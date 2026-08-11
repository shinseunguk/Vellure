import AppIntents
import SwiftUI
import UIKit
import WidgetKit
import VellureCore

struct LockScreenView: View {
    @Environment(\.colorScheme) private var colorScheme

    let context: ActivityViewContext<MemoAttributes>

    private var state: MemoAttributes.ContentState { context.state }
    private var tint: Color { colorFromTag(state.colorTag) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text("Vellure")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize()
                    Text("· \(typeLabel)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .fixedSize()

                    Spacer(minLength: 8)

                    dynamicValue
                }

                Text(state.content)
                    .font(.headline.weight(.semibold))
                    .fontDesign(fontDesign(from: state.font))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                lockScreenExtraContent
                clearCountdownRow
            }
        }
        .padding(14)
        .activityBackgroundTint(colorScheme == .dark ? .black : .white)
        .activitySystemActionForegroundColor(colorScheme == .dark ? .white : .black)
    }

    // MARK: - Dynamic Value (right side)

    @ViewBuilder
    private var dynamicValue: some View {
        switch state.renderType {
        case "dday":
            if let target = state.targetDate {
                Text(ddayString(target))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
            }
        case "countdown":
            if let target = state.targetDate {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .fixedSize()
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
                Spacer(minLength: 0)
                Image(systemName: "timer")
                    .imageScale(.small)
                Text(timerInterval: Date.now...clearDate, countsDown: true)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56, alignment: .trailing)
                Text("후 소멸")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color(uiColor: .secondaryLabel))
            .lineLimit(1)
        }
    }

    // MARK: - Extra Content (checklist / progress)

    @ViewBuilder
    private var lockScreenExtraContent: some View {
        switch state.renderType {
        case "checklist":
            if let items = state.items {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(items.prefix(4), id: \.id) { item in
                        Button(intent: ToggleItemIntent(
                            memoId: context.attributes.memoId,
                            itemId: item.id
                        )) {
                            HStack(spacing: 8) {
                                Image(systemName: item.done ? "checkmark.square.fill" : "square")
                                    .font(.body)
                                    .foregroundStyle(item.done ? tint : .secondary)
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(item.done ? .secondary : .primary)
                                    .strikethrough(item.done)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if items.count > 4 {
                        Text("외 \(items.count - 4)개")
                            .font(.caption)
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
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        Button(intent: StepProgressIntent(
                            memoId: context.attributes.memoId,
                            direction: "down"
                        )) {
                            Image(systemName: "minus")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                                .frame(width: 30, height: 30)
                                .background(.quaternary, in: Circle())
                        }
                        .buttonStyle(.plain)

                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(tint)
                            .frame(maxWidth: .infinity)

                        Button(intent: StepProgressIntent(
                            memoId: context.attributes.memoId,
                            direction: "up"
                        )) {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                                .frame(width: 30, height: 30)
                                .background(.quaternary, in: Circle())
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
