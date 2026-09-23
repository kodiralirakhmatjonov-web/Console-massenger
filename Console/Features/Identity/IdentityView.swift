import CoreImage.CIFilterBuiltins
import SwiftUI

struct IdentityView: View {
    @EnvironmentObject private var session: ConsoleSession

    @State private var endpoint = ""
    @State private var endpointMessage: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ConsoleBackdrop()

                ScrollView {
                    VStack(spacing: 18) {
                        ConsoleHeader(
                            path: "console://identity",
                            title: "Identity",
                            trailing: "LOCAL KEY"
                        )

                        ConsoleMetricStrip(metrics: [
                            ("KEY", "LOCAL", ConsoleTheme.accent),
                            ("NETWORK", networkMetric, session.networkOnline ? ConsoleTheme.accent : ConsoleTheme.warning),
                            ("E2EE", "OFF", ConsoleTheme.warning)
                        ])

                        if proxy.size.width >= 850 {
                            HStack(alignment: .top, spacing: 14) {
                                VStack(spacing: 14) {
                                    identityCard
                                    qrCard
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 14) {
                                    networkCard
                                    securityCard
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            identityCard
                            qrCard
                            networkCard
                            securityCard
                        }
                    }
                    .consolePageFrame()
                    .padding(.horizontal, proxy.size.width >= 760 ? 28 : 14)
                    .padding(.top, proxy.size.width >= 760 ? 26 : 16)
                    .padding(.bottom, 34)
                }
            }
        }
        .onAppear {
            endpoint = session.endpointStore.value?.absoluteString ?? ""
        }
    }

    private var identityCard: some View {
        ConsoleWindowCard(title: "identity@console:~") {
            VStack(alignment: .leading, spacing: 15) {
                ConsoleSystemLine(text: "local signing identity mounted", tone: .success)

                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        dataRow("HANDLE", "@\(session.profile?.handle ?? "unknown")")
                        dataRow("NODE", session.identity?.nodeID ?? "—")
                        dataRow("FINGERPRINT", session.identity?.fingerprint ?? "—")
                    }
                    Spacer(minLength: 0)
                }

                Rectangle().fill(ConsoleTheme.line).frame(height: 1)

                ConsoleCommandButton(title: "КОПИРОВАТЬ NODE ID") {
                    UIPasteboard.general.string = session.identity?.nodeID
                }
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
                        .frame(width: 106, height: 106)
                        .padding(7)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("IDENTITY QR")
                        .font(.console(9, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(ConsoleTheme.accent)

                    Text("Публичный код Identity")
                        .font(.consoleDisplay(17, weight: .bold))
                        .foregroundStyle(ConsoleTheme.text)

                    Text("QR содержит только публичный Node ID и handle. Закрытый ключ в него не входит.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(ConsoleTheme.secondary)
                        .lineSpacing(3)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var networkCard: some View {
        ConsoleWindowCard(title: "network.config") {
            VStack(alignment: .leading, spacing: 13) {
                ConsoleSystemLine(
                    text: networkStatusText,
                    tone: session.networkOnline ? .success : (session.api.baseURL == nil ? .error : .warning)
                )

                if let url = session.api.baseURL {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("PRODUCTION ENDPOINT")
                            .font(.console(8, weight: .black))
                            .tracking(0.7)
                            .foregroundStyle(ConsoleTheme.muted)
                        Text(url.absoluteString)
                            .font(.console(10, weight: .bold))
                            .foregroundStyle(ConsoleTheme.secondary)
                            .textSelection(.enabled)
                            .lineLimit(2)
                    }

                    ConsoleCommandButton(title: session.networkBusy ? "ПРОВЕРКА СЕТИ" : "ПЕРЕПОДКЛЮЧИТЬ") {
                        Task { await session.refreshNetwork() }
                    }
                    .disabled(session.networkBusy)
                }

                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        ConsoleField(prompt: "https://...workers.dev", text: $endpoint)

                        ConsoleCommandButton(title: "ПРИМЕНИТЬ ENDPOINT") {
                            do {
                                try session.saveServerURL(endpoint)
                                endpointMessage = "ENDPOINT СОХРАНЁН"
                                Task { await session.refreshNetwork() }
                            } catch {
                                endpointMessage = error.localizedDescription
                            }
                        }
                    }
                    .padding(.top, 10)
                } label: {
                    Text("ADVANCED / OVERRIDE")
                        .font(.console(8, weight: .black))
                        .foregroundStyle(ConsoleTheme.muted)
                }
                .tint(ConsoleTheme.muted)

                if let endpointMessage {
                    ConsoleSystemLine(
                        text: endpointMessage,
                        tone: endpointMessage.contains("СОХРАНЁН") ? .success : .error
                    )
                }
            }
        }
    }

    private var securityCard: some View {
        ConsoleWindowCard(title: "security.state") {
            VStack(alignment: .leading, spacing: 12) {
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
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(ConsoleTheme.secondary)
                    .lineSpacing(3)
            }
        }
    }

    private var networkMetric: String {
        guard session.api.baseURL != nil else { return "OFFLINE" }
        return session.networkOnline ? "READY" : "LINK"
    }

    private var networkStatusText: String {
        guard session.api.baseURL != nil else { return "production endpoint missing" }
        return session.networkOnline ? "production network connected" : "endpoint loaded / awaiting link"
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
