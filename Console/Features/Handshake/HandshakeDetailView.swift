import SwiftUI

struct HandshakeDetailView: View {
    @EnvironmentObject private var session: ConsoleSession
    @Environment(\.dismiss) private var dismiss

    let request: HandshakeRequest

    @State private var busy = false
    @State private var errorText: String?

    var body: some View {
        ZStack {
            ConsoleTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button("←") { dismiss() }
                        .font(.console(18, weight: .bold))
                        .foregroundStyle(ConsoleTheme.text)

                    Spacer()

                    Text("HANDSHAKE")
                        .font(.console(10, weight: .bold))
                        .foregroundStyle(ConsoleTheme.muted)
                }

                Spacer()

                Text("ПОПЫТКА\nПОДКЛЮЧЕНИЯ")
                    .font(.console(34, weight: .black))
                    .foregroundStyle(ConsoleTheme.text)

                VStack(alignment: .leading, spacing: 18) {
                    dataRow("УЗЕЛ", request.peer?.handle.map { "@\($0)" } ?? request.fromNode)
                    dataRow("NODE ID", request.peer?.nodeID ?? request.fromNode)
                    dataRow("ОТПЕЧАТОК", request.peer?.fingerprint ?? "НЕ ПОЛУЧЕН")
                    dataRow("СОСТОЯНИЕ ДОВЕРИЯ", "НЕОПРЕДЕЛЕНО")
                }
                .padding(.top, 30)

                Text("Разрешение создаст Terminal между двумя Identity. Текущая alpha-версия ещё не заявляет E2EE.")
                    .font(.console(10))
                    .foregroundStyle(ConsoleTheme.muted)
                    .lineSpacing(4)
                    .padding(.top, 26)

                if let errorText {
                    Text(errorText)
                        .font(.console(10, weight: .bold))
                        .foregroundStyle(ConsoleTheme.destructive)
                        .padding(.top, 18)
                }

                Spacer()

                VStack(spacing: 10) {
                    ConsolePrimaryButton(title: busy ? "ОБРАБОТКА..." : "РАЗРЕШИТЬ ДОСТУП", disabled: busy) {
                        decide("accepted")
                    }

                    Button {
                        decide("rejected")
                    } label: {
                        Text("ОТКЛОНИТЬ")
                            .font(.console(11, weight: .bold))
                            .foregroundStyle(ConsoleTheme.destructive)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .disabled(busy)
                }
            }
            .padding(20)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func dataRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.console(9, weight: .bold))
                .foregroundStyle(ConsoleTheme.muted)
            Text(value)
                .font(.console(13, weight: .bold))
                .foregroundStyle(ConsoleTheme.text)
                .textSelection(.enabled)
        }
    }

    private func decide(_ decision: String) {
        busy = true
        errorText = nil

        Task {
            do {
                try await session.decide(request, decision: decision)
                dismiss()
            } catch {
                errorText = error.localizedDescription
                busy = false
            }
        }
    }
}
