import AppIntents
import ActivityKit
import Foundation
import SwiftData
import VellureCore

struct ToggleItemIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "intent.toggle.title"

    @Parameter(title: "intent.toggle.memoId")
    var memoId: String

    @Parameter(title: "intent.toggle.itemId")
    var itemId: String

    init() {}

    init(memoId: String, itemId: String) {
        self.memoId = memoId
        self.itemId = itemId
    }

    func perform() async throws -> some IntentResult {
        let context = ModelContext(AppModelContainer.shared)
        let memoUUID = UUID(uuidString: memoId) ?? UUID()
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { $0.id == memoUUID }
        )

        guard let memo = try? context.fetch(descriptor).first,
              var items = memo.items else {
            return .result()
        }

        let targetId = UUID(uuidString: itemId) ?? UUID()
        if let index = items.firstIndex(where: { $0.id == targetId }) {
            items[index].done.toggle()
            memo.items = items
            memo.updatedAt = Date()

            let done = items.filter(\.done).count
            memo.progress = Double(done) / Double(items.count)

            try? context.save()

            let state = MemoAttributes.ContentState(
                renderType: memo.renderType.rawValue,
                content: memo.content,
                items: memo.items?.map {
                    LiveChecklistItem(id: $0.id.uuidString, title: $0.title, done: $0.done)
                },
                targetDate: memo.targetDate,
                progress: memo.progress,
                font: memo.font,
                colorTag: memo.colorTag,
                updatedAt: Date(),
                clearDate: memo.clearDate
            )
            let content = ActivityContent(state: state, staleDate: memo.clearDate)
            for activity in Activity<MemoAttributes>.activities where activity.attributes.memoId == memoId {
                await activity.update(content)
            }
        }

        return .result()
    }
}
