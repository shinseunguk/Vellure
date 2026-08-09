import Foundation
import SwiftUI
import VellureCore
import VellureData

@Observable
final class MemoListViewModel {
    private let repository: MemoRepository

    var memos: [Memo] = []

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

    func reorder(from source: IndexSet, to destination: Int) {
        var reordered = memos
        reordered.move(fromOffsets: source, toOffset: destination)
        repository.reorder(reordered)
        refresh()
    }

    func memos(ofType type: RenderType) -> [Memo] {
        memos.filter { $0.renderType == type }
    }

    func delete(type: RenderType, at offsets: IndexSet) {
        let group = memos(ofType: type)
        for index in offsets {
            delete(group[index])
        }
    }

    func reorder(type: RenderType, from source: IndexSet, to destination: Int) {
        var group = memos(ofType: type)
        group.move(fromOffsets: source, toOffset: destination)
        var iterator = group.makeIterator()
        let reordered = memos.map { memo in
            memo.renderType == type ? iterator.next()! : memo
        }
        repository.reorder(reordered)
        refresh()
    }

    func toggleActivity(for memo: Memo) {
        if let activityId = memo.activityId {
            Task {
                await LiveActivityService.shared.end(activityId: activityId)
                repository.clearActivityId(memo)
                await MainActor.run { refresh() }
            }
        } else {
            if let activityId = LiveActivityService.shared.start(memo: memo) {
                repository.update(memo, activityId: activityId)
                refresh()
            }
        }
    }
}
