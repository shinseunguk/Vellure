import AppIntents
import ActivityKit
import SwiftData
import VellureCore
import VellureData

struct StepProgressIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "intent.stepProgress.title"

    @Parameter(title: "intent.toggle.memoId")
    var memoId: String

    @Parameter(title: "intent.stepProgress.direction")
    var direction: String

    init() {}

    init(memoId: String, direction: String) {
        self.memoId = memoId
        self.direction = direction
    }

    func perform() async throws -> some IntentResult {
        let context = ModelContext(AppModelContainer.shared)
        let memoUUID = UUID(uuidString: memoId) ?? UUID()
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { $0.id == memoUUID }
        )

        guard let memo = try? context.fetch(descriptor).first else {
            return .result()
        }

        let delta = direction == "up" ? 0.1 : -0.1
        let current = memo.progress ?? 0
        memo.progress = max(0, min(1, current + delta))
        memo.updatedAt = Date()
        try? context.save()

        await LiveActivityService.shared.update(memoId: memoId, memo: memo)

        return .result()
    }
}
