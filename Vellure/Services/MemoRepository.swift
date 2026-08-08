import Foundation
import SwiftData

@Observable
final class MemoRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    @discardableResult
    func create(
        renderType: RenderType = .plain,
        content: String,
        items: [ChecklistItem]? = nil,
        targetDate: Date? = nil,
        progress: Double? = nil,
        displayMode: DisplayMode = .pinned,
        clearTrigger: ClearTrigger? = nil,
        font: String = "default",
        colorTag: String = "green"
    ) -> Memo {
        let maxOrder = (fetchAll().map(\.sortOrder).max() ?? -1) + 1
        let memo = Memo(
            renderType: renderType,
            content: content,
            items: items,
            targetDate: targetDate,
            progress: progress,
            displayMode: displayMode,
            clearTrigger: clearTrigger,
            font: font,
            colorTag: colorTag,
            sortOrder: maxOrder
        )
        modelContext.insert(memo)
        save()
        return memo
    }

    // MARK: - Read

    func fetchAll() -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetch(by id: UUID) -> Memo? {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func fetchActive() -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { $0.activityId != nil },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Update

    func update(_ memo: Memo, content: String? = nil, renderType: RenderType? = nil,
                items: [ChecklistItem]? = nil, targetDate: Date? = nil,
                progress: Double? = nil, displayMode: DisplayMode? = nil,
                clearTrigger: ClearTrigger? = nil,
                font: String? = nil, colorTag: String? = nil, activityId: String? = nil) {
        if let content { memo.content = content }
        if let renderType { memo.renderType = renderType }
        if let items { memo.items = items }
        if let targetDate { memo.targetDate = targetDate }
        if let progress { memo.progress = progress }
        if let displayMode { memo.displayMode = displayMode }
        memo.clearTrigger = clearTrigger
        if let font { memo.font = font }
        if let colorTag { memo.colorTag = colorTag }
        if let activityId { memo.activityId = activityId }
        memo.updatedAt = Date()
        save()
    }

    func clearActivityId(_ memo: Memo) {
        memo.activityId = nil
        memo.updatedAt = Date()
        save()
    }

    func reorder(_ memos: [Memo]) {
        for (index, memo) in memos.enumerated() {
            memo.sortOrder = index
        }
        save()
    }

    // MARK: - Delete

    func delete(_ memo: Memo) {
        modelContext.delete(memo)
        save()
    }

    // MARK: - Private

    private func save() {
        try? modelContext.save()
    }
}
