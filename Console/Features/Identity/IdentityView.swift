import CoreImage.CIFilterBuiltins
import SwiftUI

struct IdentityView: View {
    @EnvironmentObject private var session: ConsoleSession

    @State private var endpoint = ""
    @State private var endpointMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ConsoleHeader(
                    path: "console://identity",
                    title: "IDENTITY",
                    trailing: "LOCAL KEY"
                )
                .padding(.bottom, 8)

                identityCard
                qrCard
                networkCard
                securityCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(ConsoleTheme.background)
        .onAppear {
            endpoint = session.endpointStore.value?.absoluteString ?? ""
        }
    }

    private var identityCard: some View {
        ConsoleCard {
            VStack(alignment: .leading, spacing: 18) {
                dataRow("HANDLE", "@\(session.profile?.handle ?? "unknown")")
                dataRow("NODE", session.identity?.nodeID ?? "—")
                dataRow("ОТПЕЧАТОК", session.identity?.fingerprint ?? "—")

                Button {
                    UIPasteboard.general.string = session.identity?.nodeID
                } label: {
                    Label("КОПИРОВАТЬ NODE ID", systemImage: "doc.on.doc")
                        .font(.console(10, weight: .bold))
                        .foregroundStyle(ConsoleTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var qrCard: some View {
        ConsoleCard {
            HStack(spacing: 18) {
                if let image = qrImage {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 104, height: 104)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("IDENTITY QR")
                        .font(.console(12, weight: .bold))
                        .foregroundStyle(ConsoleTheme.text)

                    Text("QR содержит только публичный Node ID и handle.")
                        .font(.console(10))
                        .foregroundStyle(ConsoleTheme.muted)
                        .lineSpacing(3)
                }

                Spacer()
            }
        }
    }

    private var networkCard: some View {
        ConsoleCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("NETWORK ENDPOINT")
                    .font(.console(10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)

                ConsoleField(prompt: "https://...workers.dev", text: $endpoint)

                Button {
                    do {
                        try session.saveServerURL(endpoint)
                        endpointMessage = "СЕТЬ СОХРАНЕНА"
                        Task { await session.refreshNetwork() }
                    } catch {
                        endpointMessage = error.localizedDescription
                    }
                } label: {
                    Text("ПРИМЕНИТЬ ENDPOINT")
                        .font(.console(10, weight: .bold))
                        .foregroundStyle(ConsoleTheme.accent)
                }
                .buttonStyle(.plain)

                if let endpointMessage {
                    Text(endpointMessage)
                        .font(.console(9, weight: .bold))
                        .foregroundStyle(endpointMessage.contains("СОХРАНЕНА") ? ConsoleTheme.accent : ConsoleTheme.destructive)
                }
            }
        }
    }

    private var securityCard: some View {
        ConsoleCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("SECURITY STATE")
                    .font(.console(10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)

                Text("IDENTITY KEY: LOCAL")
                    .font(.console(11, weight: .bold))
                    .foregroundStyle(ConsoleTheme.accent)

                Text("MESSAGING: REALTIME V1\nE2EE: НЕ АКТИВИРОВАНО")
                    .font(.console(10, weight: .bold))
                    .foregroundStyle(ConsoleTheme.warning)
                    .lineSpacing(4)

                Text("Интерфейс намеренно не показывает «защищённый канал», пока проверенный E2EE-протокол не подключён.")
                    .font(.console(10))
                    .foregroundStyle(ConsoleTheme.muted)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func dataRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.console(9, weight: .bold))
                .foregroundStyle(ConsoleTheme.muted)
            Text(value)
                .font(.console(12, weight: .bold))
                .foregroundStyle(ConsoleTheme.text)
                .textSelection(.enabled)
        }
    }

    private var qrImage: UIImage? {
        guard let identity = session.identity,
              let handle = session.profile?.handle else { return nil }

        let payload = "console://identity/\(identity.nodeID)?handle=\(handle)"
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        let transformed = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
