import SwiftUI
import WidgetKit

struct LockScreenView: View {
    let context: ActivityViewContext<MemoAttributes>

    private var state: MemoAttributes.ContentState { context.state }
    private var tint: Color { colorFromTag(state.colorTag) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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
        .padding(14)
        .activityBackgroundTint(.black.opacity(0.85))
    }

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
        case "progress":
            if let progress = state.progress {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }
        case "checklist":
            if let items = state.items {
                let done = items.filter(\.done).count
                Text("\(done)/\(items.count)")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }
        default:
            EmptyView()
        }
    }

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
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: target)).day ?? 0
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
        case "green": Color(red: 31/255, green: 169/255, blue: 124/255)
        case "blue": Color(red: 59/255, green: 130/255, blue: 246/255)
        case "purple": Color(red: 139/255, green: 92/255, blue: 246/255)
        case "orange": Color(red: 245/255, green: 158/255, blue: 11/255)
        case "red": Color(red: 239/255, green: 68/255, blue: 68/255)
        case "pink": Color(red: 236/255, green: 72/255, blue: 153/255)
        case "teal": Color(red: 20/255, green: 184/255, blue: 166/255)
        default: Color(red: 31/255, green: 169/255, blue: 124/255)
        }
    }
}
