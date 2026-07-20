import AppIntents
import ActivityKit
import SwiftData

struct ToggleItemIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "체크리스트 항목 토글"

    @Parameter(title: "메모 ID")
    var memoId: String

    @Parameter(title: "항목 ID")
    var itemId: String

    init() {}

    init(memoId: String, itemId: String) {
        self.memoId = memoId
        self.itemId = itemId
    }

    func perform() async throws -> some IntentResult {
        let schema = Schema([Memo.self])
        let config = ModelConfiguration(
            "Vellure",
            schema: schema,
            groupContainer: .identifier(Constants.appGroupId)
        )

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return .result()
        }

        let context = ModelContext(container)
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

            if let activityId = memo.activityId {
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
                    updatedAt: Date()
                )
                let content = ActivityContent(state: state, staleDate: nil)
                for activity in Activity<MemoAttributes>.activities where activity.id == activityId {
                    await activity.update(content)
                }
            }
        }

        return .result()
    }
}
