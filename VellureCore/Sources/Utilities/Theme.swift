import SwiftUI
import UIKit

public enum Theme {
    public static let accent = Color(hex: "1fa97c")
    public static let accentHover = Color(hex: "23b98a")

    public static let background = Color(
        light: UIColor(hex: "eef0f4"),
        dark: UIColor(hex: "1c1c1e")
    )

    public static let cardBackground = Color(
        light: .white,
        dark: UIColor(hex: "2c2c2e")
    )

    public static let textPrimary = Color(
        light: UIColor(hex: "1b241e"),
        dark: .white
    )

    public static let textSecondary = Color(
        light: UIColor(hex: "8b95a1"),
        dark: UIColor(hex: "98989f")
    )

    public static let divider = Color(
        light: UIColor(hex: "e3e7ec"),
        dark: UIColor(hex: "38383a")
    )

    public static let chipBackground = Color(
        light: UIColor(hex: "f2f4f6"),
        dark: UIColor(hex: "3a3a3c")
    )

    public static let memoColors: [String: Color] = [
        "green": Color(hex: "1fa97c"),
        "blue": Color(hex: "3b82f6"),
        "purple": Color(hex: "8b5cf6"),
        "orange": Color(hex: "f59e0b"),
        "red": Color(hex: "ef4444"),
        "pink": Color(hex: "ec4899"),
        "teal": Color(hex: "14b8a6"),
    ]

    public static func memoColor(for tag: String) -> Color {
        memoColors[tag] ?? accent
    }
}

// MARK: - Color Helpers

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            (r, g, b) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255
            )
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: r, green: g, blue: b)
    }

    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

public extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: CGFloat
        switch hex.count {
        case 6:
            (r, g, b) = (
                CGFloat((int >> 16) & 0xFF) / 255,
                CGFloat((int >> 8) & 0xFF) / 255,
                CGFloat(int & 0xFF) / 255
            )
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
