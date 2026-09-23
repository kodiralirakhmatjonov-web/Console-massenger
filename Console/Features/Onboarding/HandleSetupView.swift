import SwiftUI

struct HandleSetupView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var handle = ""
    @State private var errorText: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ConsoleBackdrop()

                ScrollView {
                    VStack {
                        Spacer(minLength: proxy.size.height > 760 ? 90 : 34)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                ConsoleStatusPill(text: "IDENTITY INITIALIZED")
                                Spacer()
                                Text("02/02")
                                    .font(.console(8, weight: .black))
                                    .foregroundStyle(ConsoleTheme.muted)
                            }

                            Text("PUBLIC\nHANDLE")
                                .font(.consoleDisplay(proxy.size.width < 500 ? 42 : 54, weight: .heavy))
                                .tracking(-1.7)
                                .foregroundStyle(ConsoleTheme.text)
                                .padding(.top, 36)

                            Text("Handle используется для обнаружения в Network. Terminal привязывается к Node ID, а не к отображаемому имени.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ConsoleTheme.secondary)
                                .lineSpacing(5)
                                .padding(.top, 18)
                                .frame(maxWidth: 580, alignment: .leading)

                            ConsoleWindowCard(title: "identity.handle") {
                                VStack(alignment: .leading, spacing: 12) {
                                    ConsoleField(prompt: "handle", text: $handle)

                                    HStack {
                                        Text("@\(ConsoleSession.normalizeHandle(handle))")
                                            .font(.console(10, weight: .black))
                                            .foregroundStyle(ConsoleTheme.accent)
                                        Spacer()
                                        Text("3–24 // a-z 0-9 _")
                                            .font(.console(7.5, weight: .bold))
                                            .foregroundStyle(ConsoleTheme.muted)
                                    }

                                    if session.api.baseURL == nil {
                                        ConsoleSystemLine(text: "СЕТЬ НЕ НАСТРОЕНА", tone: .warning)
                                    }

                                    if let errorText {
                                        ConsoleSystemLine(text: errorText, tone: .error)
                                    }
                                }
                            }
                            .padding(.top, 30)

                            ConsolePrimaryButton(
                                title: session.networkBusy ? "ПРОВЕРКА..." : "ЗАФИКСИРОВАТЬ HANDLE",
                                disabled: session.networkBusy || !ConsoleSession.isValidHandle(ConsoleSession.normalizeHandle(handle))
                            ) {
                                claim()
                            }
                            .padding(.top, 18)
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
