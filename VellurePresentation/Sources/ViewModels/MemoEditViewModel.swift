import Foundation
import VellureCore
import VellureData

@Observable
final class MemoEditViewModel {
    private let repository: MemoRepository
    private var existingMemo: Memo?

    var content: String = ""
    var renderType: RenderType = .plain
    var displayMode: DisplayMode = .pinned
    var clearTrigger: ClearTrigger = .hours
    var clearAfterHours: Int = 12
    var font: String = "default"
    var colorTag: String = "green"
    var targetDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    var checklistItems: [ChecklistItem] = []
    var progress: Double = 0.0

    var isEditing: Bool { existingMemo != nil }

    init(repository: MemoRepository, memo: Memo? = nil) {
        self.repository = repository
        if let memo {
            self.existingMemo = memo
            self.content = memo.content
            self.renderType = memo.renderType
            self.displayMode = memo.displayMode
            self.clearTrigger = memo.clearTrigger ?? ClearTrigger.available(for: memo.renderType).first ?? .hours
            self.clearAfterHours = memo.clearAfterHours
            self.font = memo.font
            self.colorTag = memo.colorTag
            self.targetDate = memo.targetDate ?? self.targetDate
            self.checklistItems = memo.items ?? []
            self.progress = memo.progress ?? 0.0
        }
    }

    @discardableResult
    func addChecklistItem(title: String) -> ChecklistItem {
        let item = ChecklistItem(title: title)
        checklistItems.append(item)
        return item
    }

    func removeChecklistItem(at offsets: IndexSet) {
        checklistItems.remove(atOffsets: offsets)
    }

    func updateChecklistItemTitle(_ item: ChecklistItem, title: String) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        checklistItems[index].title = title
    }

    func removeChecklistItem(_ item: ChecklistItem) {
        checklistItems.removeAll { $0.id == item.id }
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        checklistItems[index].done.toggle()
        updateProgress()
    }

    /// 저장 가능 여부. 일반 메모만 본문이 필수이고,
    /// 나머지 타입은 본문을 선택값으로 둔다(타입 데이터로 의미가 성립).
    var canSave: Bool {
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch renderType {
        case .plain:
            return hasContent
        case .checklist:
            let hasItems = checklistItems.contains { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
            return hasContent || hasItems
        case .dday, .countdown, .progress:
            return true
        }
    }

    func save() -> Memo {
        let items: [ChecklistItem]? = renderType == .checklist
            ? checklistItems.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
            : nil
        let target: Date? = (renderType == .dday || renderType == .countdown) ? targetDate : nil
        let prog: Double? = renderType == .progress ? progress : nil
        let trigger: ClearTrigger? = displayMode == .autoClear ? clearTrigger : nil

        if let memo = existingMemo {
            repository.update(
                memo,
                content: content,
                renderType: renderType,
                items: items,
                targetDate: target,
                progress: prog,
                displayMode: displayMode,
                clearTrigger: trigger,
                clearAfterHours: clearAfterHours,
                font: font,
                colorTag: colorTag
            )

            if let activityId = memo.activityId {
                Task {
                    await LiveActivityService.shared.update(activityId: activityId, memo: memo)
                }
            }

            return memo
        } else {
            return repository.create(
                renderType: renderType,
                content: content,
                items: items,
                targetDate: target,
                progress: prog,
                displayMode: displayMode,
                clearTrigger: trigger,
                clearAfterHours: clearAfterHours,
                font: font,
                colorTag: colorTag
            )
        }
    }

    private func updateProgress() {
        guard !checklistItems.isEmpty else {
            progress = 0.0
            return
        }
        let done = checklistItems.filter(\.done).count
        progress = Double(done) / Double(checklistItems.count)
    }
}
