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
