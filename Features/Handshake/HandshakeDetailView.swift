import SwiftUI

struct HandshakeDetailView: View {
    @EnvironmentObject private var session: ConsoleSession
    @Environment(\.dismiss) private var dismiss

    let request: HandshakeRequest

    @State private var busy = false
    @State private var errorText: String?
    @State private var accepted = false

    var body: some View {
        ZStack {
            ConsoleBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                        .padding(.bottom, 34)

                    Text("INCOMING HANDSHAKE")
                        .font(.console(10, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(ConsoleTheme.accent)

                    Text("ПОПЫТКА\nПОДКЛЮЧЕНИЯ")
                        .font(.consoleDisplay(34, weight: .heavy))
                        .tracking(-1.25)
                        .foregroundStyle(ConsoleTheme.text)
                        .padding(.top, 8)

                    Text("Неизвестный узел запрашивает доступ к новому Terminal.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .lineSpacing(4)
                        .padding(.top, 10)

                    ConsoleWindowCard(title: "handshake.request") {
                        VStack(alignment: .leading, spacing: 15) {
                            ConsoleSystemLine(text: "connection request received", tone: .warning)
                            dataRow("УЗЕЛ", request.peer.map { "@\($0.handle)" } ?? request.fromNode)
                            dataRow("NODE ID", request.peer?.nodeID ?? request.fromNode)
                            dataRow("FINGERPRINT", request.peer?.fingerprint ?? "НЕ ПОЛУЧЕН")

                            HStack {
                                Text("TRUST STATE")
                                    .font(.console(8, weight: .black))
                                    .foregroundStyle(ConsoleTheme.muted)
                                Spacer()
                                Text("НЕОПРЕДЕЛЕНО")
                                    .font(.console(9, weight: .black))
                                    .foregroundStyle(ConsoleTheme.warning)
                            }
                        }
                    }
                    .padding(.top, 24)

                    ConsoleWindowCard(title: "protocol.notice") {
                        VStack(alignment: .leading, spacing: 9) {
                            ConsoleSystemLine(text: "accept creates terminal membership", tone: .normal)
                            ConsoleSystemLine(text: "messaging E2EE is not active", tone: .warning)

                            Text("Разрешение создаст Terminal между двумя Identity. Текущая версия не заявляет защищённый канал.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(ConsoleTheme.secondary)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.top, 12)

                    if let errorText {
                        ConsoleSystemLine(text: errorText, tone: .error)
                            .padding(.top, 16)
                    }

                    VStack(spacing: 11) {
                        ConsolePrimaryButton(
                            title: busy ? "ОБРАБОТКА..." : "РАЗРЕШИТЬ ДОСТУП",
                            disabled: busy
                        ) {
                            decide("accepted")
                        }

                        Button {
                            decide("rejected")
                        } label: {
                            Text("ОТКЛОНИТЬ")
                                .font(.console(10, weight: .black))
                                .foregroundStyle(ConsoleTheme.destructive)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(ConsoleTheme.surface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(ConsoleTheme.destructive.opacity(0.22), lineWidth: 1)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(busy)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 22)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }

            if accepted {
                successOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ConsoleTheme.text)
                    .frame(width: 36, height: 36)
                    .background(ConsoleTheme.surface)
                    .overlay {
                        Circle().stroke(ConsoleTheme.line, lineWidth: 1)
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            ConsoleStatusPill(text: "HANDSHAKE")
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.93).ignoresSafeArea()

            VStack(spacing: 17) {
                ZStack {
                    Circle()
                        .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
                        .frame(width: 66, height: 66)
                        .shadow(color: ConsoleTheme.accent.opacity(0.14), radius: 26)

                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(ConsoleTheme.accent)
                }

                Text("CHANNEL READY")
                    .font(.console(11, weight: .black))
                    .tracking(1.25)
                    .foregroundStyle(ConsoleTheme.accent)

                Text("ТЕРМИНАЛ\nАКТИВИРОВАН")
                    .font(.consoleDisplay(28, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ConsoleTheme.text)

                Text("Участники подтверждены сервером. E2EE в текущей версии не активирован.")
                    .font(.system(size: 11, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 29)
            .frame(maxWidth: 340)
            .background(
                LinearGradient(
                    colors: [ConsoleTheme.surfaceGreen, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private func dataRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.console(8, weight: .black))
                .tracking(0.7)
                .foregroundStyle(ConsoleTheme.muted)

            Text(value)
                .font(.console(11, weight: .bold))
                .foregroundStyle(ConsoleTheme.text)
                .textSelection(.enabled)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
    }

    private func decide(_ decision: String) {
        busy = true
        errorText = nil

        Task {
            do {
                try await session.decide(request, decision: decision)
                if decision == "accepted" {
                    withAnimation(.easeOut(duration: 0.18)) {
                        accepted = true
                    }
                    try? await Task.sleep(for: .milliseconds(950))
                }
                dismiss()
            } catch {
                errorText = error.localizedDescription
                busy = false
            }
        }
    }
}
