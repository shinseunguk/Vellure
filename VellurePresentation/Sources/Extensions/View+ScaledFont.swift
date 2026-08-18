import SwiftUI

/// 디자인에서 정한 고정 크기를 유지하면서 Dynamic Type에 따라 함께 커지는 폰트.
///
/// `Font.system(size:)`는 사용자가 글자 크기를 키워도 반응하지 않는다.
/// 시맨틱 폰트(`.body` 등)로 전면 교체하면 대응은 되지만 기존 레이아웃이 모두 바뀐다.
/// 여기서는 `@ScaledMetric`으로 크기만 비례 확대해, 기본 글자 크기에서는
/// 기존과 동일하게 보이면서 확대 설정을 따라가도록 한다.
private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

extension View {
    /// Dynamic Type에 맞춰 크기가 함께 커지는 시스템 폰트를 적용한다.
    /// - Parameters:
    ///   - size: 기본 글자 크기에서의 포인트 값
    ///   - weight: 폰트 굵기
    func scaledFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(ScaledFont(size: size, weight: weight, relativeTo: .textStyle(forSize: size)))
    }
}

private extension Font.TextStyle {
    /// 확대 비율의 기준이 될 텍스트 스타일을 크기에서 고른다.
    /// 큰 글자는 완만하게, 작은 글자는 가파르게 커지는 iOS 기본 곡선을 따라간다.
    static func textStyle(forSize size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<11: .caption2
        case ..<12.5: .caption
        case ..<14.5: .footnote
        case ..<15.5: .subheadline
        case ..<17.5: .callout
        case ..<21: .title3
        case ..<26: .title2
        case ..<31: .title
        default: .largeTitle
        }
    }
}
