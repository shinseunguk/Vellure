import SwiftUI
import SwiftData
import VellureCore
import VellureData

struct MemoEditView: View {
    @Environment(MemoRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MemoEditViewModel?
    @State private var newItemTitle = ""
    @FocusState private var contentFocused: Bool

    let memo: Memo?

    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            typeSection(vm)
                            contentSection(vm)
                            dynamicSection(vm)
                            displayModeSection(vm)
                            fontSection(vm)
                            colorSection(vm)
                            actionSection(vm)
                        }
                        .padding(20)
                    }

                    Divider()
                    Button {
                        let saved = vm.save()
                        if !vm.isEditing && LiveActivityService.shared.isSupported {
                            if let activityId = LiveActivityService.shared.start(memo: saved) {
                                repository.update(saved, activityId: activityId)
                            }
                        }
                        dismiss()
                    } label: {
                        Text("edit.save.cta")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(vm.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Theme.accent.opacity(0.4) : Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vm.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 26)
                }
                .background(Theme.background)
                .navigationTitle(vm.isEditing
                    ? String(localized: "edit.title.edit")
                    : String(localized: "edit.title.new"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("edit.cancel") { dismiss() }
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MemoEditViewModel(repository: repository, memo: memo)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func contentSection(_ vm: MemoEditViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "edit.section.content"))
            TextField("edit.placeholder", text: Bindable(vm).content, axis: .vertical)
                .lineLimit(3...8)
                .focused($contentFocused)
                .padding(16)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.divider, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func typeSection(_ vm: MemoEditViewModel) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "edit.section.type"))
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(RenderType.allCases, id: \.self) { type in
                    typeChip(type, selected: vm.renderType == type) {
                        vm.renderType = type
                        let available = ClearTrigger.available(for: type)
                        if !available.contains(vm.clearTrigger) {
                            vm.clearTrigger = available.first ?? .hours
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dynamicSection(_ vm: MemoEditViewModel) -> some View {
        switch vm.renderType {
        case .dday, .countdown:
            dateSection(vm)
        case .checklist:
            checklistSection(vm)
        case .progress:
            progressSection(vm)
        case .plain:
            EmptyView()
        }
    }

    @ViewBuilder
    private func dateSection(_ vm: MemoEditViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(vm.renderType == .dday
                ? String(localized: "edit.section.targetDate")
                : String(localized: "edit.section.targetTime"))
            DatePicker(
                "",
                selection: Bindable(vm).targetDate,
                in: Date()...,
                displayedComponents: vm.renderType == .dday ? [.date] : [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .tint(Theme.accent)
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func checklistSection(_ vm: MemoEditViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "edit.section.checklist"))
            VStack(spacing: 0) {
                ForEach(vm.checklistItems) { item in
                    HStack(spacing: 12) {
                        Button {
                            vm.toggleChecklistItem(item)
                        } label: {
                            Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(item.done ? Theme.accent : Theme.textSecondary)
                        }
                        Text(item.title)
                            .strikethrough(item.done)
                            .foregroundStyle(item.done ? Theme.textSecondary : Theme.textPrimary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    if item.id != vm.checklistItems.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.accent)
                    TextField("edit.checklist.add", text: $newItemTitle)
                        .onSubmit {
                            vm.addChecklistItem(title: newItemTitle)
                            newItemTitle = ""
                        }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            }
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.divider, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func progressSection(_ vm: MemoEditViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(format: String(localized: "edit.section.progress"), Int(vm.progress * 100)))
            Slider(value: Bindable(vm).progress, in: 0...1, step: 0.05)
                .tint(Theme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func displayModeSection(_ vm: MemoEditViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "edit.section.displayMode"))
            HStack(spacing: 8) {
                modeButton(
                    title: String(localized: "edit.mode.pinned"),
                    selected: vm.displayMode == .pinned
                ) { vm.displayMode = .pinned }
                modeButton(
                    title: String(localized: "edit.mode.autoClear"),
                    selected: vm.displayMode == .autoClear
                ) { vm.displayMode = .autoClear }
            }
            Text("edit.mode.systemCapNotice")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            if vm.displayMode == .autoClear {
                VStack(spacing: 2) {
                    let triggers = ClearTrigger.available(for: vm.renderType)
                    ForEach(triggers, id: \.self) { trigger in
                        triggerRow(trigger, selected: vm.clearTrigger == trigger) {
                            vm.clearTrigger = trigger
                        }
                        if trigger == .hours, vm.clearTrigger == .hours {
                            hoursStepper(vm)
                        }
                    }
                }
                .padding(6)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.divider, lineWidth: 1)
                )
            }
            if let clearDate = memo?.clearDate, memo?.activityId != nil, clearDate > .now {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .semibold))
                    Text("edit.autoClear.countdownPrefix")
                        .font(.system(size: 12.5, weight: .semibold))
                    Text(timerInterval: Date.now...clearDate, countsDown: true)
                        .font(.system(size: 12.5, weight: .semibold))
                        .monospacedDigit()
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private func fontSection(_ vm: MemoEditViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "edit.section.font"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FontStyle.allCases) { style in
                        Button {
                            vm.font = style.rawValue
                        } label: {
                            VStack(spacing: 6) {
                                Text(style.preview)
                                    .font(style.font(size: 14))
                                    .lineLimit(1)
                                Text(style.displayName)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(vm.font == style.rawValue ? Theme.accent : Theme.chipBackground)
                            .foregroundStyle(vm.font == style.rawValue ? .white : Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private let colorOrder = ["green", "gold", "blue", "rose"]

    @ViewBuilder
    private func colorSection(_ vm: MemoEditViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "edit.section.color"))
            HStack(spacing: 14) {
                ForEach(colorOrder, id: \.self) { key in
                    Button {
                        vm.colorTag = key
                    } label: {
                        Circle()
                            .fill(Theme.memoColors[key] ?? Theme.accent)
                            .frame(width: 40, height: 40)
                            .overlay {
                                if vm.colorTag == key {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .scaleEffect(vm.colorTag == key ? 1.12 : 1.0)
                            .overlay(
                                Circle()
                                    .stroke(vm.colorTag == key ? Theme.textPrimary : Color.clear, lineWidth: 3)
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.colorTag == key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actionSection(_ vm: MemoEditViewModel) -> some View {
        if vm.isEditing {
            Button(role: .destructive) {
                if let memo {
                    if let activityId = memo.activityId {
                        Task { await LiveActivityService.shared.end(activityId: activityId) }
                    }
                    repository.delete(memo)
                }
                dismiss()
            } label: {
                Text("edit.delete")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.textSecondary)
    }

    private func typeChip(_ type: RenderType, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: typeIconName(type))
                    .font(.system(size: 12))
                Text(typeDisplayName(type))
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? Theme.accent : Theme.chipBackground)
            .foregroundStyle(selected ? .white : Theme.textPrimary)
            .clipShape(Capsule())
        }
    }

    private func modeButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
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

    private func triggerRow(_ trigger: ClearTrigger, selected: Bool, action: @escaping () -> Void) -> some View {
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
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(triggerDesc(trigger))
                        .font(.system(size: 11.5))
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

    private func hoursStepper(_ vm: MemoEditViewModel) -> some View {
        Stepper(
            value: Binding(
                get: { vm.clearAfterHours },
                set: { vm.clearAfterHours = $0 }
            ),
            in: 1...12
        ) {
            Text(String(format: String(localized: "trigger.hours.value"), vm.clearAfterHours))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
    }

    private func triggerLabel(_ trigger: ClearTrigger) -> String {
        switch trigger {
        case .target: String(localized: "trigger.target")
        case .hours: String(localized: "trigger.hours")
        case .done: String(localized: "trigger.done")
        case .full: String(localized: "trigger.full")
        }
    }

    private func triggerDesc(_ trigger: ClearTrigger) -> String {
        switch trigger {
        case .target: String(localized: "trigger.target.desc")
        case .hours: String(localized: "trigger.hours.desc")
        case .done: String(localized: "trigger.done.desc")
        case .full: String(localized: "trigger.full.desc")
        }
    }

    private func typeIconName(_ type: RenderType) -> String {
        switch type {
        case .plain: "note.text"
        case .checklist: "checklist"
        case .dday: "calendar"
        case .countdown: "timer"
        case .progress: "chart.bar.fill"
        }
    }

    private func typeDisplayName(_ type: RenderType) -> String {
        switch type {
        case .plain: String(localized: "type.plain")
        case .checklist: String(localized: "type.checklist")
        case .dday: String(localized: "type.dday")
        case .countdown: String(localized: "type.countdown")
        case .progress: String(localized: "type.progress")
        }
    }
}

#if DEBUG
#Preview("새 메모") {
    if let preview = PreviewSupport.makeRepository(seeded: false) {
        MemoEditView(memo: nil)
            .environment(preview.repository)
            .modelContainer(preview.container)
    }
}

#Preview("메모 편집") {
    if let preview = PreviewSupport.makeRepository(seeded: false) {
        MemoEditView(memo: PreviewSupport.sampleMemo())
            .environment(preview.repository)
            .modelContainer(preview.container)
    }
}
#endif
