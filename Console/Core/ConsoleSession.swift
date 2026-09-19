import Foundation

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
    @Published var lastError: String?
    @Published var networkBusy = false

    let endpointStore = ConsoleEndpointStore()
    private let identityStore = IdentityStore()
    lazy var api = ConsoleAPI(endpointStore: endpointStore)

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
        await refreshNetwork()
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

        networkBusy = true
        defer { networkBusy = false }

        if api.baseURL != nil {
            _ = try await api.register(identity: identity, handle: normalized)
        }

        let profile = ConsoleProfile(handle: normalized)
        try identityStore.saveProfile(profile)
        self.profile = profile
        bootstrapState = .ready

        await refreshNetwork()
    }

    func refreshNetwork() async {
        guard let identity, api.baseURL != nil else { return }

        networkBusy = true
        defer { networkBusy = false }

        do {
            async let terminalsRequest = api.terminals(nodeID: identity.nodeID)
            async let handshakesRequest = api.handshakes(nodeID: identity.nodeID)

            terminals = try await terminalsRequest
            let handshakes = try await handshakesRequest
            incomingHandshakes = handshakes.incoming
            outgoingHandshakes = handshakes.outgoing
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func search(_ query: String) async throws -> [NetworkIdentity] {
        try await api.search(query)
            .filter { $0.nodeID != identity?.nodeID }
    }

    func requestConnection(to target: NetworkIdentity) async throws {
        guard let node = identity?.nodeID else { return }
        _ = try await api.createHandshake(from: node, to: target.nodeID)
        await refreshNetwork()
    }

    func decide(_ request: HandshakeRequest, decision: String) async throws {
        guard let node = identity?.nodeID else { return }
        _ = try await api.decideHandshake(id: request.id, nodeID: node, decision: decision)
        await refreshNetwork()
    }

    func saveServerURL(_ raw: String) throws {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: normalized),
              ["https", "http"].contains(url.scheme?.lowercased() ?? "") else {
            throw ConsoleSessionError.invalidServerURL
        }
        endpointStore.value = url
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

    var errorDescription: String? {
        switch self {
        case .invalidHandle:
            return "HANDLE ОТКЛОНЁН\n3–24 символа: a-z, 0-9, _"
        case .invalidServerURL:
            return "АДРЕС СЕТИ ОТКЛОНЁН"
        }
    }
}
