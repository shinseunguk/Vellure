import SwiftUI
import SwiftData
import VellureCore
import VellureData

// swiftlint:disable:next type_body_length
struct MemoEditView: View {
    @Environment(MemoRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MemoEditViewModel?
    @State private var activityError: LiveActivityError?
    @State private var didAttemptStart = false
    @FocusState private var contentFocused: Bool

    let memo: Memo?

    var body: some View {
        content
            .liveActivityErrorAlert($activityError)
            // 알럿을 닫은 뒤 화면을 닫는다. 실패 사유를 못 보고 넘어가지 않도록.
            .onChange(of: activityError) { _, error in
                if error == nil && didAttemptStart { dismiss() }
            }
    }

    /// 새 메모를 저장한 직후 Live Activity를 띄운다.
    /// 실패하면 이유를 알럿으로 보여주고, 확인 후 화면을 닫는다.
    private func startActivity(for memo: Memo) {
        didAttemptStart = true
        do {
            let activityId = try LiveActivityService.shared.start(memo: memo)
            repository.setActivity(memo, activityId: activityId)
            dismiss()
        } catch let error as LiveActivityError {
            activityError = error
        } catch {
            activityError = .unknown(String(describing: type(of: error)))
        }
    }

    private var content: some View {
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
                        guard vm.isEditing else {
                            startActivity(for: saved)
                            return
                        }
                        dismiss()
                    } label: {
                        Text(vm.isEditing ? "edit.update.cta" : "edit.save.cta")
                            .scaledFont(15, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(vm.canSave ? Theme.accent : Theme.accent.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!vm.canSave)
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
            sectionLabel(vm.renderType == .plain
                ? String(localized: "edit.section.content")
                : String(localized: "edit.section.content.optional"))
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
                                .scaledFont(20)
                                .foregroundStyle(item.done ? Theme.accent : Theme.textSecondary)
                        }
                        TextField(String(localized: "edit.checklist.placeholder"), text: titleBinding(vm, item))
                            .strikethrough(item.done)
                            .foregroundStyle(item.done ? Theme.textSecondary : Theme.textPrimary)
                        Button {
                            vm.removeChecklistItem(item)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .scaledFont(20)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    Divider().padding(.leading, 48)
                }

                Button {
                    vm.addChecklistItem(title: "")
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .scaledFont(20)
                            .foregroundStyle(Theme.accent)
                        Text("edit.checklist.add")
                            .foregroundStyle(Theme.accent)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                }
            }
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.divider, lineWidth: 1)
            )
        }
    }

    private func titleBinding(_ vm: MemoEditViewModel, _ item: ChecklistItem) -> Binding<String> {
        Binding(
            get: { vm.checklistItems.first(where: { $0.id == item.id })?.title ?? item.title },
            set: { vm.updateChecklistItemTitle(item, title: $0) }
        )
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
                .scaledFont(11)
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
                        .scaledFont(11, weight: .semibold)
                    Text("edit.autoClear.countdownPrefix")
                        .scaledFont(12.5, weight: .semibold)
                    Text(timerInterval: Date.now...clearDate, countsDown: true)
                        .scaledFont(12.5, weight: .semibold)
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
                                    .scaledFont(11, weight: .medium)
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
                                        .scaledFont(14, weight: .bold)
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
                    .scaledFont(15, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
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
