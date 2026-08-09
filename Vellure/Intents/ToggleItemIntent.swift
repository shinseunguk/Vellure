import AppIntents
import ActivityKit
import SwiftData
import VellureCore
import VellureData

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
                await LiveActivityService.shared.update(activityId: activityId, memo: memo)
            }
        }

        return .result()
    }
}
