import Foundation
import SwiftUI

/// 잠금화면 Live Activity의 글자 크기 배율.
///
/// 앱 화면은 Dynamic Type을 따르지만 Live Activity는 고정 크기로 그려
/// 시스템 설정이 닿지 않는다. 그래서 따로 고르게 한다.
///
/// 단계(작게·보통·크게)로 두면 사람마다 맞는 지점이 그 사이에 있을 때
/// 고를 방법이 없다. 연속값으로 두고 슬라이더로 조절한다.
public enum TextScale {
    /// 값 타입이 바뀌면 키도 바꾼다.
    /// 같은 키에 다른 타입이 남아 있으면 `@AppStorage`가 0을 읽어 슬라이더가 맨 끝으로 간다.
    public static let storageKey = "liveActivityTextScaleValue"

    /// 조절 범위.
    /// 아래로는 읽을 수 있는 선, 위로는 잠금화면 카드 높이에 내용이 들어가는 선이다.
    public static let range: ClosedRange<CGFloat> = 0.85...1.30
    public static let `default`: CGFloat = 1.0

    /// 앱과 확장이 함께 읽는 저장소.
    /// 확장은 앱의 UserDefaults를 볼 수 없어 App Group을 거쳐야 한다.
    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: Constants.appGroupId) ?? .standard
    }

    public static var current: CGFloat {
        let stored = sharedDefaults.double(forKey: storageKey)
        guard stored > 0 else { return `default` }
        return clamped(CGFloat(stored))
    }

    public static func save(_ scale: CGFloat) {
        sharedDefaults.set(Double(clamped(scale)), forKey: storageKey)
    }

    public static func clamped(_ scale: CGFloat) -> CGFloat {
        min(max(scale, range.lowerBound), range.upperBound)
    }

    /// 슬라이더 옆에 보여줄 표기. 100%를 기준으로 읽는다.
    public static func percentLabel(_ scale: CGFloat) -> String {
        "\(Int((scale * 100).rounded()))%"
    }
}
