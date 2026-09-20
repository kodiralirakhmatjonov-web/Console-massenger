import SwiftUI

enum ConsoleTheme {
    static let background = Color.black
    static let surface = Color(red: 8 / 255, green: 8 / 255, blue: 8 / 255)
    static let surfaceRaised = Color(red: 12 / 255, green: 14 / 255, blue: 13 / 255)
    static let surfaceGreen = Color(red: 4 / 255, green: 8 / 255, blue: 5 / 255)
    static let line = Color(red: 21 / 255, green: 21 / 255, blue: 21 / 255)
    static let lineGreen = Color(red: 30 / 255, green: 53 / 255, blue: 34 / 255)
    static let text = Color(red: 245 / 255, green: 245 / 255, blue: 247 / 255)
    static let secondary = Color(red: 124 / 255, green: 135 / 255, blue: 127 / 255)
    static let muted = Color(red: 86 / 255, green: 97 / 255, blue: 88 / 255)
    static let accent = Color(red: 124 / 255, green: 255 / 255, blue: 141 / 255)
    static let accentSecondary = Color(red: 51 / 255, green: 209 / 255, blue: 122 / 255)
    static let warning = Color(red: 1.0, green: 214 / 255, blue: 10 / 255)
    static let destructive = Color(red: 1.0, green: 95 / 255, blue: 87 / 255)

    static let radius: CGFloat = 18
    static let smallRadius: CGFloat = 12
    static let compactRadius: CGFloat = 9
}

extension Font {
    static func console(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func consoleDisplay(_ size: CGFloat, weight: Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
