import SwiftUI

struct TerminalsView: View {
    @EnvironmentObject private var session: ConsoleSession

    var body: some View {
        NavigationStack {
            ZStack {
                ConsoleTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 10) {
                        identityHeader

                        ForEach(session.terminals) { terminal in
                            NavigationLink(value: terminal) {
                                terminalRow(terminal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationDestination(for: TerminalSummary.self) { terminal in
                TerminalView(terminal: terminal)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var identityHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("console://network")
                .font(ConsoleTheme.monoSmall)
                .foregroundStyle(ConsoleTheme.accent)

            Text("ТЕРМИНАЛЫ")
                .font(.system(size: 34, weight: .black, design: .monospaced))
                .foregroundStyle(ConsoleTheme.text)

            if let identity = session.identity {
                Text("\(identity.nodeID)  \(identity.fingerprint)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(ConsoleTheme.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 18)
    }

    private func terminalRow(_ terminal: TerminalSummary) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(terminal.connected ? ConsoleTheme.accent : ConsoleTheme.muted)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 5) {
                Text(terminal.node)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(ConsoleTheme.text)

                Text(terminal.preview)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(ConsoleTheme.muted)
            }

            Spacer()

            if terminal.unread > 0 {
                Text(String(terminal.unread))
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.black)
                    .frame(width: 24, height: 24)
                    .background(ConsoleTheme.accent)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(ConsoleTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(ConsoleTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
