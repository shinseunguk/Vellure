import SwiftUI
import VellureCore

/// 작성 중인 메모가 잠금화면에 어떻게 보이는지 미리 보여준다.
///
/// 지금까지는 저장하고 올려봐야 결과를 알 수 있었다.
/// 색·타입·글자가 실제로 어떻게 읽히는지 보고 고를 수 있어야 한다.
struct LiveActivityPreview: View {
    let state: MemoAttributes.ContentState

    /// 글자 크기는 잠금화면 전체에 적용되는 설정이다.
    /// 결과를 보면서 맞추는 자리가 여기라 설정 화면과 같은 값을 여기서도 조절한다.
    @AppStorage(TextScale.storageKey, store: TextScale.sharedDefaults)
    private var textScale: Double = Double(TextScale.default)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("edit.section.preview")
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(Theme.textSecondary)

            LiveActivityCard(state: state, scale: CGFloat(textScale))
                .background(Theme.memoSurface(for: state.colorTag))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                // 실제 조작은 잠금화면에서만 동작한다. 여기서는 보여주기만 한다.
                .allowsHitTesting(false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("edit.section.preview")

            scaleSlider
        }
    }

    private var scaleSlider: some View {
        HStack(spacing: 10) {
            Text(verbatim: "가")
                .scaledFont(12)
                .foregroundStyle(Theme.textSecondary)

            Slider(
                value: $textScale,
                in: Double(TextScale.range.lowerBound)...Double(TextScale.range.upperBound)
            )
            .tint(Theme.accent)
            .accessibilityLabel("settings.textScale")
            .accessibilityValue(TextScale.percentLabel(CGFloat(textScale)))

            Text(verbatim: "가")
                .scaledFont(19)
                .foregroundStyle(Theme.textSecondary)

            Text(TextScale.percentLabel(CGFloat(textScale)))
                .scaledFont(12, weight: .semibold)
                .foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)
        }
        .onChange(of: textScale) { _, newValue in
            // 확장은 App Group을 통해서만 설정을 볼 수 있다.
            TextScale.save(CGFloat(newValue))
        }
    }
}
