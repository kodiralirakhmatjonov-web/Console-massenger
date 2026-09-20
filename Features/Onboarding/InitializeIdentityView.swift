import SwiftUI

struct InitializeIdentityView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var lines: [String] = []
    @State private var running = false
    @State private var errorText: String?

    var body: some View {
        ZStack {
            ConsoleBackdrop()

            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 9) {
                        ConsoleStatusDot(active: true)
                        Text("CONSOLE // IDENTITY CORE")
                            .font(.console(9, weight: .black))
                            .tracking(1.05)
                            .foregroundStyle(ConsoleTheme.text.opacity(0.88))
                        Spacer()
                        ConsoleStatusPill(text: "LOCAL")
                    }

                    Spacer(minLength: 72)

                    Text("INITIALIZATION")
                        .font(.console(10, weight: .black))
                        .tracking(1.3)
                        .foregroundStyle(ConsoleTheme.accent)

                    Text("Создайте\nIdentity.")
                        .font(.consoleDisplay(42, weight: .heavy))
                        .tracking(-1.7)
                        .foregroundStyle(ConsoleTheme.text)
                        .padding(.top, 8)

                    Text("Закрытый ключ создаётся на этом устройстве и сохраняется локально в Keychain.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .lineSpacing(5)
                        .padding(.top, 14)

                    ConsoleWindowCard(title: "identity.init") {
                        VStack(alignment: .leading, spacing: 10) {
                            if lines.isEmpty {
                                ConsoleSystemLine(text: "identity engine awaiting command")
                                ConsoleSystemLine(text: "private key destination: local keychain")
                            } else {
                                ForEach(lines.indices, id: \.self) { index in
                                    ConsoleSystemLine(
                                        text: lines[index],
                                        tone: index == lines.count - 1 && running ? .warning : .success
                                    )
                                }
                            }

                            if running {
                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Rectangle().fill(ConsoleTheme.surfaceRaised)
                                        Rectangle()
                                            .fill(ConsoleTheme.accent)
                                            .frame(width: proxy.size.width * progress)
                                            .shadow(color: ConsoleTheme.accent.opacity(0.38), radius: 8)
                                    }
                                }
                                .frame(height: 3)
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.top, 28)

                    if let errorText {
                        ConsoleSystemLine(text: errorText, tone: .error)
                            .padding(.top, 14)
                    }

                    Spacer(minLength: 64)

                    ConsolePrimaryButton(
                        title: running ? "ИНИЦИАЛИЗАЦИЯ..." : "ИНИЦИАЛИЗИРОВАТЬ IDENTITY",
                        disabled: running
                    ) {
                        initialize()
                    }
                }
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private var progress: CGFloat {
        if lines.count >= 3 { return 0.90 }
        if lines.count == 2 { return 0.62 }
        if lines.count == 1 { return 0.30 }
        return 0.08
    }

    private func initialize() {
        guard !running else { return }
        running = true
        errorText = nil
        lines = ["сбор системной энтропии"]

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(190))
            lines.append("формирование локального signing key")
            try? await Task.sleep(for: .milliseconds(190))
            lines.append("вычисление public fingerprint")

            do {
                try session.initializeIdentity()
            } catch {
                errorText = error.localizedDescription
                running = false
            }
        }
    }
}
