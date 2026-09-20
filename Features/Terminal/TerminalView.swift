import SwiftUI

struct TerminalView: View {
    @EnvironmentObject private var session: ConsoleSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let terminal: TerminalSummary

    @StateObject private var socket = ConsoleSocket()
    @State private var messages: [TerminalMessage] = []
    @State private var draft = ""
    @State private var errorText: String?
    @State private var didLoadLocalState = false

    private let messageStore = LocalMessageStore.shared

    var body: some View {
        ZStack {
            ConsoleBackdrop()

            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(ConsoleTheme.line)
                    .frame(height: 1)

                messageList

                if let errorText {
                    HStack(spacing: 7) {
                        Text("[!]")
                            .foregroundStyle(ConsoleTheme.warning)
                        Text(errorText)
                            .foregroundStyle(ConsoleTheme.secondary)
                        Spacer()
                    }
                    .font(.console(8.5, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.82))
                }

                composer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await start()
        }
        .onChange(of: socket.status) { _, newStatus in
            guard newStatus == .connected else { return }
            errorText = nil
            Task {
                await flushPending()
                await markVisibleIncomingAsRead()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, socket.status == .connected else { return }
            Task { await markVisibleIncomingAsRead() }
        }
        .onDisappear {
            persist()
            socket.disconnect()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 11) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(ConsoleTheme.text)
                        .frame(width: 34, height: 34)
                        .background(ConsoleTheme.surface)
                        .overlay {
                            Circle().stroke(ConsoleTheme.line, lineWidth: 1)
                        }
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text("console://terminal/@\(terminal.peer.handle)")
                        .font(.console(10, weight: .black))
                        .foregroundStyle(ConsoleTheme.text)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        ConsoleStatusDot(active: socket.status == .connected)

                        Text(statusText)
                            .font(.console(8, weight: .black))
                            .foregroundStyle(socket.status == .connected ? ConsoleTheme.accent : ConsoleTheme.muted)
                    }
                }

                Spacer(minLength: 6)

                if queuedCount > 0 {
                    ConsoleStatusPill(text: String(format: "QUEUE %02d", queuedCount), active: false)
                } else {
                    Text("NODE")
                        .font(.console(8, weight: .black))
                        .foregroundStyle(ConsoleTheme.muted)
                }
            }

            HStack(spacing: 7) {
                Text("SESSION")
                    .font(.console(7.5, weight: .black))
                    .foregroundStyle(ConsoleTheme.muted)
                Text(compact(terminal.id))
                    .font(.console(7.5, weight: .bold))
                    .foregroundStyle(ConsoleTheme.secondary)
                Spacer()
                Text("E2EE OFF")
                    .font(.console(7.5, weight: .black))
                    .foregroundStyle(ConsoleTheme.warning)
            }
        }
        .padding(.horizontal, 13)
        .padding(.top, 10)
        .padding(.bottom, 9)
        .background(Color.black.opacity(0.95))
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 9) {
                    protocolBanner

                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isMine: message.senderNode == session.identity?.nodeID
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 11)
                .padding(.bottom, 14)
            }
            .onChange(of: messages.count) { _, _ in
                guard let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.14)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onAppear {
                guard let last = messages.last else { return }
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var protocolBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                Circle().fill(ConsoleTheme.destructive).frame(width: 6, height: 6)
                Circle().fill(Color(red: 254 / 255, green: 188 / 255, blue: 46 / 255)).frame(width: 6, height: 6)
                Circle().fill(Color(red: 40 / 255, green: 200 / 255, blue: 64 / 255)).frame(width: 6, height: 6)
                Spacer()
                Text("terminal.session")
                    .font(.console(7.5, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
                Spacer()
                Color.clear.frame(width: 27, height: 1)
            }

            Rectangle().fill(ConsoleTheme.line).frame(height: 1)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("[+]")
                    .foregroundStyle(ConsoleTheme.accent)
                Text("ТЕРМИНАЛ АКТИВЕН")
                    .foregroundStyle(ConsoleTheme.secondary)
                Spacer()
                Text("E2EE: OFF")
                    .foregroundStyle(ConsoleTheme.warning)
            }
            .font(.console(8, weight: .black))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(ConsoleTheme.surfaceGreen.opacity(0.88))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ConsoleTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.top, 11)
        .padding(.bottom, 3)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 9) {
            HStack(alignment: .bottom, spacing: 9) {
                Text(">")
                    .font(.console(13, weight: .black))
                    .foregroundStyle(ConsoleTheme.accent)
                    .padding(.bottom, 2)

                TextField("ввод...", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(ConsoleTheme.text)
                    .tint(ConsoleTheme.accent)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(ConsoleTheme.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            Button {
                send()
            } label: {
                Image(systemName: socket.status == .connected ? "arrow.up" : "tray.and.arrow.up")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 46, height: 46)
                    .background(ConsoleTheme.text)
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(socket.status == .connected ? ConsoleTheme.accent : ConsoleTheme.warning)
                            .frame(width: 7, height: 7)
                            .offset(x: 1, y: -1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.97))
        .overlay(alignment: .top) {
            Rectangle().fill(ConsoleTheme.line).frame(height: 1)
        }
    }

    private var queuedCount: Int {
        guard let node = session.identity?.nodeID else { return 0 }
        return messages.filter {
            $0.senderNode == node && [.queued, .sending, .failed].contains($0.delivery)
        }.count
    }

    private var statusText: String {
        switch socket.status {
        case .disconnected:
            return queuedCount > 0 ? "ОЖИДАНИЕ СЕТИ" : "ОТСОЕДИНЁН"
        case .connecting:
            return "СОЕДИНЕНИЕ..."
        case let .reconnecting(attempt):
            return "RECONNECT [\(attempt)]"
        case .connected:
            return "ПОДКЛЮЧЁН"
        case .failed:
            return "СЕТЬ НЕДОСТУПНА"
        }
    }

    private func start() async {
        guard let node = session.identity?.nodeID else { return }

        if !didLoadLocalState {
            messages = messageStore.load(terminalID: terminal.id, nodeID: node)
            didLoadLocalState = true
        }

        do {
            let remote = try await session.api.history(terminalID: terminal.id, nodeID: node)
            messages = messageStore.merge(local: messages, remote: remote, currentNode: node)
            persist()
            errorText = nil
        } catch {
            errorText = "ИСТОРИЯ: ЛОКАЛЬНЫЙ РЕЖИМ"
        }

        do {
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
        let initialState: MessageDelivery = socket.status == .connected ? .sending : .queued

        let local = TerminalMessage(
            seq: nil,
            eventID: nil,
            clientID: clientID,
            senderNode: node,
            content: content,
            createdAt: now,
            delivery: initialState
        )

        messages.append(local)
        draft = ""
        persist()

        guard socket.status == .connected else {
            errorText = "СЕТЬ НЕДОСТУПНА • СООБЩЕНИЕ В ОЧЕРЕДИ"
            return
        }

        Task { await transmit(clientID: clientID) }
    }

    private func transmit(clientID: String) async {
        guard let node = session.identity?.nodeID,
              let message = messages.first(where: { $0.clientID == clientID }) else { return }

        update(clientID: clientID) { $0.delivery = .sending }

        do {
            try await socket.sendMessage(
                clientID: clientID,
                senderNode: node,
                content: message.content
            )
        } catch {
            update(clientID: clientID) { $0.delivery = .queued }
            errorText = "СЕТЬ НЕДОСТУПНА • ПЕРЕДАЧА ОТЛОЖЕНА"
        }
    }

    private func flushPending() async {
        guard let node = session.identity?.nodeID else { return }

        let pendingIDs = messages
            .filter {
                $0.senderNode == node && [.queued, .sending, .failed].contains($0.delivery)
            }
            .map(\.clientID)

        for clientID in pendingIDs {
            guard socket.status == .connected else { return }
            await transmit(clientID: clientID)
        }
    }

    private func handleFrame(_ frame: [String: Any]) {
        guard let type = frame["type"] as? String else { return }

        switch type {
        case "channel_ready", "pong":
            return

        case "server_ack":
            guard let clientID = frame["client_id"] as? String else { return }
            update(clientID: clientID) { message in
                message.eventID = frame["event_id"] as? String ?? message.eventID
                message.seq = frame["seq"] as? Int ?? message.seq
                message.createdAt = frame["created_at"] as? String ?? message.createdAt
                if message.delivery.rank < MessageDelivery.sent.rank {
                    message.delivery = .sent
                }
            }

        case "message":
            receiveMessage(frame)

        case "delivery_receipt":
            guard let eventID = frame["event_id"] as? String else { return }
            update(eventID: eventID) { message in
                if message.delivery.rank < MessageDelivery.delivered.rank {
                    message.delivery = .delivered
                }
            }

        case "read_receipt":
            guard let eventID = frame["event_id"] as? String else { return }
            update(eventID: eventID) { $0.delivery = .read }

        case "error":
            let code = frame["code"] as? String ?? "FRAME_REJECTED"
            errorText = "СЕТЬ: \(code)"

        default:
            return
        }
    }

    private func receiveMessage(_ frame: [String: Any]) {
        guard let node = session.identity?.nodeID,
              let clientID = frame["client_id"] as? String,
              let senderNode = frame["sender_node"] as? String,
              let content = frame["content"] as? String,
              let createdAt = frame["created_at"] as? String else { return }

        let eventID = frame["event_id"] as? String
        let seq = frame["seq"] as? Int

        if messages.contains(where: { $0.clientID == clientID }) {
            update(clientID: clientID) { message in
                message.eventID = eventID ?? message.eventID
                message.seq = seq ?? message.seq
                message.createdAt = createdAt
            }
        } else {
            messages.append(
                TerminalMessage(
                    seq: seq,
                    eventID: eventID,
                    clientID: clientID,
                    senderNode: senderNode,
                    content: content,
                    createdAt: createdAt,
                    delivery: senderNode == node ? .sent : .delivered
                )
            )
            persist()
        }

        guard senderNode != node, let eventID else { return }
        Task {
            try? await socket.sendDeliveryReceipt(eventID: eventID)
            if scenePhase == .active {
                try? await socket.sendReadReceipt(eventID: eventID)
            }
        }
    }

    private func markVisibleIncomingAsRead() async {
        guard let node = session.identity?.nodeID else { return }
        let eventIDs = messages.compactMap { message -> String? in
            guard message.senderNode != node else { return nil }
            return message.eventID
        }

        for eventID in eventIDs {
            guard socket.status == .connected else { return }
            try? await socket.sendDeliveryReceipt(eventID: eventID)
            try? await socket.sendReadReceipt(eventID: eventID)
        }
    }

    private func update(clientID: String, mutation: (inout TerminalMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.clientID == clientID }) else { return }
        mutation(&messages[index])
        persist()
    }

    private func update(eventID: String, mutation: (inout TerminalMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.eventID == eventID }) else { return }
        mutation(&messages[index])
        persist()
    }

    private func persist() {
        guard let node = session.identity?.nodeID else { return }
        messageStore.save(messages, terminalID: terminal.id, nodeID: node)
    }

    private func compact(_ value: String) -> String {
        guard value.count > 20 else { return value }
        return "\(value.prefix(10))…\(value.suffix(7))"
    }
}

private struct MessageBubble: View {
    let message: TerminalMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 44) }

            VStack(alignment: .leading, spacing: 7) {
                Text(message.content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(ConsoleTheme.text)
                    .textSelection(.enabled)

                HStack(spacing: 7) {
                    Text(shortTime)
                        .font(.console(7.5, weight: .bold))
                        .foregroundStyle(ConsoleTheme.muted)

                    if isMine {
                        Circle()
                            .fill(deliveryColor)
                            .frame(width: 4, height: 4)

                        Text(deliveryText)
                            .font(.console(7.5, weight: .black))
                            .foregroundStyle(deliveryColor)
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(isMine ? ConsoleTheme.surfaceGreen : ConsoleTheme.surface)
            .overlay(alignment: isMine ? .trailing : .leading) {
                Rectangle()
                    .fill(isMine ? ConsoleTheme.accent.opacity(0.72) : ConsoleTheme.line)
                    .frame(width: 2)
                    .padding(.vertical, 7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(isMine ? ConsoleTheme.lineGreen : ConsoleTheme.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            if !isMine { Spacer(minLength: 44) }
        }
    }

    private var deliveryText: String {
        switch message.delivery {
        case .queued: return "ОЖИДАНИЕ СЕТИ"
        case .sending: return "ПЕРЕДАЧА"
        case .sent: return "ОТПРАВЛЕНО"
        case .delivered: return "ДОСТАВЛЕНО"
        case .read: return "ПРОЧИТАНО"
        case .failed: return "ОШИБКА"
        }
    }

    private var deliveryColor: Color {
        switch message.delivery {
        case .queued: return ConsoleTheme.warning
        case .failed: return ConsoleTheme.destructive
        case .read: return ConsoleTheme.accent
        default: return ConsoleTheme.muted
        }
    }

    private var shortTime: String {
        guard let date = ISO8601DateFormatter().date(from: message.createdAt) else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}
