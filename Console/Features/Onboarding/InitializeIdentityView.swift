import SwiftUI

struct InitializeIdentityView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var lines: [String] = []
    @State private var running = false
    @State private var errorText: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ConsoleBackdrop()

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: proxy.size.height > 760 ? 90 : 34)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                ConsoleStatusPill(text: "IDENTITY PROTOCOL")
                                Spacer()
                                Text("01/02")
                                    .font(.console(8, weight: .black))
                                    .foregroundStyle(ConsoleTheme.muted)
                            }

                            Text("> CONSOLE")
                                .font(.console(12, weight: .black))
                                .foregroundStyle(ConsoleTheme.accent)
                                .padding(.top, 36)

                            Text("IDENTITY\nREQUIRED")
                                .font(.consoleDisplay(proxy.size.width < 500 ? 42 : 54, weight: .heavy))
                                .tracking(-1.8)
                                .foregroundStyle(ConsoleTheme.text)
                                .padding(.top, 12)

                            Text("Создайте локальную Identity. Закрытый ключ будет сформирован и сохранён на этом устройстве.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ConsoleTheme.secondary)
                                .lineSpacing(5)
                                .padding(.top, 18)
                                .frame(maxWidth: 560, alignment: .leading)

                            ConsoleWindowCard(title: "identity.init") {
                                VStack(alignment: .leading, spacing: 12) {
                                    ConsoleSystemLine(text: "local identity initialization", tone: .normal)

                                    if lines.isEmpty {
                                        Text("ОЖИДАНИЕ КОМАНДЫ")
                                            .font(.console(9, weight: .black))
                                            .foregroundStyle(ConsoleTheme.muted)
                                    } else {
                                        ForEach(lines, id: \.self) { line in
                                            Text(line)
                                                .font(.console(10, weight: .bold))
                                                .foregroundStyle(ConsoleTheme.accent)
                                        }
                                    }

                                    if let errorText {
                                        ConsoleSystemLine(text: errorText, tone: .error)
                                    }
                                }
                                .frame(minHeight: 94, alignment: .topLeading)
                            }
                            .padding(.top, 30)

                            ConsolePrimaryButton(
                                title: running ? "ИНИЦИАЛИЗАЦИЯ..." : "ИНИЦИАЛИЗИРОВАТЬ ЛИЧНОСТЬ",
                                disabled: running
                            ) {
                                initialize()
                            }
                            .padding(.top, 18)

                            Text("SECURITY NOTE // E2EE ЕЩЁ НЕ АКТИВИРОВАНО В ЭТОЙ СБОРКЕ")
                                .font(.console(7.5, weight: .black))
                                .foregroundStyle(ConsoleTheme.warning)
                                .padding(.top, 15)
                        }
                        .padding(26)
                        .background(ConsoleTheme.backgroundRaised.opacity(0.76))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(ConsoleTheme.line, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .frame(maxWidth: 720)
                        .padding(.horizontal, 18)

                        Spacer(minLength: 34)
                    }
                    .frame(minHeight: proxy.size.height)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func initialize() {
        guard !running else { return }
        running = true
        errorText = nil
        lines = ["> сбор энтропии"]

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(240))
            lines.append("> формирование ключа")
            try? await Task.sleep(for: .milliseconds(240))
            lines.append("> создание сигнатуры")

            do {
                try session.initializeIdentity()
            } catch {
                errorText = error.localizedDescription
                running = false
            }
        }
    }
}
