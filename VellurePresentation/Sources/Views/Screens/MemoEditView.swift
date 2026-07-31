import SwiftUI
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
                ScrollView {
                    VStack(spacing: 20) {
                        contentSection(vm)
                        typeSection(vm)
                        dynamicSection(vm)
                        displayModeSection(vm)
                        fontSection(vm)
                        colorSection(vm)
                        actionSection(vm)
                    }
                    .padding(20)
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
                    ToolbarItem(placement: .confirmationAction) {
                        Button("edit.save") {
                            let saved = vm.save()
                            if !vm.isEditing && LiveActivityService.shared.isSupported {
                                if let activityId = LiveActivityService.shared.start(memo: saved) {
                                    repository.update(saved, activityId: activityId)
                                }
                            }
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .disabled(vm.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "edit.section.type"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RenderType.allCases, id: \.self) { type in
                        typeChip(type, selected: vm.renderType == type) {
                            vm.renderType = type
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
            Picker("", selection: Bindable(vm).displayMode) {
                Text("edit.mode.pinned").tag(DisplayMode.pinned)
                Text("edit.mode.autoClear").tag(DisplayMode.autoClear)
            }
            .pickerStyle(.segmented)
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

    @ViewBuilder
    private func colorSection(_ vm: MemoEditViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "edit.section.color"))
            HStack(spacing: 12) {
                ForEach(Array(Theme.memoColors.keys.sorted()), id: \.self) { key in
                    Button {
                        vm.colorTag = key
                    } label: {
                        Circle()
                            .fill(Theme.memoColors[key] ?? Theme.accent)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if vm.colorTag == key {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
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
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Theme.accent : Theme.chipBackground)
            .foregroundStyle(selected ? .white : Theme.textPrimary)
            .clipShape(Capsule())
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
