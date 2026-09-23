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
        GeometryReader { proxy in
            ZStack {
                ConsoleBackdrop()

                if proxy.size.width >= 1040 {
                    HStack(alignment: .top, spacing: 16) {
                        conversation(maxBubbleWidth: 640)
                            .frame(maxWidth: 760)

                        inspector
                            .frame(width: 270)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    conversation(maxBubbleWidth: proxy.size.width >= 700 ? 610 : 430)
                        .frame(maxWidth: 820)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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

    private func conversation(maxBubbleWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            header

            Rectangle()
                .fill(ConsoleTheme.line)
                .frame(height: 1)

            messageList(maxBubbleWidth: maxBubbleWidth)

            if let errorText {
                ConsoleSystemLine(text: errorText, tone: .warning)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ConsoleTheme.warning.opacity(0.035))
            }

            composer
        }
        .background(ConsoleTheme.backgroundRaised.opacity(0.80))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ConsoleTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(12)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ConsoleTheme.text)
                    .frame(width: 36, height: 36)
                    .background(ConsoleTheme.surface)
                    .overlay {
                        Circle().stroke(ConsoleTheme.line, lineWidth: 1)
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            ConsoleNodeGlyph(active: socket.status == .connected)
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text("@\(terminal.peer.handle)")
                    .font(.consoleDisplay(16, weight: .bold))
                    .foregroundStyle(ConsoleTheme.text)

                HStack(spacing: 6) {
                    ConsoleStatusDot(active: socket.status == .connected)
                    Text(statusText)
                        .font(.console(8, weight: .black))
                        .foregroundStyle(socket.status == .connected ? ConsoleTheme.accent : ConsoleTheme.muted)
                }
            }

            Spacer()

            if queuedCount > 0 {
                ConsoleStatusPill(text: String(format: "QUEUE %02d", queuedCount), active: false)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(ConsoleTheme.surfaceGreen.opacity(0.35))
    }

    private func messageList(maxBubbleWidth: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 11) {
                    VStack(spacing: 6) {
                        Text("console://terminal/@\(terminal.peer.handle)")
                            .font(.console(8.5, weight: .black))
                            .foregroundStyle(ConsoleTheme.muted)

                        HStack(spacing: 7) {
                            Text("> CHANNEL READY")
                                .foregroundStyle(ConsoleTheme.accent)
                            Text("//")
                                .foregroundStyle(ConsoleTheme.muted)
                            Text("E2EE OFF")
                                .foregroundStyle(ConsoleTheme.warning)
                        }
                        .font(.console(8, weight: .black))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)

                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isMine: message.senderNode == session.identity?.nodeID,
                            maxWidth: maxBubbleWidth
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .onChange(of: messages.count) { _, _ in
                guard let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.16)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onAppear {
                guard let last = messages.last else { return }
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            HStack(alignment: .bottom, spacing: 9) {
                Text(">")
                    .font(.console(13, weight: .black))
                    .foregroundStyle(ConsoleTheme.accent)
                    .padding(.bottom, 2)

                TextField("ввод...", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.console(13))
                    .foregroundStyle(ConsoleTheme.text)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(ConsoleTheme.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ConsoleTheme.lineGreen.opacity(0.65), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                send()
            } label: {
                Image(systemName: socket.status == .connected ? "arrow.up" : "tray.and.arrow.up")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 47, height: 47)
                    .background(ConsoleTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(ConsoleTheme.line).frame(height: 1)
        }
    }

    private var inspector: some View {
        VStack(spacing: 12) {
            ConsoleWindowCard(title: "terminal.inspect") {
                VStack(alignment: .leading, spacing: 13) {
                    ConsoleSystemLine(text: "terminal mounted", tone: .success)
                    inspectRow("HANDLE", "@\(terminal.peer.handle)")
                    inspectRow("NODE", terminal.peer.nodeID)
                    inspectRow("FINGERPRINT", terminal.peer.fingerprint)
                    Rectangle().fill(ConsoleTheme.line).frame(height: 1)
                    inspectRow("TRANSPORT", "REALTIME V1")
                    inspectRow("E2EE", "NOT ACTIVE", color: ConsoleTheme.warning)
                }
            }

            ConsoleCard {
                VStack(alignment: .leading, spacing: 9) {
                    Text("SESSION PROTOCOL")
                        .font(.console(8, weight: .black))
                        .foregroundStyle(ConsoleTheme.muted)
                    Text("Сообщения передаются через текущий realtime transport. Криптографический защищённый канал ещё не заявляется.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .lineSpacing(3)
                }
            }

            Spacer()
        }
    }

    private func inspectRow(_ key: String, _ value: String, color: Color = ConsoleTheme.secondary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.console(7.5, weight: .black))
                .foregroundStyle(ConsoleTheme.muted)
            Text(value)
                .font(.console(9, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .textSelection(.enabled)
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
            return "ПОВТОР СОЕДИНЕНИЯ [\(attempt)]"
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
            // Local history remains available even when the network is down.
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
}

private struct MessageBubble: View {
    let message: TerminalMessage
    let isMine: Bool
    let maxWidth: CGFloat

    var body: some View {
        HStack(alignment: .bottom) {
            if isMine { Spacer(minLength: 58) }

            VStack(alignment: .leading, spacing: 8) {
                Text(message.content)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(ConsoleTheme.text)
                    .textSelection(.enabled)

                HStack(spacing: 7) {
                    Text(shortTime)
                        .font(.console(7.5, weight: .medium))
                        .foregroundStyle(ConsoleTheme.muted)

                    if isMine {
                        Text("//")
                            .font(.console(7, weight: .black))
                            .foregroundStyle(ConsoleTheme.muted)
                        Text(deliveryText)
                            .font(.console(7.5, weight: .black))
                            .foregroundStyle(deliveryColor)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .background(
                isMine
                ? LinearGradient(
                    colors: [ConsoleTheme.accent.opacity(0.115), ConsoleTheme.surfaceGreen.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [ConsoleTheme.surfaceRaised, ConsoleTheme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isMine ? ConsoleTheme.lineGreen : ConsoleTheme.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            if !isMine { Spacer(minLength: 58) }
        }
        .frame(maxWidth: .infinity)
    }

    private var deliveryText: String {
        switch message.delivery {
        case .queued: return "ОЖИДАНИЕ СЕТИ"
        case .sending: return "ПЕРЕДАЧА"
        case .sent: return "ОТПРАВЛЕНО"
        case .delivered: return "ДОСТАВЛЕНО"
        case .read: return "ВЫВОД ПОДТВЕРЖДЁН"
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
