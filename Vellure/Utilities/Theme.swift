import SwiftUI

enum Theme {
    static let accent = Color(hex: "1fa97c")
    static let accentHover = Color(hex: "23b98a")
    static let background = Color(hex: "eef0f4")
    static let cardBackground = Color(.systemBackground)
    static let textPrimary = Color(hex: "1b241e")
    static let textSecondary = Color(hex: "8b95a1")
    static let divider = Color(hex: "e3e7ec")
    static let chipBackground = Color(hex: "f2f4f6")

    static let memoColors: [String: Color] = [
        "green": Color(hex: "1fa97c"),
        "blue": Color(hex: "3b82f6"),
        "purple": Color(hex: "8b5cf6"),
        "orange": Color(hex: "f59e0b"),
        "red": Color(hex: "ef4444"),
        "pink": Color(hex: "ec4899"),
        "teal": Color(hex: "14b8a6"),
    ]

    static func memoColor(for tag: String) -> Color {
        memoColors[tag] ?? accent
    }
}

extension Color {
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
}
