import SwiftUI

struct TerminalView: View {
    @EnvironmentObject private var session: ConsoleSession
    @Environment(\.dismiss) private var dismiss

    let terminal: TerminalSummary

    @StateObject private var socket = ConsoleSocket()
    @State private var messages: [TerminalMessage] = []
    @State private var draft = ""
    @State private var errorText: String?

    var body: some View {
        ZStack {
            ConsoleTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(ConsoleTheme.line)
                    .frame(height: 1)

                messageList

                if let errorText {
                    Text(errorText)
                        .font(.console(9, weight: .bold))
                        .foregroundStyle(ConsoleTheme.destructive)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 6)
                }

                composer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await start()
        }
        .onDisappear {
            socket.disconnect()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(ConsoleTheme.text)
                    .frame(width: 34, height: 34)
                    .background(ConsoleTheme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("console://terminal/@\(terminal.peer.handle)")
                    .font(.console(11, weight: .bold))
                    .foregroundStyle(ConsoleTheme.text)

                HStack(spacing: 6) {
                    ConsoleStatusDot(active: socket.status == .connected)

                    Text(statusText)
                        .font(.console(8, weight: .bold))
                        .foregroundStyle(socket.status == .connected ? ConsoleTheme.accent : ConsoleTheme.muted)
                }
            }

            Spacer()

            Button { } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ConsoleTheme.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    Text("> ТЕРМИНАЛ АКТИВЕН")
                        .font(.console(9, weight: .bold))
                        .foregroundStyle(ConsoleTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)

                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isMine: message.senderNode == session.identity?.nodeID
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .onChange(of: messages.count) {
                guard let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.16)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("ввод...", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .font(.console(14))
                .foregroundStyle(ConsoleTheme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(ConsoleTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ConsoleTheme.line, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                send()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 46, height: 46)
                    .background(ConsoleTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ConsoleTheme.line)
                .frame(height: 1)
        }
    }

    private var statusText: String {
        switch socket.status {
        case .disconnected: return "ОТСОЕДИНЁН"
        case .connecting: return "СОЕДИНЕНИЕ..."
        case .connected: return "ПОДКЛЮЧЁН"
        case .failed: return "СЕТЬ НЕДОСТУПНА"
        }
    }

    private func start() async {
        guard let node = session.identity?.nodeID else { return }

        do {
            messages = try await session.api.history(terminalID: terminal.id, nodeID: node)
            let url = try session.api.socketURL(terminalID: terminal.id, nodeID: node)

            socket.connect(url: url) { frame in
                handleFrame(frame)
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func send() {
        guard let node = session.identity?.nodeID else { return }

        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        let clientID = UUID().uuidString
        let now = ISO8601DateFormatter().string(from: Date())

        let local = TerminalMessage(
            seq: nil,
            eventID: nil,
            clientID: clientID,
            senderNode: node,
            content: content,
            createdAt: now,
            delivery: .sending
        )

        messages.append(local)
        draft = ""

        Task {
            do {
                try await socket.sendMessage(clientID: clientID, senderNode: node, content: content)
            } catch {
                mark(clientID: clientID, delivery: .failed)
                errorText = error.localizedDescription
            }
        }
    }

    private func handleFrame(_ frame: [String: Any]) {
        guard let type = frame["type"] as? String else { return }

        if type == "server_ack",
           let clientID = frame["client_id"] as? String {
            mark(clientID: clientID, delivery: .sent)
            return
        }

        if type == "message",
           let clientID = frame["client_id"] as? String,
           let senderNode = frame["sender_node"] as? String,
           let content = frame["content"] as? String,
           let createdAt = frame["created_at"] as? String {

            if messages.contains(where: { $0.clientID == clientID }) {
                mark(clientID: clientID, delivery: .delivered)
                return
            }

            let seq = frame["seq"] as? Int
            let eventID = frame["event_id"] as? String

            messages.append(
                TerminalMessage(
                    seq: seq,
                    eventID: eventID,
                    clientID: clientID,
                    senderNode: senderNode,
                    content: content,
                    createdAt: createdAt,
                    delivery: .delivered
                )
            )
        }
    }

    private func mark(clientID: String, delivery: MessageDelivery) {
        guard let index = messages.firstIndex(where: { $0.clientID == clientID }) else { return }
        messages[index].delivery = delivery
    }
}

private struct MessageBubble: View {
    let message: TerminalMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 46) }

            VStack(alignment: .leading, spacing: 7) {
                Text(message.content)
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundStyle(ConsoleTheme.text)
                    .textSelection(.enabled)

                HStack(spacing: 6) {
                    Text(shortTime)
                        .font(.console(8, weight: .medium))
                        .foregroundStyle(ConsoleTheme.muted)

                    if isMine {
                        Text(deliveryText)
                            .font(.console(8, weight: .bold))
                            .foregroundStyle(message.delivery == .failed ? ConsoleTheme.destructive : ConsoleTheme.muted)
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(isMine ? ConsoleTheme.accent.opacity(0.10) : ConsoleTheme.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isMine ? ConsoleTheme.accent.opacity(0.24) : ConsoleTheme.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if !isMine { Spacer(minLength: 46) }
        }
    }

    private var deliveryText: String {
        switch message.delivery {
        case .sending: return "ПЕРЕДАЧА"
        case .sent: return "ОТПРАВЛЕНО"
        case .delivered: return "ДОСТАВЛЕНО"
        case .failed: return "ОШИБКА"
        }
    }

    private var shortTime: String {
        guard let date = ISO8601DateFormatter().date(from: message.createdAt) else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}
