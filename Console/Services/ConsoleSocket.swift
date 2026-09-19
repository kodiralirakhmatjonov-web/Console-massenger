import Foundation

actor ConsoleSocket {
    enum State {
        case disconnected
        case connecting
        case connected
    }

    private(set) var state: State = .disconnected
    private var task: URLSessionWebSocketTask?

    func connect(to url: URL) {
        guard task == nil else { return }
        state = .connecting
        let socket = URLSession.shared.webSocketTask(with: url)
        task = socket
        socket.resume()
        state = .connected
    }

    func send(_ payload: Data) async throws {
        guard let task else { throw URLError(.notConnectedToInternet) }
        try await task.send(.data(payload))
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        state = .disconnected
    }
}
