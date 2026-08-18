import SwiftUI

/// Live Activity가 Vellure에서 발행됐음을 알리는 얇은 브랜드 표시.
/// 아이콘 대신 테마색 점 + 워드마크만 써서 한 줄 높이로 유지한다.
struct BrandLabel: View {
    /// 점 지름
    private static let dotSize: CGFloat = 5

    let tint: Color
    var fontSize: CGFloat = 11

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: Self.dotSize, height: Self.dotSize)
            Text(verbatim: "Vellure")
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .fixedSize()
        }
    }
}
