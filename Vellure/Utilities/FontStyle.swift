import SwiftUI

enum FontStyle: String, CaseIterable, Identifiable {
    case system = "default"
    case rounded = "rounded"
    case serif = "serif"
    case mono = "mono"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "기본"
        case .rounded: "라운드"
        case .serif: "세리프"
        case .mono: "모노"
        }
    }

    var preview: String { "가나다 ABC 123" }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
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

    static func from(_ rawValue: String) -> FontStyle {
        FontStyle(rawValue: rawValue) ?? .system
    }
}
