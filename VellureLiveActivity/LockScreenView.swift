import AppIntents
import SwiftUI
import WidgetKit
import VellureCore

/// 잠금화면 Live Activity 표현.
///
/// 카드 자체는 `VellureCore`의 `LiveActivityCard`에 있다.
/// 여기서는 ActivityKit 컨텍스트를 값으로 풀고, 조작이 필요한 행에
/// 인텐트 버튼을 감싸는 일만 한다.
struct LockScreenView: View {
    let context: ActivityViewContext<MemoAttributes>

    var body: some View {
        LiveActivityCard(
            state: context.state,
            isStale: context.isStale,
            scale: TextScale.current,
            wrapRow: { content, action in
                AnyView(interactiveRow(content, action: action))
            }
        )
        // 뷰 안에서만 배경을 칠하면 시스템 카드가 내용보다 클 때 가장자리가 비어
        // 카드가 잘린 것처럼 보인다. 컨테이너 전체를 시스템이 칠하게 맡긴다.
        //
        // 적응형 색이었다면 시스템 외형 기준으로 해석돼 글자색과 어긋났겠지만,
        // memoSurface는 모드와 무관한 고정색이라 그 문제가 없다.
        .activityBackgroundTint(Theme.memoSurface(for: context.state.colorTag))
        .activitySystemActionForegroundColor(LiveActivityCard.label)
    }

    /// 잠금화면에서는 닫힌 앱을 깨우지 않고 조작해야 하므로 인텐트 버튼만 동작한다.
    @ViewBuilder
    private func interactiveRow(_ content: AnyView, action: LiveActivityCard.RowAction) -> some View {
        switch action {
        case .toggleItem(let id):
            Button(intent: ToggleItemIntent(memoId: context.attributes.memoId, itemId: id)) {
                content
            }
            .buttonStyle(.plain)
        case .stepProgress(let up):
            Button(intent: StepProgressIntent(
                memoId: context.attributes.memoId,
                direction: up ? "up" : "down"
            )) {
                content
            }
            .buttonStyle(.plain)
        }
    }
}
