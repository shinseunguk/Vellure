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

    /// 칩 위에 얹는 테두리.
    ///
    /// divider는 배경·카드 위에 긋는 선이라 칩 위에서는 칩 색과 거의 같아 보이지 않는다.
    /// (다크 모드에서 3a3a3c 위의 38383a = 1.03:1)
    /// 칩을 기준으로 한 단계 떨어뜨려, 고르지 않은 칩도 경계가 읽히게 한다.
    public static let chipBorder = Color(
        light: UIColor(hex: "c9d0d9"),
        dark: UIColor(hex: "626266")
    )

    /// 메모 컬러 태그의 단일 정의.
    /// 앱·Live Activity·위젯이 모두 이 표를 통해 색을 얻는다.
    public static let memoColors: [String: Color] = [
        "green": accent,
        "teal": Color(hex: "2ec5c0"),
        "blue": Color(hex: "4b96f3"),
        "purple": Color(hex: "a97bf0"),
        "rose": Color(hex: "ee7ba2"),
        "red": Color(hex: "f26a5f"),
        "gold": Color(hex: "ef9645"),
        "slate": Color(hex: "7f8c9e")
    ]

    /// 색 선택 순서. 색상환을 따라 늘어놓아 고를 때 옆 색과 헷갈리지 않는다.
    public static let memoColorOrder = ["green", "teal", "blue", "purple", "rose", "red", "gold", "slate"]

    public static func memoColor(for tag: String) -> Color {
        memoColors[tag] ?? accent
    }

    /// 흰 글자를 얹는 카드 배경에 쓰는 메모 색.
    ///
    /// `memoColors`는 글자·강조용이라 밝다. 그대로 배경에 쓰면 흰 글자가
    /// 2.3~3.0:1로 읽히지 않는다. 같은 색을 채도는 지키고 밝기만 낮춰
    /// 흰 글자 기준(4.5:1)을 넘긴 값이다.
    ///
    /// 모드에 따라 바꾸지 않는다. 잠금화면 카드가 라이트·다크에서 다른 색이면
    /// 같은 메모가 다른 메모처럼 보인다.
    public static let memoSurfaces: [String: Color] = [
        "green": Color(hex: "05885d"),
        "teal": Color(hex: "1e8380"),
        "blue": Color(hex: "2876d7"),
        "purple": Color(hex: "8963c3"),
        "rose": Color(hex: "be5277"),
        "red": Color(hex: "c2544c"),
        "gold": Color(hex: "b1631c"),
        "slate": Color(hex: "6c7787")
    ]

    public static func memoSurface(for tag: String) -> Color {
        memoSurfaces[tag] ?? memoSurfaces["green"] ?? accent
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
