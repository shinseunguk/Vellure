import SwiftUI
import VellureCore

/// 잠금화면 글자 크기 조절.
///
/// 슬라이더만 두면 결과를 짐작해야 한다. 바로 위에 실제 카드를 같은 배율로 그려
/// 움직이는 대로 보이게 한다.
struct TextScaleRow: View {
    @Binding var scale: Double

    private static let previewState = MemoAttributes.ContentState(
        renderType: "plain",
        content: String(localized: "settings.textScale.sample"),
        font: "default",
        colorTag: "green",
        updatedAt: .now,
        expiresAt: Calendar.current.date(byAdding: .hour, value: 6, to: .now)
    )

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("settings.textScale")
                    .scaledFont(14)
                    .foregroundStyle(Theme.textPrimary)
                Text("settings.textScale.hint")
                    .scaledFont(12)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.top, 15)

            preview
                .padding(.horizontal, 15)
                .padding(.top, 12)

            slider
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.divider, lineWidth: 1)
        )
    }

    private var preview: some View {
        LiveActivityCard(state: Self.previewState, scale: CGFloat(scale))
            .background(Theme.memoSurface(for: "green"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityHidden(true)
    }

    private var slider: some View {
        HStack(spacing: 10) {
            Text(verbatim: "가")
                .scaledFont(12)
                .foregroundStyle(Theme.textSecondary)

            Slider(
                value: $scale,
                in: Double(TextScale.range.lowerBound)...Double(TextScale.range.upperBound)
            )
            .tint(Theme.accent)
            .accessibilityLabel("settings.textScale")
            .accessibilityValue(TextScale.percentLabel(CGFloat(scale)))

            Text(verbatim: "가")
                .scaledFont(19)
                .foregroundStyle(Theme.textSecondary)

            Text(TextScale.percentLabel(CGFloat(scale)))
                .scaledFont(12, weight: .semibold)
                .foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)
        }
    }
}
