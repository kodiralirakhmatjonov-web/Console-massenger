import SwiftUI

struct TerminalsView: View {
    @EnvironmentObject private var session: ConsoleSession
    let onOpenNetwork: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ConsoleTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ConsoleHeader(
                            path: "console://terminals",
                            title: "ТЕРМИНАЛЫ",
                            trailing: String(format: "%02d", session.terminals.count)
                        )
                        .padding(.bottom, 14)

                        if session.terminals.isEmpty {
                            emptyState
                        } else {
                            ForEach(session.terminals) { terminal in
                                NavigationLink(value: terminal) {
                                    terminalRow(terminal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
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
        ConsoleCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("РЕЗУЛЬТАТОВ: 0")
                    .font(.console(11, weight: .bold))
                    .foregroundStyle(ConsoleTheme.accent)

                Text("АКТИВНЫХ ТЕРМИНАЛОВ НЕТ")
                    .font(.console(17, weight: .black))
                    .foregroundStyle(ConsoleTheme.text)

                Text("Найдите узел в Network и инициируйте Handshake. Терминал появится только после подтверждения второй стороны.")
                    .font(.console(12))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(4)

                Button(action: onOpenNetwork) {
                    Text("ОТКРЫТЬ NETWORK  →")
                        .font(.console(11, weight: .bold))
                        .foregroundStyle(ConsoleTheme.accent)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func terminalRow(_ terminal: TerminalSummary) -> some View {
        ConsoleCard {
            HStack(spacing: 14) {
                ConsoleStatusDot(active: true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("@\(terminal.peer.handle)")
                        .font(.console(15, weight: .bold))
                        .foregroundStyle(ConsoleTheme.text)

                    Text(terminal.peer.nodeID)
                        .font(.console(9, weight: .medium))
                        .foregroundStyle(ConsoleTheme.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
            }
        }
    }
}
