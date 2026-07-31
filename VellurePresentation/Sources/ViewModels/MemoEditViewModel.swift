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
            self.font = memo.font
            self.colorTag = memo.colorTag
            self.targetDate = memo.targetDate ?? self.targetDate
            self.checklistItems = memo.items ?? []
            self.progress = memo.progress ?? 0.0
        }
    }

    func addChecklistItem(title: String) {
        guard !title.isEmpty else { return }
        checklistItems.append(ChecklistItem(title: title))
    }

    func removeChecklistItem(at offsets: IndexSet) {
        checklistItems.remove(atOffsets: offsets)
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        checklistItems[index].done.toggle()
        updateProgress()
    }

    func save() -> Memo {
        let items: [ChecklistItem]? = renderType == .checklist ? checklistItems : nil
        let target: Date? = (renderType == .dday || renderType == .countdown) ? targetDate : nil
        let prog: Double? = renderType == .progress ? progress : nil

        if let memo = existingMemo {
            repository.update(
                memo,
                content: content,
                renderType: renderType,
                items: items,
                targetDate: target,
                progress: prog,
                displayMode: displayMode,
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
