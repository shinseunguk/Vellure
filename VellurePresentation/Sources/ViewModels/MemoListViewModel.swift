import Foundation
import SwiftUI
import VellureCore
import VellureData

@MainActor
@Observable
final class MemoListViewModel {
    private let repository: MemoRepository

    var memos: [Memo] = []
    /// Live Activity를 띄우지 못한 이유. 뷰가 알럿으로 보여준다.
    var activityError: LiveActivityError?
    /// 실제로 잠금화면에 떠 있는 메모 id. "표시 중" 판정의 기준.
    private(set) var runningMemoIds: Set<String> = []

    /// 검색어. 본문과 체크리스트 항목 제목을 대상으로 한다.
    var searchText = ""
    /// 타입 필터. nil이면 전체.
    var typeFilter: RenderType?
    /// 표시 상태 필터.
    var displayFilter: DisplayFilter = .all

    private var hasPendingReorder = false

    init(repository: MemoRepository) {
        self.repository = repository
        refresh()
    }

    func refresh() {
        memos = repository.fetchAll()
        runningMemoIds = LiveActivityService.shared.runningMemoIds
    }

    /// 저장된 activityId가 아니라 실제 실행 중인 Activity를 기준으로 판정한다.
    func isActive(_ memo: Memo) -> Bool {
        runningMemoIds.contains(memo.id.uuidString)
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

    /// 검색·필터가 하나라도 걸려 있는지.
    /// 걸려 있으면 섹션을 접고 단일 결과 목록을 보여주며, 드래그 정렬을 막는다.
    var isFiltering: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
            || typeFilter != nil
            || displayFilter != .all
    }

    /// 검색·필터를 통과한 메모. `isFiltering`일 때만 쓴다.
    var filteredMemos: [Memo] {
        memos.filter { matchesSearch($0) && matchesType($0) && matchesDisplay($0) }
    }

    func clearFilters() {
        searchText = ""
        typeFilter = nil
        displayFilter = .all
    }

    private func matchesSearch(_ memo: Memo) -> Bool {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else { return true }
        if memo.content.localizedCaseInsensitiveContains(keyword) { return true }
        return memo.items?.contains { $0.title.localizedCaseInsensitiveContains(keyword) } ?? false
    }

    private func matchesType(_ memo: Memo) -> Bool {
        guard let typeFilter else { return true }
        return memo.renderType == typeFilter
    }

    private func matchesDisplay(_ memo: Memo) -> Bool {
        switch displayFilter {
        case .all: true
        case .active: isActive(memo)
        case .inactive: !isActive(memo)
        }
    }

    /// 잠금화면에 표시 중인(활성) 메모 — 타입 무관 한 그룹.
    var activeMemos: [Memo] {
        memos.filter { isActive($0) }
    }

    /// 표시 중이 아닌(비활성) 메모 — 타입별 그룹.
    func inactiveMemos(ofType type: RenderType) -> [Memo] {
        memos.filter { !isActive($0) && $0.renderType == type }
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
            return
        }

        // 실패하면 이유를 알럿으로 알린다.
        // (예전에는 조용히 아무 일도 일어나지 않아 "눌러도 안 올라간다"로만 보였다)
        do {
            let activityId = try LiveActivityService.shared.start(memo: memo)
            repository.setActivity(memo, activityId: activityId)
            refresh()
        } catch let error as LiveActivityError {
            activityError = error
        } catch {
            activityError = .unknown(String(describing: type(of: error)))
        }
    }
}
