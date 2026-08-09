import AppIntents
import SwiftUI
import WidgetKit
import VellureCore

struct LockScreenView: View {
    let context: ActivityViewContext<MemoAttributes>

    private var state: MemoAttributes.ContentState { context.state }
    private var tint: Color { colorFromTag(state.colorTag) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(tint)
                            .frame(width: 6, height: 6)
                        Text("Vellure · \(typeLabel)")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(tint)
                    }

                    Text(state.content)
                        .font(.system(size: 14, weight: .semibold, design: fontDesign(from: state.font)))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }

                Spacer()

                dynamicValue
            }

            lockScreenExtraContent
            clearCountdownRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .activityBackgroundTint(.black.opacity(0.85))
    }

    // MARK: - Dynamic Value (right side)

    @ViewBuilder
    private var dynamicValue: some View {
        switch state.renderType {
        case "dday":
            if let target = state.targetDate {
                Text(ddayString(target))
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }
        case "countdown":
            if let target = state.targetDate {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Auto-clear Countdown (bottom-right)

    @ViewBuilder
    private var clearCountdownRow: some View {
        if let clearDate = state.clearDate, clearDate > .now {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 10, weight: .semibold))
                (Text(timerInterval: Date.now...clearDate, countsDown: true) + Text(" 후 소멸"))
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Extra Content (checklist / progress)

    @ViewBuilder
    private var lockScreenExtraContent: some View {
        switch state.renderType {
        case "checklist":
            if let items = state.items {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items.prefix(4), id: \.id) { item in
                        Button(intent: ToggleItemIntent(
                            memoId: context.attributes.memoId,
                            itemId: item.id
                        )) {
                            HStack(spacing: 10) {
                                Image(systemName: item.done ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 16))
                                    .foregroundStyle(item.done ? tint : .white.opacity(0.6))
                                Text(item.title)
                                    .font(.system(size: 14))
                                    .foregroundStyle(item.done ? .white.opacity(0.45) : .white)
                                    .strikethrough(item.done)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if items.count > 4 {
                        Text("외 \(items.count - 4)개")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            }
        case "progress":
            if let progress = state.progress {
                VStack(spacing: 6) {
                    HStack {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        Button(intent: StepProgressIntent(
                            memoId: context.attributes.memoId,
                            delta: -0.1
                        )) {
                            Image(systemName: "minus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        GeometryReader { geo in
                            Capsule()
                                .fill(.white.opacity(0.14))
                                .frame(height: 8)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(tint)
                                        .frame(width: geo.size.width * progress, height: 8)
                                }
                        }
                        .frame(height: 8)

                        Button(intent: StepProgressIntent(
                            memoId: context.attributes.memoId,
                            delta: 0.1
                        )) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 3)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private var typeLabel: String {
        switch state.renderType {
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

    private func fontDesign(from fontTag: String) -> Font.Design? {
        switch fontTag {
        case "rounded": .rounded
        case "serif": .serif
        case "mono": .monospaced
        default: nil
        }
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
