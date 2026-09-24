import Foundation
import Combine

struct ConsoleActivityEvent: Identifiable, Equatable {
    enum Kind: Equatable {
        case handshake
        case connection
        case message
        case system
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let detail: String
}

@MainActor
final class ConsoleSession: ObservableObject {
    enum BootstrapState {
        case needsIdentity
        case needsHandle
        case ready
    }

    @Published private(set) var bootstrapState: BootstrapState = .needsIdentity
    @Published private(set) var identity: ConsoleIdentity?
    @Published private(set) var profile: ConsoleProfile?
    @Published private(set) var terminals: [TerminalSummary] = []
    @Published private(set) var incomingHandshakes: [HandshakeRequest] = []
    @Published private(set) var outgoingHandshakes: [HandshakeRequest] = []
    @Published private(set) var networkOnline = false
    @Published private(set) var activityEvent: ConsoleActivityEvent?
    @Published var lastError: String?
    @Published var networkBusy = false
    @Published var terminalFullscreenActive = false

    let endpointStore = ConsoleEndpointStore()
    private let identityStore = IdentityStore()
    lazy var api = ConsoleAPI(endpointStore: endpointStore)

    private var hasNetworkSnapshot = false
    private var lastPushSyncToken: String?

    func bootstrap() async {
        identity = identityStore.loadIdentity()
        profile = identityStore.loadProfile()

        if identity == nil {
            bootstrapState = .needsIdentity
            return
        }

        if profile?.handle.isEmpty != false {
            bootstrapState = .needsHandle
            return
        }

        bootstrapState = .ready
        await refreshNetwork(notify: false)
        await syncPushRegistration()
    }

    func initializeIdentity() throws {
        identity = try identityStore.createIdentity()
        bootstrapState = .needsHandle
    }

    func claimHandle(_ rawHandle: String) async throws {
        guard let identity else { return }
        let normalized = Self.normalizeHandle(rawHandle)
        guard Self.isValidHandle(normalized) else {
            throw ConsoleSessionError.invalidHandle
        }

        guard api.baseURL != nil else {
            throw ConsoleAPIError.serverNotConfigured
        }

        networkBusy = true
        defer { networkBusy = false }

        _ = try await api.health()
        _ = try await api.register(identity: identity, handle: normalized)
        networkOnline = true

        let profile = ConsoleProfile(handle: normalized)
        try identityStore.saveProfile(profile)
        self.profile = profile
        bootstrapState = .ready

        await refreshNetwork(notify: false)
        await syncPushRegistration()
    }

    func refreshNetwork(notify: Bool = true) async {
        guard let identity, api.baseURL != nil else {
            networkOnline = false
            return
        }

        if !networkBusy { networkBusy = true }
        defer { networkBusy = false }

        let previousIncoming = Set(incomingHandshakes.map(\.id))
        let previousTerminalIDs = Set(terminals.map(\.id))
        let previousActivity = Dictionary(uniqueKeysWithValues: terminals.map { ($0.id, $0.lastMessageAt) })

        do {
            _ = try await api.health()
            try await registerCurrentIdentityIfNeeded(identity: identity)

            async let terminalsRequest = api.terminals(nodeID: identity.nodeID)
            async let handshakesRequest = api.handshakes(nodeID: identity.nodeID)

            let refreshedTerminals = try await terminalsRequest
            let handshakes = try await handshakesRequest

            terminals = refreshedTerminals
            incomingHandshakes = handshakes.incoming
            outgoingHandshakes = handshakes.outgoing
            networkOnline = true
            lastError = nil

            if notify && hasNetworkSnapshot {
                emitActivityIfNeeded(
                    previousIncoming: previousIncoming,
                    previousTerminalIDs: previousTerminalIDs,
                    previousActivity: previousActivity,
                    newTerminals: refreshedTerminals,
                    newIncoming: handshakes.incoming
                )
            }

            hasNetworkSnapshot = true
            await syncPushRegistration()
        } catch {
            networkOnline = false
            lastError = error.localizedDescription
        }
    }

    func search(_ query: String) async throws -> [NetworkIdentity] {
        guard let identity else { return [] }
        guard api.baseURL != nil else {
            throw ConsoleAPIError.serverNotConfigured
        }

        _ = try await api.health()
        try await registerCurrentIdentityIfNeeded(identity: identity)
        let matches = try await api.search(query)
        networkOnline = true
        lastError = nil
        return matches
    }

    func requestConnection(to target: NetworkIdentity) async throws {
        guard let node = identity?.nodeID else { return }
        guard target.nodeID != node else {
            throw ConsoleSessionError.cannotConnectToSelf
        }

        try await ensureNetworkIdentityRegistered()
        _ = try await api.createHandshake(from: node, to: target.nodeID)
        activityEvent = ConsoleActivityEvent(
            kind: .system,
            title: "ЗАПРОС СОЕДИНЕНИЯ ОТПРАВЛЕН",
            detail: "@\(target.handle) // ожидание решения"
        )
        await refreshNetwork(notify: false)
    }

    func decide(_ request: HandshakeRequest, decision: String) async throws {
        guard let node = identity?.nodeID else { return }
        try await ensureNetworkIdentityRegistered()
        _ = try await api.decideHandshake(id: request.id, nodeID: node, decision: decision)

        if decision == "accepted" {
            activityEvent = ConsoleActivityEvent(
                kind: .connection,
                title: "КАНАЛ УСТАНОВЛЕН",
                detail: request.peer.map { "@\($0.handle) // терминал активирован" } ?? "Терминал активирован"
            )
        }

        await refreshNetwork(notify: false)
    }

    func saveServerURL(_ raw: String) throws {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: normalized),
              ["https", "http"].contains(components.scheme?.lowercased() ?? ""),
              components.host?.isEmpty == false else {
            throw ConsoleSessionError.invalidServerURL
        }

        components.path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = components.url else {
            throw ConsoleSessionError.invalidServerURL
        }

        endpointStore.value = url
        networkOnline = false
        hasNetworkSnapshot = false
        lastPushSyncToken = nil
    }

    func dismissActivity() {
        activityEvent = nil
    }

    func syncPushRegistration(force: Bool = false) async {
        guard let identity,
              let token = ConsoleNotifications.shared.deviceToken,
              !token.isEmpty,
              api.baseURL != nil else { return }

        let enabled = UserDefaults.standard.object(forKey: "console.notifications.enabled") as? Bool ?? true
        guard enabled else { return }
        guard force || lastPushSyncToken != token else { return }

        let previews = UserDefaults.standard.object(forKey: "console.notifications.previews") as? Bool ?? true
        let sound = UserDefaults.standard.object(forKey: "console.notifications.sound") as? Bool ?? true

        do {
            _ = try await api.registerPushToken(
                nodeID: identity.nodeID,
                token: token,
                previews: previews,
                sound: sound
            )
            lastPushSyncToken = token
        } catch {
            // Push is an auxiliary channel. Messaging must continue even if APNs is not configured yet.
        }
    }

    func disablePushRegistration() async {
        guard let node = identity?.nodeID,
              let token = ConsoleNotifications.shared.deviceToken,
              api.baseURL != nil else { return }
        do {
            _ = try await api.unregisterPushToken(nodeID: node, token: token)
            lastPushSyncToken = nil
        } catch {
            // Keep local preference even when the network is unavailable.
        }
    }

    private func emitActivityIfNeeded(
        previousIncoming: Set<String>,
        previousTerminalIDs: Set<String>,
        previousActivity: [String: String?],
        newTerminals: [TerminalSummary],
        newIncoming: [HandshakeRequest]
    ) {
        if let request = newIncoming.first(where: { !previousIncoming.contains($0.id) }) {
            let handle = request.peer?.handle ?? "unknown"
            activityEvent = ConsoleActivityEvent(
                kind: .handshake,
                title: "ПОПЫТКА ПОДКЛЮЧЕНИЯ",
                detail: "@\(handle) запрашивает доступ"
            )
            ConsoleNotifications.shared.postLocal(
                title: "Console • запрос соединения",
                body: "@\(handle) запрашивает доступ",
                category: "console.handshake"
            )
            return
        }

        if let terminal = newTerminals.first(where: { !previousTerminalIDs.contains($0.id) }) {
            activityEvent = ConsoleActivityEvent(
                kind: .connection,
                title: "ТЕРМИНАЛ АКТИВИРОВАН",
                detail: "@\(terminal.peer.handle) // канал установлен"
            )
            ConsoleNotifications.shared.postLocal(
                title: "Console • канал установлен",
                body: "Терминал с @\(terminal.peer.handle) активирован",
                category: "console.connection"
            )
            return
        }

        if let changed = newTerminals.first(where: { terminal in
            guard previousTerminalIDs.contains(terminal.id), let newValue = terminal.lastMessageAt else { return false }
            return previousActivity[terminal.id] ?? nil != newValue
        }) {
            activityEvent = ConsoleActivityEvent(
                kind: .message,
                title: "НОВЫЕ ДАННЫЕ",
                detail: "@\(changed.peer.handle) // активность терминала"
            )
            ConsoleNotifications.shared.postLocal(
                title: "Console • новые данные",
                body: "Активность в терминале @\(changed.peer.handle)",
                category: "console.message"
            )
        }
    }

    private func ensureNetworkIdentityRegistered() async throws {
        guard let identity else { return }
        guard api.baseURL != nil else {
            throw ConsoleAPIError.serverNotConfigured
        }
        _ = try await api.health()
        try await registerCurrentIdentityIfNeeded(identity: identity)
        networkOnline = true
    }

    private func registerCurrentIdentityIfNeeded(identity: ConsoleIdentity) async throws {
        guard let handle = profile?.handle, !handle.isEmpty else { return }
        _ = try await api.register(identity: identity, handle: handle)
    }

    static func normalizeHandle(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
    }

    static func isValidHandle(_ handle: String) -> Bool {
        guard (3...24).contains(handle.count) else { return false }
        return handle.range(of: #"^[a-z0-9_]+$"#, options: .regularExpression) != nil
    }
}

enum ConsoleSessionError: LocalizedError {
    case invalidHandle
    case invalidServerURL
    case cannotConnectToSelf

    var errorDescription: String? {
        switch self {
        case .invalidHandle:
            return "HANDLE ОТКЛОНЁН\n3–24 символа: a-z, 0-9, _"
        case .invalidServerURL:
            return "АДРЕС СЕТИ ОТКЛОНЁН"
        case .cannotConnectToSelf:
            return "ЭТО ВАШ УЗЕЛ\nСОЕДИНЕНИЕ С СОБОЙ НЕДОСТУПНО"
        }
    }
}
