import Foundation

@MainActor
final class ConsoleSession: ObservableObject {
    @Published var identity: ConsoleIdentity?
    @Published var terminals: [TerminalSummary] = [
        .init(id: "T-7X91", node: "node_7X91", preview: "КАНАЛ ГОТОВ", unread: 2, connected: true),
        .init(id: "T-A4CF", node: "node_A4CF", preview: "СЕССИЯ ЗАВЕРШЕНА", unread: 0, connected: false)
    ]

    private let identityStore = IdentityStore()

    init() {
        identity = identityStore.loadIdentity()
    }

    func initializeIdentity() throws {
        identity = try identityStore.createIdentity()
    }
}

struct TerminalSummary: Identifiable, Hashable {
    let id: String
    let node: String
    let preview: String
    let unread: Int
    let connected: Bool
}
