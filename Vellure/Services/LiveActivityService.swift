import ActivityKit
import Foundation

final class LiveActivityService {
    static let shared = LiveActivityService()

    private init() {}

    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(memo: Memo) -> String? {
        guard isSupported else { return nil }

        let attributes = MemoAttributes(
            memoId: memo.id.uuidString,
            displayMode: memo.displayMode.rawValue
        )

        let state = buildState(from: memo)
        let staleDate = calculateStaleDate(for: memo)
        let content = ActivityContent(state: state, staleDate: staleDate)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            return activity.id
        } catch {
            print("Live Activity 시작 실패: \(error)")
            return nil
        }
    }

    func update(activityId: String, memo: Memo) async {
        let state = buildState(from: memo)
        let staleDate = calculateStaleDate(for: memo)
        let content = ActivityContent(state: state, staleDate: staleDate)

        for activity in Activity<MemoAttributes>.activities where activity.id == activityId {
            await activity.update(content)
        }
    }

    func end(activityId: String) async {
        for activity in Activity<MemoAttributes>.activities where activity.id == activityId {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    func endAll() async {
        for activity in Activity<MemoAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// 앱 재진입 시 만료된 Activity 정리 + activityId 동기화
    func cleanupExpired(repository: MemoRepository) {
        let activeIds = Set(Activity<MemoAttributes>.activities.map(\.id))
        let activeMemos = repository.fetchActive()

        for memo in activeMemos {
            guard let activityId = memo.activityId else { continue }
            if !activeIds.contains(activityId) {
                repository.clearActivityId(memo)
            }
        }
    }

    // MARK: - Private

    private func buildState(from memo: Memo) -> MemoAttributes.ContentState {
        MemoAttributes.ContentState(
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
    }

    private func calculateStaleDate(for memo: Memo) -> Date? {
        switch memo.displayMode {
        case .autoClear:
            if let targetDate = memo.targetDate,
               (memo.renderType == .countdown || memo.renderType == .dday) {
                return targetDate
            }
            return Date().addingTimeInterval(Constants.activityMaxDuration)
        case .pinned:
            return nil
        }
    }
}
