import ActivityKit
import WidgetKit
import SwiftUI
import VellureCore

struct VellureLiveActivityWidget: Widget {
    /// 확장 상태 콘텐츠의 좌우 여백.
    /// 아일랜드 코너 곡선 마스크에 좌우가 잘리는 것을 막는다.
    private static let expandedContentInset: CGFloat = 10
    /// 본문과 위아래 요소 사이에 추가로 두는 여백
    private static let contentVerticalPadding: CGFloat = 2
    /// 본문과 타입별 콘텐츠 사이 여백
    private static let contentSpacing: CGFloat = 8

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded (롱탭)
                // 상단 좌우 영역은 카메라 컷아웃에 폭이 눌려 잘림이 잦다.
                // 콘텐츠를 폭이 온전한 하단 영역 하나에 모아 잘림을 없앤다.
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: Self.contentSpacing) {
                        if hasContent(context) {
                            Text(context.state.content)
                                .font(.headline.weight(.semibold))
                                .fontDesign(fontDesign(from: context.state.font))
                                .foregroundStyle(.primary)
                                .lineLimit(expandedContentLineLimit(context))
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        expandedDynamicContent(context)
                    }
                    .padding(.horizontal, Self.expandedContentInset)
                    .padding(.vertical, Self.contentVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Circle()
                    .fill(tint(context))
                    .frame(width: 11, height: 11)
            } compactTrailing: {
                compactTrailingContent(context)
                    .padding(.trailing, Self.compactTrailingInset)
            } minimal: {
                Circle()
                    .fill(tint(context))
                    .frame(width: 11, height: 11)
            }
        }
    }

    private func hasContent(_ context: ActivityViewContext<MemoAttributes>) -> Bool {
        !context.state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 타입별 본문 최대 줄 수.
    /// 확장 영역도 높이 상한이 있어, 아래 콘텐츠가 클수록 본문 줄 수를 줄인다.
    private func expandedContentLineLimit(_ context: ActivityViewContext<MemoAttributes>) -> Int {
        switch context.state.renderType {
        case "checklist": 1
        case "progress", "dday", "countdown": 2
        default: 3
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
