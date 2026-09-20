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
            ZStack {
                ConsoleBackdrop()

                ScrollView {
                    VStack(spacing: 14) {
                        ConsoleHeader(
                            path: "console://network",
                            title: "Network",
                            trailing: session.api.baseURL == nil ? "OFFLINE" : "SCANNER READY"
                        )

                        ConsoleMetricStrip(metrics: [
                            ("INCOMING", String(format: "%02d", session.incomingHandshakes.count), session.incomingHandshakes.isEmpty ? ConsoleTheme.secondary : ConsoleTheme.accent),
                            ("OUTGOING", String(format: "%02d", session.outgoingHandshakes.count), ConsoleTheme.text),
                            ("MATCHES", String(format: "%02d", results.count), results.isEmpty ? ConsoleTheme.secondary : ConsoleTheme.accent)
                        ])

                        searchPanel
                        requestPanel
                        resultPanel

                        if let lastNotice {
                            ConsoleSystemLine(text: lastNotice, tone: .success)
                                .padding(.horizontal, 2)
                        }

                        if let errorText {
                            ConsoleSystemLine(text: errorText, tone: .error)
                                .padding(.horizontal, 2)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
                .refreshable {
                    await session.refreshNetwork()
                }
            }
            .navigationDestination(for: HandshakeRequest.self) { request in
                HandshakeDetailView(request: request)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var searchPanel: some View {
        ConsoleWindowCard(title: "scan@network:~") {
            VStack(alignment: .leading, spacing: 12) {
                ConsoleSystemLine(text: searching ? "scanning identity registry..." : "scanner awaiting target", tone: searching ? .warning : .normal)

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
                        Text("QR")
                    }
                    .font(.console(9, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
                }
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
                }
            } else {
                ForEach(session.incomingHandshakes) { request in
                    NavigationLink(value: request) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(ConsoleTheme.accent.opacity(0.07))
                                    .frame(width: 39, height: 39)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
                                    }

                                Image(systemName: "link")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(ConsoleTheme.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("@\(request.peer?.handle ?? request.fromNode)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(ConsoleTheme.text)
                                Text("ПОПЫТКА ПОДКЛЮЧЕНИЯ")
                                    .font(.console(8.5, weight: .black))
                                    .foregroundStyle(ConsoleTheme.accent)
                            }

                            Spacer()

                            Text("REVIEW")
                                .font(.console(8, weight: .black))
                                .foregroundStyle(ConsoleTheme.muted)
                        }
                        .padding(13)
                        .background(ConsoleTheme.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var resultPanel: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ConsoleSectionLabel(title: "IDENTITY MATCHES", value: String(format: "%02d", results.count))

                ForEach(results) { identity in
                    ConsoleWindowCard(title: "identity://\(identity.handle)") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("@\(identity.handle)")
                                        .font(.consoleDisplay(18, weight: .bold))
                                        .foregroundStyle(ConsoleTheme.text)
                                    Text("NODE \(compact(identity.nodeID))")
                                        .font(.console(9, weight: .bold))
                                        .foregroundStyle(ConsoleTheme.muted)
                                }

                                Spacer()

                                ConsoleStatusPill(text: "DISCOVERED")
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

                            ConsoleCommandButton(title: "УСТАНОВИТЬ СОЕДИНЕНИЕ") {
                                requestConnection(identity)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
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
