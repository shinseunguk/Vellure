import ActivityKit
import WidgetKit
import SwiftUI

struct VellureLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded (롱탭)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(tint(context))
                            .frame(width: 7, height: 7)
                        Text("Vellure")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tint(context))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(typeLabel(context))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.content)
                            .font(.system(size: 15, weight: .semibold, design: fontDesign(from: context.state.font)))
                            .foregroundStyle(.white)
                            .lineLimit(3)

                        expandedDynamicContent(context)
                        clearCountdownRow(context)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                Circle()
                    .fill(tint(context))
                    .frame(width: 11, height: 11)
            } compactTrailing: {
                // MARK: - Compact Trailing
                compactTrailingContent(context)
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
            }
        case "countdown":
            if let target = state.targetDate {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(tint(context))
                    .monospacedDigit()
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

    // MARK: - Auto-clear Countdown (bottom-right)

    @ViewBuilder
    private func clearCountdownRow(_ context: ActivityViewContext<MemoAttributes>) -> some View {
        if let clearDate = context.state.clearDate, clearDate > .now {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 10, weight: .semibold))
                (Text(timerInterval: Date.now...clearDate, countsDown: true) + Text(" 후 소멸"))
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(tint(context))
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Compact Trailing

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
                    .frame(maxWidth: 70)
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
                .frame(maxWidth: 80)
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
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: target)).day ?? 0
        if days > 0 { return "D-\(days)" }
        if days == 0 { return "D-Day" }
        return "D+\(abs(days))"
    }

    private func colorFromTag(_ tag: String) -> Color {
        switch tag {
        case "green": Color(red: 31/255, green: 169/255, blue: 124/255)
        case "gold": Color(red: 239/255, green: 150/255, blue: 69/255)
        case "blue": Color(red: 75/255, green: 150/255, blue: 243/255)
        case "rose": Color(red: 238/255, green: 123/255, blue: 162/255)
        default: Color(red: 31/255, green: 169/255, blue: 124/255)
        }
    }
}
