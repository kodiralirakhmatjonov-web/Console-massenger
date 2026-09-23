import SwiftUI

struct ConsoleBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ConsoleTheme.background

                RadialGradient(
                    colors: [
                        ConsoleTheme.accent.opacity(0.12),
                        ConsoleTheme.accent.opacity(0.025),
                        .clear
                    ],
                    center: UnitPoint(x: 0.16, y: -0.04),
                    startRadius: 0,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                )

                RadialGradient(
                    colors: [ConsoleTheme.cyan.opacity(0.045), .clear],
                    center: UnitPoint(x: 0.98, y: 0.86),
                    startRadius: 0,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.56
                )

                Canvas { context, size in
                    let step: CGFloat = 32
                    var path = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += step
                    }
                    context.stroke(path, with: .color(.white.opacity(0.018)), lineWidth: 0.5)
                }

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.34)],
                    startPoint: .top,
                    endPoint: .bottom
                )
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 9) {
                ConsoleStatusDot(active: true)

                Text("CONSOLE // HUMAN PROTOCOL")
                    .font(.console(9, weight: .black))
                    .tracking(1.15)
                    .foregroundStyle(ConsoleTheme.text.opacity(0.78))

                Spacer(minLength: 8)

                if let trailing {
                    ConsoleStatusPill(text: trailing, active: trailing != "OFFLINE")
                }
            }

            HStack(alignment: .bottom, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(path.uppercased())
                        .font(.console(9, weight: .black))
                        .tracking(1.1)
                        .foregroundStyle(ConsoleTheme.accent)

                    Text(title)
                        .font(.consoleDisplay(32, weight: .heavy))
                        .tracking(-1.1)
                        .foregroundStyle(ConsoleTheme.text)
                }

                Spacer(minLength: 0)

                Text("_\u{2588}")
                    .font(.console(13, weight: .bold))
                    .foregroundStyle(ConsoleTheme.accent.opacity(0.78))
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
            .padding(17)
            .background(
                LinearGradient(
                    colors: [ConsoleTheme.surfaceRaised.opacity(0.95), ConsoleTheme.surface.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: ConsoleTheme.radius, style: .continuous)
                    .stroke(ConsoleTheme.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: ConsoleTheme.radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.30), radius: 24, y: 12)
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
            HStack(spacing: 7) {
                Circle().fill(ConsoleTheme.destructive.opacity(0.86)).frame(width: 7, height: 7)
                Circle().fill(ConsoleTheme.warning.opacity(0.86)).frame(width: 7, height: 7)
                Circle().fill(ConsoleTheme.accent.opacity(0.86)).frame(width: 7, height: 7)

                Spacer()

                Text(title)
                    .font(.console(8, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(ConsoleTheme.secondary)

                Spacer()

                Text("::")
                    .font(.console(8, weight: .bold))
                    .foregroundStyle(ConsoleTheme.muted)
                    .frame(width: 28)
            }
            .padding(.horizontal, 13)
            .frame(height: 39)
            .background(ConsoleTheme.surfaceGreen.opacity(0.88))

            Rectangle().fill(ConsoleTheme.line).frame(height: 1)

            content
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [ConsoleTheme.surfaceGreen.opacity(0.96), ConsoleTheme.surface.opacity(0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: ConsoleTheme.radius, style: .continuous)
                .stroke(ConsoleTheme.lineGreen.opacity(0.70), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: ConsoleTheme.radius, style: .continuous))
        .shadow(color: Color.black.opacity(0.44), radius: 30, y: 16)
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
            }
            .font(.console(11, weight: .black))
            .foregroundStyle(disabled ? ConsoleTheme.muted : Color.black)
            .padding(.horizontal, 17)
            .frame(height: 54)
            .background(
                disabled
                ? ConsoleTheme.surfaceRaised
                : (destructive ? ConsoleTheme.destructive : ConsoleTheme.accent)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(disabled ? 0.04 : 0.13), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(
                color: disabled ? .clear : (destructive ? ConsoleTheme.destructive : ConsoleTheme.accent).opacity(0.16),
                radius: 18,
                y: 8
            )
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
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .font(.console(10, weight: .black))
            .foregroundStyle(destructive ? ConsoleTheme.destructive : ConsoleTheme.accent)
            .padding(.vertical, 3)
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
            .shadow(color: active ? ConsoleTheme.accent.opacity(0.55) : .clear, radius: 10)
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
            .padding(.horizontal, 10)
            .frame(height: 27)
            .background(ConsoleTheme.surfaceGreen.opacity(0.92))
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
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
        .background(Color.black.opacity(0.48))
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
                VStack(alignment: .leading, spacing: 5) {
                    Text(metric.0)
                        .font(.console(8, weight: .black))
                        .foregroundStyle(ConsoleTheme.muted)

                    Text(metric.1)
                        .font(.console(11, weight: .black))
                        .foregroundStyle(metric.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .padding(.horizontal, 11)
                .frame(maxWidth: .infinity, minHeight: 57, alignment: .leading)
                .background(ConsoleTheme.surface.opacity(0.86))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(ConsoleTheme.line, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
    }
}

struct ConsoleNodeGlyph: View {
    var active = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(ConsoleTheme.accent.opacity(active ? 0.08 : 0.035))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(active ? ConsoleTheme.lineGreen : ConsoleTheme.line, lineWidth: 1)
                }

            Image(systemName: "terminal.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(active ? ConsoleTheme.accent : ConsoleTheme.secondary)
        }
        .frame(width: 46, height: 46)
    }
}
