import SwiftUI

struct TerminalsView: View {
    @EnvironmentObject private var session: ConsoleSession
    let onOpenNetwork: () -> Void

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    ConsoleBackdrop()

                    ScrollView {
                        VStack(spacing: 18) {
                            ConsoleHeader(
                                path: "console://terminals",
                                title: "Терминалы",
                                trailing: String(format: "%02d ACTIVE", session.terminals.count)
                            )

                            ConsoleMetricStrip(metrics: [
                                ("CHANNELS", String(format: "%02d", session.terminals.count), session.terminals.isEmpty ? ConsoleTheme.secondary : ConsoleTheme.accent),
                                ("NETWORK", session.networkOnline ? "READY" : "IDLE", session.networkOnline ? ConsoleTheme.accent : ConsoleTheme.warning),
                                ("E2EE", "OFF", ConsoleTheme.warning)
                            ])

                            if session.terminals.isEmpty {
                                emptyState
                            } else {
                                terminalGrid(width: proxy.size.width)
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
            .navigationDestination(for: TerminalSummary.self) { terminal in
                TerminalView(terminal: terminal)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func terminalGrid(width: CGFloat) -> some View {
        let columns = width >= 900
            ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            : [GridItem(.flexible())]

        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(session.terminals) { terminal in
                NavigationLink(value: terminal) {
                    terminalRow(terminal)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        ConsoleWindowCard(title: "terminals.list") {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    ConsoleNodeGlyph(active: false)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("РЕЗУЛЬТАТОВ: 0")
                            .font(.console(9, weight: .black))
                            .foregroundStyle(ConsoleTheme.accent)
                        Text("АКТИВНЫХ ТЕРМИНАЛОВ НЕТ")
                            .font(.consoleDisplay(18, weight: .bold))
                            .foregroundStyle(ConsoleTheme.text)
                    }
                }

                Text("Найдите узел в Network и инициируйте Handshake. Терминал появится только после разрешения второй стороны.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(4)
                    .frame(maxWidth: 620, alignment: .leading)

                ConsoleCommandButton(title: "ОТКРЫТЬ NETWORK") {
                    onOpenNetwork()
                }
            }
        }
    }

    private func terminalRow(_ terminal: TerminalSummary) -> some View {
        ConsoleCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 13) {
                    ConsoleNodeGlyph()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("@\(terminal.peer.handle)")
                            .font(.consoleDisplay(17, weight: .bold))
                            .foregroundStyle(ConsoleTheme.text)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            ConsoleStatusDot(active: true)
                            Text("ТЕРМИНАЛ АКТИВЕН")
                                .font(.console(8, weight: .black))
                                .foregroundStyle(ConsoleTheme.accent)
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ConsoleTheme.muted)
                }

                Rectangle().fill(ConsoleTheme.line).frame(height: 1)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NODE")
                            .font(.console(7.5, weight: .black))
                            .foregroundStyle(ConsoleTheme.muted)
                        Text(compact(terminal.peer.nodeID))
                            .font(.console(9, weight: .bold))
                            .foregroundStyle(ConsoleTheme.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("FINGERPRINT")
                            .font(.console(7.5, weight: .black))
                            .foregroundStyle(ConsoleTheme.muted)
                        Text(compact(terminal.peer.fingerprint))
                            .font(.console(9, weight: .bold))
                            .foregroundStyle(ConsoleTheme.secondary)
                    }
                }
            }
        }
    }

    private func compact(_ value: String) -> String {
        guard value.count > 20 else { return value }
        return "\(value.prefix(10))…\(value.suffix(6))"
    }
}
