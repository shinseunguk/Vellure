import SwiftUI

public enum FontStyle: String, CaseIterable, Identifiable {
    case system = "default"
    case rounded = "rounded"
    case serif = "serif"
    case mono = "mono"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: String(localized: "font.system")
        case .rounded: String(localized: "font.rounded")
        case .serif: String(localized: "font.serif")
        case .mono: String(localized: "font.mono")
        }
    }

    public var preview: String { String(localized: "font.preview") }

    public func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .system:
            .system(size: size, weight: weight)
        case .rounded:
            .system(size: size, weight: weight, design: .rounded)
        case .serif:
            .system(size: size, weight: weight, design: .serif)
        case .mono:
            .system(size: size, weight: weight, design: .monospaced)
        }
    }

    public static func from(_ rawValue: String) -> FontStyle {
        FontStyle(rawValue: rawValue) ?? .system
    }
}
