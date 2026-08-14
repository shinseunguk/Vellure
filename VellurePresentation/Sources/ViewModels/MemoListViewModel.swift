import Foundation
import SwiftUI
import VellureCore
import VellureData

@MainActor
@Observable
final class MemoListViewModel {
    private let repository: MemoRepository

    var memos: [Memo] = []

    private var hasPendingReorder = false

    init(repository: MemoRepository) {
        self.repository = repository
        refresh()
    }

    func refresh() {
        memos = repository.fetchAll()
    }

    func delete(_ memo: Memo) {
        if let activityId = memo.activityId {
            Task {
                await LiveActivityService.shared.end(activityId: activityId)
            }
        }
        repository.delete(memo)
        refresh()
    }

    /// 잠금화면에 표시 중인(활성) 메모 — 타입 무관 한 그룹.
    var activeMemos: [Memo] {
        memos.filter { $0.activityId != nil }
    }

    /// 표시 중이 아닌(비활성) 메모 — 타입별 그룹.
    func inactiveMemos(ofType type: RenderType) -> [Memo] {
        memos.filter { $0.activityId == nil && $0.renderType == type }
    }

    /// 한 섹션(그룹) 안에서 fromIndex 메모를 toIndex 위치로 옮긴다 (커스텀 드래그).
    /// 순서만 메모리에 반영하고, 저장은 `commitReorder()`에서 일괄 처리한다.
    /// - Parameter matches: 해당 그룹에 속하는 메모를 판별하는 조건.
    func moveInGroup(_ items: [Memo], fromIndex: Int, toIndex: Int, matches: (Memo) -> Bool) {
        var group = items
        guard group.indices.contains(fromIndex) else { return }
        let item = group.remove(at: fromIndex)
        let clamped = min(max(toIndex, 0), group.count)
        group.insert(item, at: clamped)

        var iterator = group.makeIterator()
        memos = memos.map { matches($0) ? (iterator.next() ?? $0) : $0 }
        hasPendingReorder = true
    }

    /// 재정렬 종료 시 변경된 순서를 저장하고, 실행 중인 LA의 relevanceScore에 반영한다.
    func commitReorder() {
        guard hasPendingReorder else { return }
        hasPendingReorder = false

        repository.reorder(memos)
        let current = memos
        Task { await LiveActivityService.shared.refreshOrder(memos: current) }
    }

    func toggleActivity(for memo: Memo) {
        if let activityId = memo.activityId {
            Task {
                await LiveActivityService.shared.end(activityId: activityId)
                repository.clearActivityId(memo)
                refresh()
            }
        } else {
            if let activityId = LiveActivityService.shared.start(memo: memo) {
                repository.update(memo, activityId: activityId)
                refresh()
            }
        }
    }
}
