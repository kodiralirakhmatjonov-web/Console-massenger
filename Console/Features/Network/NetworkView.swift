import SwiftUI

struct NetworkView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var query = ""
    @State private var results: [NetworkIdentity] = []
    @State private var searching = false
    @State private var errorText: String?
    @State private var lastNotice: String?

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    ConsoleBackdrop()

                    ScrollView {
                        VStack(spacing: 18) {
                            ConsoleHeader(
                                path: "console://network",
                                title: "Network",
                                trailing: networkLabel
                            )

                            ConsoleMetricStrip(metrics: [
                                ("INCOMING", String(format: "%02d", session.incomingHandshakes.count), session.incomingHandshakes.isEmpty ? ConsoleTheme.secondary : ConsoleTheme.accent),
                                ("OUTGOING", String(format: "%02d", session.outgoingHandshakes.count), ConsoleTheme.text),
                                ("MATCHES", String(format: "%02d", results.count), results.isEmpty ? ConsoleTheme.secondary : ConsoleTheme.accent)
                            ])

                            if proxy.size.width >= 860 {
                                HStack(alignment: .top, spacing: 14) {
                                    VStack(spacing: 14) {
                                        searchPanel
                                        resultPanel
                                    }
                                    .frame(maxWidth: .infinity)

                                    requestPanel
                                        .frame(maxWidth: .infinity)
                                }
                            } else {
                                searchPanel
                                requestPanel
                                resultPanel
                            }

                            if let lastNotice {
                                ConsoleSystemLine(text: lastNotice, tone: .success)
                                    .padding(.horizontal, 2)
                            }

                            if let errorText {
                                ConsoleSystemLine(text: errorText, tone: .error)
                                    .padding(.horizontal, 2)
                            }
                        }
                        .consolePageFrame()
                        .padding(.horizontal, proxy.size.width >= 760 ? 28 : 14)
                        .padding(.top, proxy.size.width >= 760 ? 26 : 16)
                        .padding(.bottom, 34)
                    }
                    .refreshable {
                        await session.refreshNetwork()
                    }
                }
            }
            .navigationDestination(for: HandshakeRequest.self) { request in
                HandshakeDetailView(request: request)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if session.api.baseURL != nil && !session.networkOnline {
                    await session.refreshNetwork()
                }
            }
        }
    }

    private var searchPanel: some View {
        ConsoleWindowCard(title: "scan@network:~") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ConsoleSystemLine(
                        text: searching ? "scanning identity registry..." : "scanner awaiting target",
                        tone: searching ? .warning : .normal
                    )
                    Spacer(minLength: 0)
                }

                ConsoleField(prompt: "@handle или node_id", text: $query)
                    .onSubmit { performSearch() }

                HStack(spacing: 14) {
                    Button {
                        performSearch()
                    } label: {
                        HStack(spacing: 7) {
                            if searching {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(ConsoleTheme.accent)
                            } else {
                                Text(">")
                            }

                            Text(searching ? "СКАНИРОВАНИЕ" : "СКАНИРОВАТЬ NETWORK")
                        }
                        .font(.console(9, weight: .black))
                        .foregroundStyle(ConsoleTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(searching || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "qrcode.viewfinder")
                        Text("QR READY")
                    }
                    .font(.console(8, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
                }

                Text("HANDSHAKE защищает Terminal от прямых входящих сообщений: незнакомый узел сначала запрашивает доступ.")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(3)
            }
        }
    }

    private var requestPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            ConsoleSectionLabel(
                title: "HANDSHAKE REQUESTS",
                value: String(format: "%02d", session.incomingHandshakes.count)
            )

            if session.incomingHandshakes.isEmpty {
                ConsoleCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            ConsoleStatusDot(active: false)
                            Text("ВХОДЯЩИХ ЗАПРОСОВ НЕТ")
                                .font(.console(10, weight: .black))
                                .foregroundStyle(ConsoleTheme.secondary)
                            Spacer()
                            Text("IDLE")
                                .font(.console(8, weight: .black))
                                .foregroundStyle(ConsoleTheme.muted)
                        }

                        Rectangle().fill(ConsoleTheme.line).frame(height: 1)

                        Text("NETWORK LISTENER ACTIVE")
                            .font(.console(8, weight: .black))
                            .foregroundStyle(ConsoleTheme.muted)
                    }
                }
            } else {
                ForEach(session.incomingHandshakes) { request in
                    NavigationLink(value: request) {
                        HStack(spacing: 13) {
                            ConsoleNodeGlyph()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("@\(request.peer?.handle ?? request.fromNode)")
                                    .font(.consoleDisplay(15, weight: .bold))
                                    .foregroundStyle(ConsoleTheme.text)
                                Text("ПОПЫТКА ПОДКЛЮЧЕНИЯ")
                                    .font(.console(8.5, weight: .black))
                                    .foregroundStyle(ConsoleTheme.accent)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("REVIEW")
                                    .font(.console(8, weight: .black))
                                    .foregroundStyle(ConsoleTheme.muted)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ConsoleTheme.accent)
                            }
                        }
                        .padding(14)
                        .background(ConsoleTheme.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var resultPanel: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ConsoleSectionLabel(title: "IDENTITY MATCHES", value: String(format: "%02d", results.count))

                ForEach(results) { identity in
                    ConsoleWindowCard(title: "identity://\(identity.handle)") {
                        VStack(alignment: .leading, spacing: 13) {
                            HStack(spacing: 12) {
                                ConsoleNodeGlyph(active: !isSelf(identity))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("@\(identity.handle)")
                                        .font(.consoleDisplay(18, weight: .bold))
                                        .foregroundStyle(ConsoleTheme.text)
                                    Text("NODE \(compact(identity.nodeID))")
                                        .font(.console(9, weight: .bold))
                                        .foregroundStyle(ConsoleTheme.muted)
                                }

                                Spacer()

                                ConsoleStatusPill(text: isSelf(identity) ? "LOCAL" : "DISCOVERED")
                            }

                            Rectangle().fill(ConsoleTheme.line).frame(height: 1)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("FINGERPRINT")
                                    .font(.console(8, weight: .black))
                                    .foregroundStyle(ConsoleTheme.muted)
                                Text(identity.fingerprint)
                                    .font(.console(10, weight: .bold))
                                    .foregroundStyle(ConsoleTheme.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }

                            if isSelf(identity) {
                                ConsoleSystemLine(text: "ЭТО ВАШ УЗЕЛ", tone: .warning)
                                    .padding(.top, 2)
                            } else {
                                ConsolePrimaryButton(title: "УСТАНОВИТЬ СОЕДИНЕНИЕ") {
                                    requestConnection(identity)
                                }
                                .padding(.top, 2)
                            }
                        }
                    }
                }
            }
        }
    }

    private var networkLabel: String {
        if session.api.baseURL == nil { return "OFFLINE" }
        return session.networkOnline ? "CONNECTED" : "CONNECTING"
    }

    private func isSelf(_ identity: NetworkIdentity) -> Bool {
        identity.nodeID == session.identity?.nodeID
    }

    private func performSearch() {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        searching = true
        errorText = nil
        lastNotice = nil

        Task {
            do {
                results = try await session.search(value)
                if results.isEmpty {
                    lastNotice = nil
                    errorText = "СОВПАДЕНИЙ НЕ ОБНАРУЖЕНО"
                }
            } catch {
                errorText = error.localizedDescription
            }
            searching = false
        }
    }

    private func requestConnection(_ identity: NetworkIdentity) {
        errorText = nil
        lastNotice = nil

        Task {
            do {
                try await session.requestConnection(to: identity)
                results.removeAll { $0.id == identity.id }
                lastNotice = "HANDSHAKE REQUEST TRANSMITTED"
            } catch {
                errorText = error.localizedDescription
            }
        }
    }

    private func compact(_ value: String) -> String {
        guard value.count > 22 else { return value }
        return "\(value.prefix(12))…\(value.suffix(7))"
    }
}
