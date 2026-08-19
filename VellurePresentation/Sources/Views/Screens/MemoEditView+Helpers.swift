import SwiftUI
import VellureCore

// 파일 길이 제한(500줄)을 지키기 위해 편집 화면의 표현 헬퍼를 분리한다.
// private는 파일 스코프라 본문에서 호출할 수 없어 모듈 내부 접근으로 둔다.
extension MemoEditView {

    func sectionLabel(_ title: String) -> some View {
        Text(title)
            .scaledFont(13, weight: .bold)
            .foregroundStyle(Theme.textSecondary)
    }

    func typeChip(_ type: RenderType, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: typeIconName(type))
                    .scaledFont(12)
                Text(typeDisplayName(type))
                    .scaledFont(13, weight: .semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? Theme.accent : Theme.chipBackground)
            .foregroundStyle(selected ? .white : Theme.textPrimary)
            .clipShape(Capsule())
        }
    }

    func modeButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .scaledFont(13, weight: .semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Theme.accent : Theme.chipBackground)
                .foregroundStyle(selected ? .white : Theme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selected ? Color.clear : Theme.divider, lineWidth: 1)
                )
        }
    }

    func triggerRow(_ trigger: ClearTrigger, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .strokeBorder(selected ? Theme.accent : Theme.textSecondary, lineWidth: 2)
                    .frame(width: 18, height: 18)
                    .overlay {
                        if selected {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 8, height: 8)
                        }
                    }
                VStack(alignment: .leading, spacing: 1) {
                    Text(triggerLabel(trigger))
                        .scaledFont(13.5, weight: .semibold)
                        .foregroundStyle(Theme.textPrimary)
                    Text(triggerDesc(trigger))
                        .scaledFont(11.5)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .background(selected ? Theme.accent.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    func hoursStepper(_ vm: MemoEditViewModel) -> some View {
        Stepper(
            value: Binding(
                get: { vm.clearAfterHours },
                set: { vm.clearAfterHours = $0 }
            ),
            in: 1...12
        ) {
            Text(String(format: String(localized: "trigger.hours.value"), vm.clearAfterHours))
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
    }

    func triggerLabel(_ trigger: ClearTrigger) -> String {
        switch trigger {
        case .target: String(localized: "trigger.target")
        case .hours: String(localized: "trigger.hours")
        case .done: String(localized: "trigger.done")
        case .full: String(localized: "trigger.full")
        }
    }

    func triggerDesc(_ trigger: ClearTrigger) -> String {
        switch trigger {
        case .target: String(localized: "trigger.target.desc")
        case .hours: String(localized: "trigger.hours.desc")
        case .done: String(localized: "trigger.done.desc")
        case .full: String(localized: "trigger.full.desc")
        }
    }

    func typeIconName(_ type: RenderType) -> String {
        switch type {
        case .plain: "note.text"
        case .checklist: "checklist"
        case .dday: "calendar"
        case .countdown: "timer"
        case .progress: "chart.bar.fill"
        }
    }

    func typeDisplayName(_ type: RenderType) -> String {
        switch type {
        case .plain: String(localized: "type.plain")
        case .checklist: String(localized: "type.checklist")
        case .dday: String(localized: "type.dday")
        case .countdown: String(localized: "type.countdown")
        case .progress: String(localized: "type.progress")
        }
    }
}
