import Foundation

@MainActor
final class ConsoleSocket: ObservableObject {
    enum Status: Equatable {
        case disconnected
        case connecting
        case connected
        case failed
    }

    @Published private(set) var status: Status = .disconnected

    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var onFrame: (([String: Any]) -> Void)?

    func connect(url: URL, onFrame: @escaping ([String: Any]) -> Void) {
        disconnect()
        self.onFrame = onFrame
        status = .connecting

        let socket = URLSession.shared.webSocketTask(with: url)
        task = socket
        socket.resume()
        status = .connected

        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    func sendMessage(clientID: String, senderNode: String, content: String) async throws {
        guard let task else { throw URLError(.notConnectedToInternet) }

        let payload: [String: Any] = [
            "type": "message",
            "client_id": clientID,
            "sender_node": senderNode,
            "content": content
        ]

        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotEncodeContentData)
        }

        try await task.send(.string(text))
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        status = .disconnected
    }

    private func receiveLoop() async {
        while !Task.isCancelled {
            do {
                guard let task else { return }
                let message = try await task.receive()

                let data: Data
                switch message {
                case let .string(text):
                    data = Data(text.utf8)
                case let .data(raw):
                    data = raw
                @unknown default:
                    continue
                }

                guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    continue
                }

                onFrame?(object)
            } catch {
                if !Task.isCancelled {
                    status = .failed
                }
                return
            }
        }
    }
}
