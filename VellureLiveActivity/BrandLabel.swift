import SwiftUI

/// Live Activity가 Vellure에서 발행됐음을 알리는 얇은 브랜드 표시.
/// 앱 아이콘 + 워드마크 + 메모 종류를 한 줄 높이로 담는다.
struct BrandLabel: View {
    /// 아이콘 한 변 길이. 워드마크 높이에 맞춘다.
    private var iconSize: CGFloat { fontSize + 2 }
    /// 아이콘 모서리 곡률
    private var iconCornerRadius: CGFloat { iconSize * 0.27 }

    let tint: Color
    /// `MemoAttributes.ContentState.renderType` 원시값. nil이면 워드마크만 표시한다.
    var renderType: String?
    var fontSize: CGFloat = 11

    var body: some View {
        HStack(spacing: 5) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: iconSize, height: iconSize)
                .clipShape(
                    RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                )

            Text(verbatim: brandText)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                // 다이나믹 아일랜드 상단 영역은 카메라 컷아웃에 폭이 눌린다.
                // 잘리는 대신 살짝 줄어들도록 둔다.
                .minimumScaleFactor(0.85)
        }
    }

    private var brandText: String {
        guard let label = renderType.flatMap(Self.typeLabel) else { return "Vellure" }
        return "Vellure · \(label)"
    }

    /// 렌더 타입을 사용자에게 보여줄 이름으로 옮긴다.
    static func typeLabel(_ renderType: String) -> String? {
        switch renderType {
        case "plain": "메모"
        case "checklist": "체크리스트"
        case "dday": "D-day"
        case "countdown": "카운트다운"
        case "progress": "진행바"
        default: nil
        }
    }
}
