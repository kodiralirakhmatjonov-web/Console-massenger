import SwiftUI

enum ConsoleTheme {
    static let background = Color.black
    static let surface = Color(red: 0.035, green: 0.039, blue: 0.038)
    static let surfaceRaised = Color(red: 0.055, green: 0.061, blue: 0.059)
    static let line = Color.white.opacity(0.085)
    static let text = Color(red: 0.965, green: 0.965, blue: 0.975)
    static let secondary = Color.white.opacity(0.60)
    static let muted = Color.white.opacity(0.36)
    static let accent = Color(red: 0.0, green: 1.0, blue: 0.62)
    static let warning = Color(red: 1.0, green: 0.79, blue: 0.15)
    static let destructive = Color(red: 1.0, green: 0.31, blue: 0.30)

    static let radius: CGFloat = 18
    static let smallRadius: CGFloat = 12
}

extension Font {
    static func console(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
