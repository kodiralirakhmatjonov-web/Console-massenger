import SwiftUI

struct HandshakeDetailView: View {
    @EnvironmentObject private var session: ConsoleSession
    @Environment(\.dismiss) private var dismiss

    let request: HandshakeRequest

    @State private var busy = false
    @State private var errorText: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ConsoleBackdrop()

                ScrollView {
                    VStack {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                HStack(spacing: 7) {
                                    Image(systemName: "chevron.left")
                                    Text("BACK")
                                }
                                .font(.console(9, weight: .black))
                                .foregroundStyle(ConsoleTheme.secondary)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                            ConsoleStatusPill(text: "HANDSHAKE")
                        }

                        VStack(alignment: .leading, spacing: 0) {
                            Text("ПОПЫТКА\nПОДКЛЮЧЕНИЯ")
                                .font(.consoleDisplay(proxy.size.width < 500 ? 38 : 48, weight: .heavy))
                                .tracking(-1.5)
                                .foregroundStyle(ConsoleTheme.text)

                            Text("Удалённый узел запрашивает разрешение открыть Terminal. Содержимое сообщений до принятия Handshake не отображается.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ConsoleTheme.secondary)
                                .lineSpacing(4)
                                .padding(.top, 16)

                            ConsoleWindowCard(title: "handshake.inspect") {
                                VStack(alignment: .leading, spacing: 17) {
                                    ConsoleSystemLine(text: "connection request received", tone: .warning)
                                    dataRow("УЗЕЛ", request.peer.map { "@\($0.handle)" } ?? request.fromNode)
                                    dataRow("NODE ID", request.peer?.nodeID ?? request.fromNode)
                                    dataRow("ОТПЕЧАТОК", request.peer?.fingerprint ?? "НЕ ПОЛУЧЕН")
                                    dataRow("СОСТОЯНИЕ ДОВЕРИЯ", "НЕОПРЕДЕЛЕНО")
                                }
                            }
                            .padding(.top, 26)

                            ConsoleCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "exclamationmark.shield")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(ConsoleTheme.warning)

                                    Text("Разрешение создаст Terminal между двумя Identity. Текущая версия Console ещё не использует E2EE — интерфейс не выдаёт это соединение за защищённый криптографический канал.")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundStyle(ConsoleTheme.secondary)
                                        .lineSpacing(3)
                                }
                            }
                            .padding(.top, 14)

                            if let errorText {
                                ConsoleSystemLine(text: errorText, tone: .error)
                                    .padding(.top, 14)
                            }

                            VStack(spacing: 10) {
                                ConsolePrimaryButton(
                                    title: busy ? "ОБРАБОТКА..." : "РАЗРЕШИТЬ ДОСТУП",
                                    disabled: busy
                                ) {
                                    decide("accepted")
                                }

                                Button {
                                    decide("rejected")
                                } label: {
                                    Text("ОТКЛОНИТЬ ПОДКЛЮЧЕНИЕ")
                                        .font(.console(10, weight: .black))
                                        .foregroundStyle(ConsoleTheme.destructive)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(ConsoleTheme.destructive.opacity(0.055))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                .stroke(ConsoleTheme.destructive.opacity(0.22), lineWidth: 1)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(busy)
                            }
                            .padding(.top, 18)
                        }
                        .padding(24)
                        .background(ConsoleTheme.backgroundRaised.opacity(0.78))
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(ConsoleTheme.line, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .padding(.top, 22)
                    }
                    .frame(maxWidth: 720)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 22)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func dataRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.console(8, weight: .black))
                .tracking(0.7)
                .foregroundStyle(ConsoleTheme.muted)

            Text(value)
                .font(.console(12, weight: .bold))
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
