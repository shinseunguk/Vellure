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

    /// 메모 컬러 태그의 단일 정의.
    /// 앱·Live Activity·위젯이 모두 이 표를 통해 색을 얻는다.
    public static let memoColors: [String: Color] = [
        "green": accent,
        "gold": Color(hex: "ef9645"),
        "blue": Color(hex: "4b96f3"),
        "rose": Color(hex: "ee7ba2")
    ]

    public static func memoColor(for tag: String) -> Color {
        memoColors[tag] ?? accent
    }
}

// MARK: - Metric

public extension Theme {
    /// 메모를 그리는 표면(Live Activity·위젯·앱 카드)이 공유하는 치수.
    /// 표면마다 따로 두면 한쪽만 바뀌어 같은 메모가 다르게 보인다.
    enum Metric {
        /// 본문 글자 크기
        public static let contentFontSize: CGFloat = 15
        /// D-day·카운트다운 강조 숫자 크기
        public static let highlightFontSize: CGFloat = 24
        /// 본문과 타입별 콘텐츠 사이 여백
        public static let contentSpacing: CGFloat = 8
    }
}

// MARK: - Color Helpers

public extension Color {
    /// 색을 어둡게 만든다.
    func darkened(by amount: Double) -> Color {
        let ui = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard ui.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return self }

        let factor = 1 - amount
        return Color(
            red: Double(red) * factor,
            green: Double(green) * factor,
            blue: Double(blue) * factor,
            opacity: Double(alpha)
        )
    }

    /// 흰 글자를 읽을 수 있을 만큼만 어둡게 만든다.
    ///
    /// 메모 색 원본 위의 흰 글자는 대비가 2.3~3.0:1로 본문 기준(4.5:1)에 못 미친다.
    /// 일괄로 같은 양을 깎으면 어두운 색은 필요 이상으로 탁해지므로,
    /// 색마다 기준을 넘기는 최소한만 깎는다.
    func darkenedForWhiteText(minimumContrast: Double = 4.5) -> Color {
        let ui = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard ui.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return self }

        var amount = 0.0
        while amount < 0.7 {
            let factor = 1 - amount
            let contrast = Self.whiteContrast(
                red: Double(red) * factor,
                green: Double(green) * factor,
                blue: Double(blue) * factor
            )
            if contrast >= minimumContrast { break }
            amount += 0.01
        }
        return darkened(by: amount)
    }

    /// 흰색과의 명암비. WCAG 상대 휘도 공식을 따른다.
    private static func whiteContrast(red: Double, green: Double, blue: Double) -> Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
        return 1.05 / (luminance + 0.05)
    }
}

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
