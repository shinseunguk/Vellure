import ActivityKit
import WidgetKit
import SwiftUI
import VellureCore

struct VellureLiveActivityWidget: Widget {
    /// 확장 상태 콘텐츠의 좌우 여백.
    /// 상단 좌우 영역이 아일랜드 코너 곡선 마스크에 잘리는 것을 막고,
    /// 하단 영역에도 동일하게 적용해 앱 로고와 본문의 시작 위치를 맞춘다.
    private static let expandedContentInset: CGFloat = 10
    /// 본문과 위아래 요소 사이에 추가로 두는 여백
    private static let contentVerticalPadding: CGFloat = 2

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded (롱탭)
                // 헤더(타입·타이머)는 상단 좌우 영역이 맡고, 하단은 콘텐츠 전용으로 둔다.
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 5) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        Text(typeLabel(context))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tint(context))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.leading, Self.expandedContentInset)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    clearTimerLabel(context)
                        .padding(.trailing, Self.expandedContentInset)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        if !context.state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(context.state.content)
                                .font(.headline.weight(.semibold))
                                .fontDesign(fontDesign(from: context.state.font))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .padding(.vertical, Self.contentVerticalPadding)
                        }

                        expandedDynamicContent(context)
                    }
                    .padding(.horizontal, Self.expandedContentInset)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                Circle()
                    .fill(tint(context))
                    .frame(width: 11, height: 11)
            } compactTrailing: {
                // MARK: - Compact Trailing
                compactTrailingContent(context)
                    .padding(.trailing, Self.compactTrailingInset)
            } minimal: {
                // MARK: - Minimal
                Circle()
                    .fill(tint(context))
                    .frame(width: 11, height: 11)
            }
        }
    }

    // MARK: - Expanded Dynamic Content

    @ViewBuilder
    private func expandedDynamicContent(_ context: ActivityViewContext<MemoAttributes>) -> some View {
        let state = context.state
        switch state.renderType {
        case "dday":
            if let target = state.targetDate {
                Text(ddayString(target))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(tint(context))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        case "countdown":
            if let target = state.targetDate {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(tint(context))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        case "progress":
            if let progress = state.progress {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: progress)
                        .tint(tint(context))
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(tint(context))
                        .monospacedDigit()
                }
            }
        case "checklist":
            if let items = state.items {
                ExpandedChecklistView(items: items, memoId: context.attributes.memoId, tint: tint(context))
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Auto-clear Timer (header trailing)

    /// 소멸 카운트다운 타이머의 고정 폭 (자릿수가 바뀌어도 위치가 흔들리지 않도록).
    /// `HH:MM:SS` 8자리가 말줄임 없이 들어가도록 여유를 둔다.
    /// `timerInterval` 텍스트는 고유 폭이 확정되지 않아 `fixedSize()`를 쓰면
    /// 무한 폭을 요구하고 확장 영역 전체가 렌더링되지 않는다. 반드시 폭을 명시한다.
    private static let clearTimerWidth: CGFloat = 62

    /// 상단 trailing 영역의 소멸 카운트다운.
    /// 하단 모서리 곡선에서 멀리 떨어진 자리라 잘림 없이 배치된다.
    @ViewBuilder
    private func clearTimerLabel(_ context: ActivityViewContext<MemoAttributes>) -> some View {
        if let clearDate = context.state.clearDate, clearDate > .now {
            HStack(spacing: 3) {
                Image(systemName: "timer")
                    .font(.system(size: 9, weight: .semibold))
                Text(timerInterval: Date.now...clearDate, countsDown: true)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(width: Self.clearTimerWidth, alignment: .trailing)
            }
            .foregroundStyle(tint(context))
            .lineLimit(1)
        }
    }

    // MARK: - Compact Trailing

    /// 캡슐 우측 라운드 모서리에 글자가 잘리지 않도록 확보하는 여백
    private static let compactTrailingInset: CGFloat = 4
    /// 여백을 제외한 텍스트 최대 폭 (여백 포함 시 기존 폭과 동일)
    private static let compactTextWidth: CGFloat = 80 - compactTrailingInset
    /// 여백을 제외한 카운트다운 최대 폭 (여백 포함 시 기존 폭과 동일)
    private static let compactCountdownWidth: CGFloat = 70 - compactTrailingInset

    @ViewBuilder
    private func compactTrailingContent(_ context: ActivityViewContext<MemoAttributes>) -> some View {
        let state = context.state
        switch state.renderType {
        case "dday":
            if let target = state.targetDate {
                Text(ddayString(target))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint(context))
                    .monospacedDigit()
            }
        case "countdown":
            if let target = state.targetDate {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .frame(maxWidth: Self.compactCountdownWidth)
            }
        case "progress":
            if let progress = state.progress {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint(context))
                    .monospacedDigit()
            }
        default:
            Text(state.content)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: Self.compactTextWidth)
        }
    }

    // MARK: - Helpers

    private func fontDesign(from fontTag: String) -> Font.Design? {
        switch fontTag {
        case "rounded": .rounded
        case "serif": .serif
        case "mono": .monospaced
        default: nil
        }
    }

    private func tint(_ context: ActivityViewContext<MemoAttributes>) -> Color {
        colorFromTag(context.state.colorTag)
    }

    private func typeLabel(_ context: ActivityViewContext<MemoAttributes>) -> String {
        switch context.state.renderType {
        case "plain": "메모"
        case "checklist": "체크리스트"
        case "dday": "D-day"
        case "countdown": "카운트다운"
        case "progress": "진행바"
        default: "메모"
        }
    }

    private func ddayString(_ target: Date) -> String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: target)
        ).day ?? 0
        if days > 0 { return "D-\(days)" }
        if days == 0 { return "D-Day" }
        return "D+\(abs(days))"
    }

    private func colorFromTag(_ tag: String) -> Color {
        switch tag {
        case "green": Color(red: 31 / 255, green: 169 / 255, blue: 124 / 255)
        case "gold": Color(red: 239 / 255, green: 150 / 255, blue: 69 / 255)
        case "blue": Color(red: 75 / 255, green: 150 / 255, blue: 243 / 255)
        case "rose": Color(red: 238 / 255, green: 123 / 255, blue: 162 / 255)
        default: Color(red: 31 / 255, green: 169 / 255, blue: 124 / 255)
        }
    }
}

#if DEBUG
private extension MemoAttributes.ContentState {
    static var checklist: MemoAttributes.ContentState {
        MemoAttributes.ContentState(
            renderType: "checklist",
            content: "여행 준비물",
            items: [
                LiveChecklistItem(id: "1", title: "여권", done: true),
                LiveChecklistItem(id: "2", title: "충전기", done: false)
            ],
            font: "default",
            colorTag: "green",
            updatedAt: Date()
        )
    }

    static var dday: MemoAttributes.ContentState {
        MemoAttributes.ContentState(
            renderType: "dday",
            content: "프로젝트 마감",
            targetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
            font: "default",
            colorTag: "blue",
            updatedAt: Date()
        )
    }
}

#Preview("Live Activity", as: .content, using: MemoAttributes(memoId: "preview", displayMode: "pinned")) {
    VellureLiveActivityWidget()
} contentStates: {
    MemoAttributes.ContentState.checklist
    MemoAttributes.ContentState.dday
}
#endif
