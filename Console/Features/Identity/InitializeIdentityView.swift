import SwiftUI

struct InitializeIdentityView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var isInitializing = false
    @State private var statusLines: [String] = []
    @State private var errorText: String?

    var body: some View {
        ZStack {
            ConsoleTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("> CONSOLE")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(ConsoleTheme.accent)

                Text("IDENTITY\nREQUIRED")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .tracking(-2)
                    .foregroundStyle(ConsoleTheme.text)
                    .padding(.top, 18)

                Text("Создайте локальную Identity.\nЗакрытый ключ останется на этом устройстве.")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(ConsoleTheme.muted)
                    .lineSpacing(6)
                    .padding(.top, 18)

                if !statusLines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(statusLines, id: \.self) { line in
                            Text(line)
                                .font(ConsoleTheme.monoSmall)
                                .foregroundStyle(ConsoleTheme.accent)
                        }
                    }
                    .padding(.top, 28)
                }

                if let errorText {
                    Text(errorText)
                        .font(ConsoleTheme.monoSmall)
                        .foregroundStyle(.red)
                        .padding(.top, 20)
                }

                Spacer()

                Button {
                    initialize()
                } label: {
                    HStack {
                        Text(isInitializing ? "ИНИЦИАЛИЗАЦИЯ..." : "ИНИЦИАЛИЗИРОВАТЬ ЛИЧНОСТЬ")
                        Spacer()
                        Text("↵")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .frame(height: 58)
                    .background(ConsoleTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .disabled(isInitializing)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
    }

    private func initialize() {
        guard !isInitializing else { return }
        isInitializing = true
        errorText = nil
        statusLines = ["> сбор энтропии"]

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            statusLines.append("> формирование локального ключа")
            try? await Task.sleep(for: .milliseconds(280))
            statusLines.append("> создание публичной сигнатуры")

            do {
                try session.initializeIdentity()
            } catch {
                errorText = "ОПЕРАЦИЯ ОТКЛОНЕНА\n\(error.localizedDescription)"
                isInitializing = false
            }
        }
    }
}
