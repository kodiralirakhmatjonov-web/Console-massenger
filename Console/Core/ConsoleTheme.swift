import SwiftUI
import UIKit

enum ConsoleTheme {
    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let background = adaptive(
        light: UIColor(red: 246/255, green: 248/255, blue: 247/255, alpha: 1),
        dark: UIColor(red: 3/255, green: 5/255, blue: 4/255, alpha: 1)
    )
    static let backgroundRaised = adaptive(
        light: UIColor(red: 1, green: 1, blue: 1, alpha: 0.96),
        dark: UIColor(red: 7/255, green: 10/255, blue: 8/255, alpha: 1)
    )
    static let surface = adaptive(
        light: UIColor(red: 1, green: 1, blue: 1, alpha: 0.92),
        dark: UIColor(red: 9/255, green: 12/255, blue: 10/255, alpha: 1)
    )
    static let surfaceRaised = adaptive(
        light: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
        dark: UIColor(red: 14/255, green: 18/255, blue: 15/255, alpha: 1)
    )
    static let surfaceGreen = adaptive(
        light: UIColor(red: 232/255, green: 248/255, blue: 238/255, alpha: 1),
        dark: UIColor(red: 7/255, green: 17/255, blue: 11/255, alpha: 1)
    )
    static let line = adaptive(
        light: UIColor.black.withAlphaComponent(0.09),
        dark: UIColor.white.withAlphaComponent(0.08)
    )
    static let lineStrong = adaptive(
        light: UIColor.black.withAlphaComponent(0.16),
        dark: UIColor.white.withAlphaComponent(0.14)
    )
    static let lineGreen = adaptive(
        light: UIColor(red: 0/255, green: 160/255, blue: 82/255, alpha: 0.22),
        dark: UIColor(red: 76/255, green: 255/255, blue: 142/255, alpha: 0.24)
    )
    static let text = adaptive(
        light: UIColor(red: 16/255, green: 22/255, blue: 18/255, alpha: 1),
        dark: UIColor(red: 244/255, green: 248/255, blue: 245/255, alpha: 1)
    )
    static let secondary = adaptive(
        light: UIColor(red: 84/255, green: 96/255, blue: 88/255, alpha: 1),
        dark: UIColor(red: 142/255, green: 154/255, blue: 146/255, alpha: 1)
    )
    static let muted = adaptive(
        light: UIColor(red: 122/255, green: 132/255, blue: 126/255, alpha: 1),
        dark: UIColor(red: 83/255, green: 96/255, blue: 87/255, alpha: 1)
    )
    static let accent = adaptive(
        light: UIColor(red: 0/255, green: 161/255, blue: 81/255, alpha: 1),
        dark: UIColor(red: 73/255, green: 255/255, blue: 137/255, alpha: 1)
    )
    static let accentSecondary = adaptive(
        light: UIColor(red: 0/255, green: 125/255, blue: 63/255, alpha: 1),
        dark: UIColor(red: 29/255, green: 201/255, blue: 100/255, alpha: 1)
    )
    static let warning = adaptive(
        light: UIColor(red: 193/255, green: 124/255, blue: 0/255, alpha: 1),
        dark: UIColor(red: 1.0, green: 199/255, blue: 68/255, alpha: 1)
    )
    static let destructive = adaptive(
        light: UIColor(red: 205/255, green: 43/255, blue: 52/255, alpha: 1),
        dark: UIColor(red: 1.0, green: 82/255, blue: 82/255, alpha: 1)
    )
    static let cyan = adaptive(
        light: UIColor(red: 0/255, green: 129/255, blue: 176/255, alpha: 1),
        dark: UIColor(red: 75/255, green: 218/255, blue: 255/255, alpha: 1)
    )
    static let grid = adaptive(
        light: UIColor.black.withAlphaComponent(0.026),
        dark: UIColor.white.withAlphaComponent(0.018)
    )
    static let fieldBackground = adaptive(
        light: UIColor(red: 239/255, green: 244/255, blue: 241/255, alpha: 0.92),
        dark: UIColor.black.withAlphaComponent(0.48)
    )
    static let shadow = adaptive(
        light: UIColor.black.withAlphaComponent(0.10),
        dark: UIColor.black.withAlphaComponent(0.34)
    )

    static let radius: CGFloat = 20
    static let smallRadius: CGFloat = 14
    static let compactRadius: CGFloat = 11
    static let pageMaxWidth: CGFloat = 1180
    static let readingMaxWidth: CGFloat = 860
}

enum ConsoleAppearance: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Система"
        case .dark: return "Тёмная"
        case .light: return "Светлая"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
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
