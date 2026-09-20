import SwiftUI

struct ConsoleBackdrop: View {
    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    ConsoleTheme.accent.opacity(0.085),
                    ConsoleTheme.accent.opacity(0.018),
                    Color.clear
                ],
                center: UnitPoint(x: 0.50, y: 0.02),
                startRadius: 0,
                endRadius: 390
            )

            Canvas { context, size in
                var path = Path()
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += 4
                }
                context.stroke(path, with: .color(.white.opacity(0.022)), lineWidth: 0.45)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct ConsoleHeader: View {
    let path: String
    let title: String
    var trailing: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 9) {
                ConsoleStatusDot(active: true)

                Text("CONSOLE // HUMAN PROTOCOL")
                    .font(.console(9, weight: .black))
                    .tracking(1.15)
                    .foregroundStyle(ConsoleTheme.text.opacity(0.88))

                Spacer(minLength: 8)

                if let trailing {
                    ConsoleStatusPill(text: trailing, active: trailing != "OFFLINE")
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(path.uppercased())
                    .font(.console(10, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(ConsoleTheme.accent)

                Text(title)
                    .font(.consoleDisplay(30, weight: .heavy))
                    .tracking(-1.15)
                    .foregroundStyle(ConsoleTheme.text)
            }
        }
    }
}

struct ConsoleCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(ConsoleTheme.surface)
            .overlay {
                RoundedRectangle(cornerRadius: ConsoleTheme.radius, style: .continuous)
                    .stroke(ConsoleTheme.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: ConsoleTheme.radius, style: .continuous))
    }
}

struct ConsoleWindowCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(ConsoleTheme.destructive).frame(width: 7, height: 7)
                Circle().fill(Color(red: 254 / 255, green: 188 / 255, blue: 46 / 255)).frame(width: 7, height: 7)
                Circle().fill(Color(red: 40 / 255, green: 200 / 255, blue: 64 / 255)).frame(width: 7, height: 7)

                Spacer()

                Text(title)
                    .font(.console(8, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)

                Spacer()

                Color.clear.frame(width: 33, height: 1)
            }
            .padding(.horizontal, 12)
            .frame(height: 37)
            .background(ConsoleTheme.surfaceGreen)

            Rectangle().fill(ConsoleTheme.line).frame(height: 1)

            content
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [ConsoleTheme.surfaceGreen, Color.black.opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: ConsoleTheme.radius, style: .continuous)
                .stroke(ConsoleTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: ConsoleTheme.radius, style: .continuous))
        .shadow(color: Color.black.opacity(0.48), radius: 28, y: 18)
    }
}

struct ConsolePrimaryButton: View {
    let title: String
    var destructive = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .lineLimit(1)

                Spacer()

                Text(destructive ? "!" : "EXEC")
                    .font(.console(8, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(destructive ? ConsoleTheme.destructive : ConsoleTheme.accentSecondary)
            }
            .font(.console(12, weight: .black))
            .foregroundStyle(disabled ? ConsoleTheme.muted : Color.black)
            .padding(.horizontal, 17)
            .frame(height: 54)
            .background(disabled ? ConsoleTheme.surfaceRaised : ConsoleTheme.text)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(destructive ? ConsoleTheme.destructive.opacity(0.45) : Color.white.opacity(0.10), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct ConsoleCommandButton: View {
    let title: String
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(">")
                Text(title)
                Spacer()
            }
            .font(.console(10, weight: .black))
            .foregroundStyle(destructive ? ConsoleTheme.destructive : ConsoleTheme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ConsoleStatusDot: View {
    var active: Bool

    var body: some View {
        Circle()
            .fill(active ? ConsoleTheme.accent : ConsoleTheme.muted)
            .frame(width: 7, height: 7)
            .shadow(color: active ? ConsoleTheme.accent.opacity(0.40) : .clear, radius: 9)
    }
}

struct ConsoleStatusPill: View {
    let text: String
    var active = true

    var body: some View {
        Text(text)
            .font(.console(8, weight: .black))
            .tracking(0.55)
            .foregroundStyle(active ? ConsoleTheme.accent : ConsoleTheme.secondary)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(ConsoleTheme.surfaceGreen)
            .overlay {
                Capsule().stroke(active ? ConsoleTheme.lineGreen : ConsoleTheme.line, lineWidth: 1)
            }
            .clipShape(Capsule())
    }
}

struct ConsoleSectionLabel: View {
    let title: String
    var value: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.console(9, weight: .black))
                .tracking(0.9)
                .foregroundStyle(ConsoleTheme.muted)

            Spacer()

            if let value {
                Text(value)
                    .font(.console(9, weight: .black))
                    .foregroundStyle(ConsoleTheme.accent)
            }
        }
    }
}

struct ConsoleSystemLine: View {
    let text: String
    var tone: Tone = .normal

    enum Tone: Equatable {
        case normal
        case success
        case warning
        case error
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(prefix)
                .font(.console(10, weight: .black))
                .foregroundStyle(color)

            Text(text)
                .font(.console(10, weight: .bold))
                .foregroundStyle(tone == .normal ? ConsoleTheme.secondary : color)

            Spacer(minLength: 0)
        }
    }

    private var prefix: String {
        switch tone {
        case .normal: return ">"
        case .success: return "[+]"
        case .warning: return "[!]"
        case .error: return "[-]"
        }
    }

    private var color: Color {
        switch tone {
        case .normal, .success: return ConsoleTheme.accent
        case .warning: return ConsoleTheme.warning
        case .error: return ConsoleTheme.destructive
        }
    }
}

struct ConsoleField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(">")
                .font(.console(14, weight: .black))
                .foregroundStyle(ConsoleTheme.accent)

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.console(13, weight: .medium))
                .foregroundStyle(ConsoleTheme.text)
                .tint(ConsoleTheme.accent)
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 49)
        .background(Color.black.opacity(0.68))
        .overlay {
            RoundedRectangle(cornerRadius: ConsoleTheme.compactRadius, style: .continuous)
                .stroke(ConsoleTheme.lineGreen, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: ConsoleTheme.compactRadius, style: .continuous))
    }
}

struct ConsoleMetricStrip: View {
    let metrics: [(String, String, Color)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(metrics.indices, id: \.self) { index in
                let metric = metrics[index]
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.0)
                        .font(.console(8, weight: .black))
                        .foregroundStyle(ConsoleTheme.muted)

                    Text(metric.1)
                        .font(.console(11, weight: .black))
                        .foregroundStyle(metric.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                .background(ConsoleTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ConsoleTheme.line, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}
