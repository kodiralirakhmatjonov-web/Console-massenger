import SwiftUI

struct TerminalsView: View {
    @EnvironmentObject private var session: ConsoleSession
    let onOpenNetwork: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ConsoleBackdrop()

                ScrollView {
                    LazyVStack(spacing: 13) {
                        ConsoleHeader(
                            path: "console://terminals",
                            title: "Терминалы",
                            trailing: session.api.baseURL == nil ? "OFFLINE" : "NETWORK LIVE"
                        )
                        .padding(.bottom, 2)

                        ConsoleMetricStrip(metrics: [
                            ("TERMINALS", String(format: "%02d", session.terminals.count), ConsoleTheme.text),
                            ("REQUESTS", String(format: "%02d", session.incomingHandshakes.count), session.incomingHandshakes.isEmpty ? ConsoleTheme.secondary : ConsoleTheme.accent),
                            ("STATE", session.api.baseURL == nil ? "LOCAL" : "READY", session.api.baseURL == nil ? ConsoleTheme.warning : ConsoleTheme.accent)
                        ])
                        .padding(.bottom, 5)

                        if session.terminals.isEmpty {
                            emptyState
                        } else {
                            ConsoleSectionLabel(title: "ACTIVE SESSIONS", value: String(format: "%02d", session.terminals.count))
                                .padding(.top, 3)

                            ForEach(session.terminals) { terminal in
                                NavigationLink(value: terminal) {
                                    terminalRow(terminal)
                                }
                                .buttonStyle(.plain)
                            }
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
            .navigationDestination(for: TerminalSummary.self) { terminal in
                TerminalView(terminal: terminal)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        ConsoleWindowCard(title: "terminals@console:~") {
            VStack(alignment: .leading, spacing: 13) {
                ConsoleSystemLine(text: "terminal index mounted", tone: .success)
                ConsoleSystemLine(text: "active sessions: 0")
                ConsoleSystemLine(text: "waiting for accepted handshake", tone: .warning)

                Rectangle()
                    .fill(ConsoleTheme.line)
                    .frame(height: 1)
                    .padding(.vertical, 3)

                Text("АКТИВНЫХ ТЕРМИНАЛОВ НЕТ")
                    .font(.consoleDisplay(17, weight: .bold))
                    .foregroundStyle(ConsoleTheme.text)

                Text("Найдите узел в Network. Терминал создаётся только после того, как вторая сторона разрешит Handshake.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(4)

                ConsoleCommandButton(title: "ОТКРЫТЬ NETWORK", action: onOpenNetwork)
                    .padding(.top, 3)
            }
        }
    }

    private func terminalRow(_ terminal: TerminalSummary) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(ConsoleTheme.surfaceGreen)
                    .frame(width: 42, height: 42)
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
                    }

                Text(String(terminal.peer.handle.prefix(1)).uppercased())
                    .font(.console(14, weight: .black))
                    .foregroundStyle(ConsoleTheme.accent)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    ConsoleStatusDot(active: true)
                    Text("@\(terminal.peer.handle)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ConsoleTheme.text)
                }

                Text("NODE \(compactNode(terminal.peer.nodeID))")
                    .font(.console(8.5, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("OPEN")
                    .font(.console(8, weight: .black))
                    .foregroundStyle(ConsoleTheme.accent)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
            }
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 68)
        .background(ConsoleTheme.surface)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(ConsoleTheme.accent.opacity(0.70))
                .frame(width: 2)
                .padding(.vertical, 12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ConsoleTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func compactNode(_ value: String) -> String {
        guard value.count > 18 else { return value }
        return "\(value.prefix(10))…\(value.suffix(6))"
    }
}
