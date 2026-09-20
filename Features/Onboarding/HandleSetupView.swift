import SwiftUI

struct HandleSetupView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var handle = ""
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
                        ConsoleStatusPill(text: "KEY READY")
                    }

                    Spacer(minLength: 72)

                    Text("IDENTITY INITIALIZED")
                        .font(.console(10, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(ConsoleTheme.accent)

                    Text("Public\nHandle.")
                        .font(.consoleDisplay(42, weight: .heavy))
                        .tracking(-1.6)
                        .foregroundStyle(ConsoleTheme.text)
                        .padding(.top, 8)

                    Text("Handle используется для обнаружения в Network. Terminal привязывается к стабильному Node ID, а не к имени.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .lineSpacing(5)
                        .padding(.top, 14)

                    ConsoleWindowCard(title: "identity.handle") {
                        VStack(alignment: .leading, spacing: 12) {
                            ConsoleSystemLine(text: "public alias required")
                            ConsoleField(prompt: "handle", text: $handle)

                            HStack {
                                Text("NORMALIZED")
                                    .font(.console(8, weight: .black))
                                    .foregroundStyle(ConsoleTheme.muted)
                                Spacer()
                                Text("@\(ConsoleSession.normalizeHandle(handle))")
                                    .font(.console(10, weight: .black))
                                    .foregroundStyle(ConsoleTheme.accent)
                            }

                            if session.api.baseURL == nil {
                                ConsoleSystemLine(text: "network offline • handle will be local", tone: .warning)
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
                        title: session.networkBusy ? "ПРОВЕРКА..." : "ЗАФИКСИРОВАТЬ HANDLE",
                        disabled: session.networkBusy || !ConsoleSession.isValidHandle(ConsoleSession.normalizeHandle(handle))
                    ) {
                        claim()
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

    private func claim() {
        Task {
            do {
                try await session.claimHandle(handle)
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
