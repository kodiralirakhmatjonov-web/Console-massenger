import SwiftUI

struct HandleSetupView: View {
    @EnvironmentObject private var session: ConsoleSession
    @State private var handle = ""
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("> IDENTITY INITIALIZED")
                .font(.console(12, weight: .bold))
                .foregroundStyle(ConsoleTheme.accent)

            Text("PUBLIC\nHANDLE")
                .font(.console(44, weight: .black))
                .tracking(-1.8)
                .foregroundStyle(ConsoleTheme.text)
                .padding(.top, 18)

            Text("Handle нужен только для обнаружения в Network.\nTerminal привязывается к Node ID, а не к имени.")
                .font(.console(13))
                .foregroundStyle(ConsoleTheme.secondary)
                .lineSpacing(5)
                .padding(.top, 16)

            ConsoleField(prompt: "handle", text: $handle)
                .padding(.top, 30)

            Text("@\(ConsoleSession.normalizeHandle(handle))")
                .font(.console(11, weight: .bold))
                .foregroundStyle(ConsoleTheme.muted)
                .padding(.top, 10)

            if session.api.baseURL == nil {
                Text("СЕТЬ НЕ НАСТРОЕНА · HANDLE БУДЕТ СОХРАНЁН ЛОКАЛЬНО")
                    .font(.console(9, weight: .bold))
                    .foregroundStyle(ConsoleTheme.warning)
                    .padding(.top, 18)
            }

            if let errorText {
                Text(errorText)
                    .font(.console(10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.destructive)
                    .padding(.top, 16)
            }

            Spacer()

            ConsolePrimaryButton(
                title: session.networkBusy ? "ПРОВЕРКА..." : "ЗАФИКСИРОВАТЬ HANDLE",
                disabled: session.networkBusy || !ConsoleSession.isValidHandle(ConsoleSession.normalizeHandle(handle))
            ) {
                claim()
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
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
