import SwiftUI

enum ConsoleTheme {
    static let background = Color(red: 3 / 255, green: 5 / 255, blue: 4 / 255)
    static let backgroundRaised = Color(red: 7 / 255, green: 10 / 255, blue: 8 / 255)
    static let surface = Color(red: 9 / 255, green: 12 / 255, blue: 10 / 255)
    static let surfaceRaised = Color(red: 14 / 255, green: 18 / 255, blue: 15 / 255)
    static let surfaceGreen = Color(red: 7 / 255, green: 17 / 255, blue: 11 / 255)
    static let line = Color.white.opacity(0.08)
    static let lineStrong = Color.white.opacity(0.14)
    static let lineGreen = Color(red: 76 / 255, green: 255 / 255, blue: 142 / 255).opacity(0.24)
    static let text = Color(red: 244 / 255, green: 248 / 255, blue: 245 / 255)
    static let secondary = Color(red: 142 / 255, green: 154 / 255, blue: 146 / 255)
    static let muted = Color(red: 83 / 255, green: 96 / 255, blue: 87 / 255)
    static let accent = Color(red: 73 / 255, green: 255 / 255, blue: 137 / 255)
    static let accentSecondary = Color(red: 29 / 255, green: 201 / 255, blue: 100 / 255)
    static let warning = Color(red: 1.0, green: 199 / 255, blue: 68 / 255)
    static let destructive = Color(red: 1.0, green: 82 / 255, blue: 82 / 255)
    static let cyan = Color(red: 75 / 255, green: 218 / 255, blue: 255 / 255)

    static let radius: CGFloat = 20
    static let smallRadius: CGFloat = 14
    static let compactRadius: CGFloat = 11
    static let pageMaxWidth: CGFloat = 1180
    static let readingMaxWidth: CGFloat = 860
}

extension Font {
    static func console(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func consoleDisplay(_ size: CGFloat, weight: Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension View {
    func consolePageFrame(maxWidth: CGFloat = ConsoleTheme.pageMaxWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
