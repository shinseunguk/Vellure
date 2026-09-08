import Foundation
import SwiftData
import VellureCore
import WidgetKit

@Observable
public final class MemoRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    @discardableResult
    public func create(
        renderType: RenderType = .plain,
        content: String,
        items: [ChecklistItem]? = nil,
        targetDate: Date? = nil,
        progress: Double? = nil,
        displayMode: DisplayMode = .pinned,
        clearTrigger: ClearTrigger? = nil,
        clearAfterHours: Int = Memo.maxClearAfterHours,
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
            clearAfterHours: clearAfterHours,
            font: font,
            colorTag: colorTag,
            sortOrder: maxOrder
        )
        modelContext.insert(memo)
        save()
        return memo
    }

    // MARK: - Read

    public func fetchAll() -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    public func fetch(by id: UUID) -> Memo? {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    public func fetchActive() -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { $0.activityId != nil },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Update

    public func update(
        _ memo: Memo,
        content: String? = nil,
        renderType: RenderType? = nil,
        items: [ChecklistItem]? = nil,
        targetDate: Date? = nil,
        progress: Double? = nil,
        displayMode: DisplayMode? = nil,
        clearTrigger: ClearTrigger? = nil,
        clearAfterHours: Int? = nil,
        font: String? = nil,
        colorTag: String? = nil,
        activityId: String? = nil
    ) {
        if let content { memo.content = content }
        if let renderType { memo.renderType = renderType }
        if let items { memo.items = items }
        if let targetDate { memo.targetDate = targetDate }
        if let progress { memo.progress = progress }
        // clearTrigger는 displayMode와 짝으로만 갱신한다.
        // 무조건 대입하면 activityId만 넘기는 핀 토글 경로에서 트리거가 nil로 지워진다.
        if let displayMode {
            memo.displayMode = displayMode
            memo.clearTrigger = displayMode == .autoClear ? clearTrigger : nil
        }
        if let clearAfterHours { memo.clearAfterHours = clearAfterHours }
        if let font { memo.font = font }
        if let colorTag { memo.colorTag = colorTag }
        if let activityId { memo.activityId = activityId }
        memo.updatedAt = Date()
        save()
    }

    /// Live Activity 시작을 기록한다.
    /// 소멸 시각 계산의 기준이 되는 시작 시각을 activityId와 함께 저장한다.
    public func setActivity(_ memo: Memo, activityId: String, startedAt: Date = Date()) {
        memo.activityId = activityId
        memo.activityStartedAt = startedAt
        memo.updatedAt = Date()
        save()
    }

    public func clearActivityId(_ memo: Memo) {
        memo.activityId = nil
        memo.activityStartedAt = nil
        memo.updatedAt = Date()
        save()
    }

    public func reorder(_ memos: [Memo]) {
        for (index, memo) in memos.enumerated() {
            memo.sortOrder = index
        }
        save()
    }

    // MARK: - Delete

    public func delete(_ memo: Memo) {
        modelContext.delete(memo)
        save()
    }

    // MARK: - Private

    private func save() {
        try? modelContext.save()
        // 위젯은 자기 힘으로 변경을 알 수 없다.
        // 저장할 때마다 타임라인을 다시 만들게 해서 앱과 값이 어긋나지 않게 한다.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
