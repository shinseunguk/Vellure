import AppIntents
import ActivityKit
import Foundation
import SwiftData
import VellureCore

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
            clearDate: memo.userClearDate,
            expiresAt: memo.activeDeadline
        )
        let content = ActivityContent(state: state, staleDate: memo.clearDate)

        // 100% 도달 시 소멸: autoClear + .full 트리거 + 진행률 100%
        let isFull = (memo.progress ?? 0) >= 1.0
        let shouldAutoClear = memo.displayMode == .autoClear
            && memo.clearTrigger == .full
            && isFull

        for activity in Activity<MemoAttributes>.activities where activity.attributes.memoId == memoId {
            if shouldAutoClear {
                await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(2)))
            } else {
                await activity.update(content)
            }
        }

        if shouldAutoClear {
            memo.activityId = nil
            try? context.save()
        }

        return .result()
    }
}
