import SwiftUI
import VellureCore

/// 작성 중인 메모가 잠금화면에 어떻게 보이는지 미리 보여준다.
///
/// 지금까지는 저장하고 올려봐야 결과를 알 수 있었다.
/// 색·타입·글자가 실제로 어떻게 읽히는지 보고 고를 수 있어야 한다.
struct LiveActivityPreview: View {
    let state: MemoAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("edit.section.preview")
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(Theme.textSecondary)

            LiveActivityCard(state: state, scale: TextScale.current)
                .background(Theme.memoSurface(for: state.colorTag))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                // 실제 조작은 잠금화면에서만 동작한다. 여기서는 보여주기만 한다.
                .allowsHitTesting(false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("edit.section.preview")
        }
    }
}
