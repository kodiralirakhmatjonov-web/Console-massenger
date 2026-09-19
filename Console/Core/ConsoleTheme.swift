import SwiftUI

enum ConsoleTheme {
    static let background = Color.black
    static let surface = Color(red: 0.035, green: 0.039, blue: 0.038)
    static let surfaceRaised = Color(red: 0.055, green: 0.061, blue: 0.059)
    static let line = Color.white.opacity(0.09)
    static let text = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let muted = Color.white.opacity(0.45)
    static let accent = Color(red: 0.0, green: 1.0, blue: 0.62)

    static let mono = Font.system(.body, design: .monospaced)
    static let monoSmall = Font.system(size: 12, weight: .semibold, design: .monospaced)
}
