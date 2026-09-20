import CoreImage.CIFilterBuiltins
import SwiftUI

struct IdentityView: View {
    @EnvironmentObject private var session: ConsoleSession

    @State private var endpoint = ""
    @State private var endpointMessage: String?

    var body: some View {
        ZStack {
            ConsoleBackdrop()

            ScrollView {
                VStack(spacing: 14) {
                    ConsoleHeader(
                        path: "console://identity",
                        title: "Identity",
                        trailing: "LOCAL KEY"
                    )

                    ConsoleMetricStrip(metrics: [
                        ("KEY", "LOCAL", ConsoleTheme.accent),
                        ("NETWORK", session.api.baseURL == nil ? "OFFLINE" : "READY", session.api.baseURL == nil ? ConsoleTheme.warning : ConsoleTheme.accent),
                        ("E2EE", "OFF", ConsoleTheme.warning)
                    ])

                    identityCard
                    qrCard
                    networkCard
                    securityCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            endpoint = session.endpointStore.value?.absoluteString ?? ""
        }
    }

    private var identityCard: some View {
        ConsoleWindowCard(title: "identity@console:~") {
            VStack(alignment: .leading, spacing: 14) {
                ConsoleSystemLine(text: "local signing identity mounted", tone: .success)
                dataRow("HANDLE", "@\(session.profile?.handle ?? "unknown")")
                dataRow("NODE", session.identity?.nodeID ?? "—")
                dataRow("FINGERPRINT", session.identity?.fingerprint ?? "—")

                Rectangle().fill(ConsoleTheme.line).frame(height: 1)

                ConsoleCommandButton(title: "КОПИРОВАТЬ NODE ID") {
                    UIPasteboard.general.string = session.identity?.nodeID
                }
            }
        }
    }

    private var qrCard: some View {
        ConsoleCard {
            HStack(spacing: 17) {
                if let image = qrImage {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding(7)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("IDENTITY QR")
                        .font(.console(10, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(ConsoleTheme.accent)

                    Text("Публичный код Identity")
                        .font(.consoleDisplay(16, weight: .bold))
                        .foregroundStyle(ConsoleTheme.text)

                    Text("Содержит только публичный Node ID и handle. Закрытый ключ в QR не входит.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .lineSpacing(3)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var networkCard: some View {
        ConsoleWindowCard(title: "network.config") {
            VStack(alignment: .leading, spacing: 12) {
                ConsoleSystemLine(text: session.api.baseURL == nil ? "endpoint not configured" : "endpoint loaded", tone: session.api.baseURL == nil ? .warning : .success)

                ConsoleField(prompt: "https://...workers.dev", text: $endpoint)

                ConsoleCommandButton(title: "ПРИМЕНИТЬ ENDPOINT") {
                    do {
                        try session.saveServerURL(endpoint)
                        endpointMessage = "СЕТЬ СОХРАНЕНА"
                        Task { await session.refreshNetwork() }
                    } catch {
                        endpointMessage = error.localizedDescription
                    }
                }

                if let endpointMessage {
                    ConsoleSystemLine(
                        text: endpointMessage,
                        tone: endpointMessage.contains("СОХРАНЕНА") ? .success : .error
                    )
                }
            }
        }
    }

    private var securityCard: some View {
        ConsoleWindowCard(title: "security.state") {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Text("SECURITY STATE")
                        .font(.console(9, weight: .black))
                        .foregroundStyle(ConsoleTheme.muted)
                    Spacer()
                    ConsoleStatusPill(text: "INTERNAL", active: false)
                }

                stateRow("IDENTITY KEY", "LOCAL", ConsoleTheme.accent)
                stateRow("MESSAGING", "REALTIME V1", ConsoleTheme.text)
                stateRow("E2EE", "НЕ АКТИВИРОВАНО", ConsoleTheme.warning)

                Rectangle().fill(ConsoleTheme.line).frame(height: 1)

                Text("Console не показывает состояние защищённого канала, пока проверенный E2EE-протокол действительно не активирован.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(3)
            }
        }
    }

    private func dataRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.console(8, weight: .black))
                .tracking(0.75)
                .foregroundStyle(ConsoleTheme.muted)
            Text(value)
                .font(.console(11, weight: .bold))
                .foregroundStyle(ConsoleTheme.text)
                .textSelection(.enabled)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
    }

    private func stateRow(_ key: String, _ value: String, _ color: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key)
                .font(.console(9, weight: .black))
                .foregroundStyle(ConsoleTheme.muted)
            Spacer()
            Text(value)
                .font(.console(9, weight: .black))
                .foregroundStyle(color)
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
