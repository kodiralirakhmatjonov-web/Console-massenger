import SwiftUI

struct TerminalView: View {
    let terminal: TerminalSummary
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var messages = [
        "КАНАЛ УСТАНОВЛЕН",
        "Привет. Это первый нативный терминал Console."
    ]

    var body: some View {
        ZStack {
            ConsoleTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().overlay(ConsoleTheme.line)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, text in
                            Text(index == 0 ? "> \(text)" : "user@console:~$ \(text)")
                                .font(.system(size: 13, weight: index == 0 ? .bold : .regular, design: .monospaced))
                                .foregroundStyle(index == 0 ? ConsoleTheme.accent : ConsoleTheme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                }

                composer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Button("←") { dismiss() }
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(ConsoleTheme.text)

            VStack(alignment: .leading, spacing: 3) {
                Text("console://terminal/\(terminal.node)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(ConsoleTheme.text)
                Text(terminal.connected ? "СОСТОЯНИЕ: ПОДКЛЮЧЁН" : "СОСТОЯНИЕ: ОТСОЕДИНЁН")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(terminal.connected ? ConsoleTheme.accent : ConsoleTheme.muted)
            }

            Spacer()
        }
        .padding(16)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("ввод...", text: $draft, axis: .vertical)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(ConsoleTheme.text)
                .padding(14)
                .background(ConsoleTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button("↵") {
                let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                messages.append(text) // optimistic local render
                draft = ""
            }
            .font(.system(size: 18, weight: .black, design: .monospaced))
            .foregroundStyle(.black)
            .frame(width: 50, height: 50)
            .background(ConsoleTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(12)
        .background(ConsoleTheme.background)
    }
}
