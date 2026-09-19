import SwiftUI

struct ConsoleHeader: View {
    let path: String
    let title: String
    var trailing: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(path)
                    .font(.console(11, weight: .bold))
                    .foregroundStyle(ConsoleTheme.accent)

                Spacer()

                if let trailing {
                    Text(trailing)
                        .font(.console(10, weight: .bold))
                        .foregroundStyle(ConsoleTheme.muted)
                }
            }

            Text(title)
                .font(.console(31, weight: .black))
                .tracking(-1.2)
                .foregroundStyle(ConsoleTheme.text)
        }
    }
}

struct ConsoleCard<Content: View>: View {
    @ViewBuilder let content: Content

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

struct ConsolePrimaryButton: View {
    let title: String
    var destructive = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text("↵")
            }
            .font(.console(13, weight: .bold))
            .foregroundStyle(destructive ? Color.white : Color.black)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(
                disabled
                ? ConsoleTheme.muted.opacity(0.30)
                : destructive ? ConsoleTheme.destructive : ConsoleTheme.accent
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct ConsoleStatusDot: View {
    var active: Bool

    var body: some View {
        Circle()
            .fill(active ? ConsoleTheme.accent : ConsoleTheme.muted)
            .frame(width: 7, height: 7)
            .shadow(color: active ? ConsoleTheme.accent.opacity(0.45) : .clear, radius: 7)
    }
}

struct ConsoleField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(">")
                .font(.console(15, weight: .bold))
                .foregroundStyle(ConsoleTheme.accent)

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.console(14))
                .foregroundStyle(ConsoleTheme.text)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
        .background(ConsoleTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(ConsoleTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
