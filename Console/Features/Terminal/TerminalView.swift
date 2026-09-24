import SwiftUI

struct TerminalView: View {
    @EnvironmentObject private var session: ConsoleSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("console.effects.enabled") private var effectsEnabled = true
    @AppStorage("console.effects.reduceMotion") private var reduceMotion = false
    @AppStorage("console.notifications.previews") private var notificationPreviews = true
    @AppStorage("console.interface.showProtocolHints") private var showProtocolHints = true

    let terminal: TerminalSummary

    @StateObject private var socket = ConsoleSocket()
    @State private var messages: [TerminalMessage] = []
    @State private var draft = ""
    @State private var errorText: String?
    @State private var didLoadLocalState = false
    @State private var activeEffect: ConsoleSimulationEffect?

    private let messageStore = LocalMessageStore.shared

    var body: some View {
        GeometryReader { proxy in
            let wideInspector = proxy.size.width >= 1040
            let compactScreen = proxy.size.width < 700
            let regularBubbleWidth = min(proxy.size.width * 0.72, 640)
            let compactBubbleWidth = min(max(proxy.size.width * 0.78, 240), 470)

            ZStack {
                ConsoleBackdrop()

                if wideInspector {
                    HStack(alignment: .top, spacing: 16) {
                        regularConversation(maxBubbleWidth: regularBubbleWidth)
                            .frame(maxWidth: 780)
                        inspector
                            .frame(width: 280)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if compactScreen {
                    compactConversation(maxBubbleWidth: compactBubbleWidth)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    regularConversation(maxBubbleWidth: regularBubbleWidth)
                        .frame(maxWidth: 860, maxHeight: .infinity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let activeEffect {
                    ConsoleSimulationOverlay(effect: activeEffect, reduceMotion: reduceMotion) {
                        self.activeEffect = nil
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
                    .zIndex(50)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await start()
        }
        .onAppear {
            session.terminalFullscreenActive = true
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
            session.terminalFullscreenActive = false
        }
    }

    private func regularConversation(maxBubbleWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            header(compact: false)
            Rectangle().fill(ConsoleTheme.line).frame(height: 1)
            messageList(maxBubbleWidth: maxBubbleWidth)
            if let errorText {
                errorBanner(errorText)
            }
            composer
        }
        .background(ConsoleTheme.backgroundRaised.opacity(0.84))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ConsoleTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(12)
    }

    private func compactConversation(maxBubbleWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            header(compact: true)
            Rectangle().fill(ConsoleTheme.line).frame(height: 1)
            messageList(maxBubbleWidth: maxBubbleWidth)
            if let errorText {
                errorBanner(errorText)
            }
            composer
        }
        .background(ConsoleTheme.backgroundRaised.opacity(0.97))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ConsoleTheme.text)
                    .frame(width: 38, height: 38)
                    .background(ConsoleTheme.surface)
                    .overlay {
                        Circle().stroke(ConsoleTheme.line, lineWidth: 1)
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            ConsoleNodeGlyph(active: socket.status == .connected)
                .frame(width: compact ? 42 : 40, height: compact ? 42 : 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("@\(terminal.peer.handle)")
                    .font(.system(size: compact ? 24 : 18, weight: .bold, design: .rounded))
                    .foregroundStyle(ConsoleTheme.text)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    ConsoleStatusDot(active: socket.status == .connected)
                    Text(statusText)
                        .font(.console(compact ? 8.5 : 8, weight: .black))
                        .foregroundStyle(socket.status == .connected ? ConsoleTheme.accent : ConsoleTheme.muted)
                }
            }

            Spacer()

            if queuedCount > 0 {
                ConsoleStatusPill(text: String(format: "QUEUE %02d", queuedCount), active: false)
            }
        }
        .padding(.horizontal, compact ? 16 : 15)
        .padding(.top, compact ? 16 : 12)
        .padding(.bottom, compact ? 14 : 12)
        .background(ConsoleTheme.surfaceGreen.opacity(compact ? 0.30 : 0.35))
    }

    private func errorBanner(_ text: String) -> some View {
        ConsoleSystemLine(text: text, tone: .warning)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(ConsoleTheme.warning.opacity(0.035))
    }

    private func messageList(maxBubbleWidth: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 11) {
                    if showProtocolHints {
                        VStack(spacing: 6) {
                            Text("console://terminal/@\(terminal.peer.handle)")
                                .font(.console(8.5, weight: .black))
                                .foregroundStyle(ConsoleTheme.muted)

                            HStack(spacing: 7) {
                                Text("> CHANNEL READY")
                                    .foregroundStyle(ConsoleTheme.accent)
                                Text("//")
                                    .foregroundStyle(ConsoleTheme.muted)
                                Text("REALTIME V1")
                                    .foregroundStyle(ConsoleTheme.secondary)
                            }
                            .font(.console(8, weight: .black))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                    } else {
                        Color.clear.frame(height: 10)
                    }

                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isMine: message.senderNode == session.identity?.nodeID,
                            maxWidth: maxBubbleWidth
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 2)
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
                    .font(.console(14, weight: .black))
                    .foregroundStyle(ConsoleTheme.accent)
                    .padding(.bottom, 2)

                TextField("Сообщение", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(ConsoleTheme.text)
                    .tint(ConsoleTheme.accent)
                    .submitLabel(.send)
                    .onSubmit { send() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(ConsoleTheme.fieldBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ConsoleTheme.lineGreen.opacity(0.65), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                send()
            } label: {
                Image(systemName: socket.status == .connected ? "arrow.up" : "tray.and.arrow.up")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 48, height: 48)
                    .background(ConsoleTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 10)
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
                    Text("Чат получил более читаемый полноэкранный режим. Для Console FX отправьте /hacked, /panic, /trace, /breach, /ghost или /wake.")
                        .font(.system(size: 11.5, weight: .medium))
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
        triggerEffectIfNeeded(content)

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

        guard senderNode != node else { return }

        triggerEffectIfNeeded(content)
        if scenePhase != .active {
            let body = notificationPreviews ? "@\(terminal.peer.handle): \(content)" : "Новые данные в терминале @\(terminal.peer.handle)"
            ConsoleNotifications.shared.postLocal(
                title: "Console • новое сообщение",
                body: body,
                category: "console.message"
            )
        }

        guard let eventID else { return }
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

    private func triggerEffectIfNeeded(_ content: String) {
        guard effectsEnabled,
              let effect = ConsoleSimulationEffect(command: content) else { return }
        activeEffect = effect
        Task {
            let delay: UInt64 = reduceMotion ? 1_200_000_000 : 1_800_000_000
            try? await Task.sleep(nanoseconds: delay)
            await MainActor.run {
                if activeEffect == effect { activeEffect = nil }
            }
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
            if isMine { Spacer(minLength: 54) }

            VStack(alignment: .leading, spacing: 7) {
                Text(message.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(ConsoleTheme.text)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

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
                    colors: [ConsoleTheme.accent.opacity(0.11), ConsoleTheme.surfaceGreen.opacity(0.88)],
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
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isMine ? ConsoleTheme.lineGreen : ConsoleTheme.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if !isMine { Spacer(minLength: 54) }
        }
        .frame(maxWidth: .infinity)
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

private enum ConsoleSimulationEffect: String, CaseIterable, Identifiable {
    case hacked = "/hacked"
    case panic = "/panic"
    case trace = "/trace"
    case breach = "/breach"
    case ghost = "/ghost"
    case wake = "/wake"

    init?(command: String) {
        let normalized = command.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.init(rawValue: normalized)
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hacked: return "ОБНАРУЖЕНО ВНЕШНЕЕ ВМЕШАТЕЛЬСТВО"
        case .panic: return "АВАРИЙНЫЙ РЕЖИМ АКТИВИРОВАН"
        case .trace: return "ЗАПУЩЕН АНАЛИЗ МАРШРУТА"
        case .breach: return "НАРУШЕНИЕ ПЕРИМЕТРА"
        case .ghost: return "РЕЖИМ ТЕНИ"
        case .wake: return "СИГНАЛ ВНИМАНИЯ"
        }
    }

    var subtitle: String {
        switch self {
        case .hacked: return "СИМУЛЯЦИЯ • КАНАЛ НЕ ПОВРЕЖДЁН"
        case .panic: return "СИМУЛЯЦИЯ • УТЕЧКИ НЕ ОБНАРУЖЕНО"
        case .trace: return "СИМУЛЯЦИЯ • МАРШРУТ СКАНИРУЕТСЯ"
        case .breach: return "СИМУЛЯЦИЯ • ИДЁТ ЛОКАЛЬНАЯ ПРОВЕРКА"
        case .ghost: return "СИМУЛЯЦИЯ • ПРИСУТСТВИЕ ОГРАНИЧЕНО"
        case .wake: return "СИМУЛЯЦИЯ • ПОЛЬЗОВАТЕЛЬ УВЕДОМЛЁН"
        }
    }

    var icon: String {
        switch self {
        case .hacked: return "exclamationmark.triangle.fill"
        case .panic: return "bolt.horizontal.circle.fill"
        case .trace: return "scope"
        case .breach: return "shield.lefthalf.filled.badge.exclamationmark"
        case .ghost: return "moon.stars.fill"
        case .wake: return "bell.and.waves.left.and.right.fill"
        }
    }

    var color: Color {
        switch self {
        case .hacked, .panic, .breach: return ConsoleTheme.warning
        case .ghost: return ConsoleTheme.cyan
        case .wake, .trace: return ConsoleTheme.accent
        }
    }
}

private struct ConsoleSimulationOverlay: View {
    let effect: ConsoleSimulationEffect
    let reduceMotion: Bool
    let dismiss: () -> Void

    @State private var phase = false

    var body: some View {
        ZStack {
            ConsoleTheme.background.opacity(reduceMotion ? 0.72 : 0.86)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(effect.color.opacity(0.12))
                        Image(systemName: effect.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(effect.color)
                    }
                    .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(effect.title)
                            .font(.console(11, weight: .black))
                            .foregroundStyle(ConsoleTheme.text)
                        Text(effect.subtitle)
                            .font(.console(8.5, weight: .bold))
                            .foregroundStyle(effect.color)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    effectLine("> анализ сигнала")
                    effectLine("> проверка канала")
                    effectLine("> симуляция завершится автоматически")
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(ConsoleTheme.surface)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(effect.color)
                            .frame(width: proxy.size.width * (phase ? 0.84 : 0.42))
                    }
                }
                .frame(height: 12)
            }
            .padding(20)
            .frame(maxWidth: 420)
            .background(ConsoleTheme.backgroundRaised.opacity(0.96))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(effect.color.opacity(0.5), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: ConsoleTheme.shadow, radius: 28, y: 14)
            .padding(24)
        }
        .onAppear {
            withAnimation(reduceMotion ? .linear(duration: 0.25) : .easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                phase.toggle()
            }
        }
    }

    private func effectLine(_ text: String) -> some View {
        Text(text)
            .font(.console(9, weight: .bold))
            .foregroundStyle(ConsoleTheme.secondary)
    }
}
