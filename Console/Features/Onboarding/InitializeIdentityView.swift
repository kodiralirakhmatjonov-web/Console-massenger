import SwiftUI

struct InitializeIdentityView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var lines: [String] = []
    @State private var running = false
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("> CONSOLE")
                .font(.console(13, weight: .bold))
                .foregroundStyle(ConsoleTheme.accent)

            Text("IDENTITY\nREQUIRED")
                .font(.console(46, weight: .black))
                .tracking(-2)
                .foregroundStyle(ConsoleTheme.text)
                .padding(.top, 18)

            Text("Создайте локальную Identity.\nЗакрытый ключ останется на этом устройстве.")
                .font(.console(14, weight: .medium))
                .foregroundStyle(ConsoleTheme.secondary)
                .lineSpacing(6)
                .padding(.top, 18)

            if !lines.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(lines, id: \.self) { line in
                        Text(line)
                            .font(.console(11, weight: .bold))
                            .foregroundStyle(ConsoleTheme.accent)
                    }
                }
                .padding(.top, 28)
            }

            if let errorText {
                Text(errorText)
                    .font(.console(11, weight: .bold))
                    .foregroundStyle(ConsoleTheme.destructive)
                    .padding(.top, 20)
            }

            Spacer()

            ConsolePrimaryButton(
                title: running ? "ИНИЦИАЛИЗАЦИЯ..." : "ИНИЦИАЛИЗИРОВАТЬ ЛИЧНОСТЬ",
                disabled: running
            ) {
                initialize()
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
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
