import SwiftUI

public extension View {

    /// D-day·카운트다운 강조 숫자에 공통으로 적용하는 스타일.
    ///
    /// 색은 메모마다 다르므로 여기서 정하지 않는다. 호출부에서 `foregroundStyle`로 지정한다.
    /// - Parameter size: 글자 크기. 표면이 좁으면 줄여서 넘긴다.
    func memoHighlightStyle(size: CGFloat = Theme.Metric.highlightFontSize) -> some View {
        font(.system(size: size, weight: .heavy))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
