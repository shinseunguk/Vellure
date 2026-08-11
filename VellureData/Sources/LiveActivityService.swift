import ActivityKit
import Foundation
import VellureCore

public final class LiveActivityService {
    public static let shared = LiveActivityService()

    private init() {}

    public var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    public func start(memo: Memo) -> String? {
        guard isSupported else { return nil }

        let attributes = MemoAttributes(
            memoId: memo.id.uuidString,
            displayMode: memo.displayMode.rawValue
        )

        let state = buildState(from: memo)
        let content = ActivityContent(
            state: state,
            staleDate: memo.clearDate,
            relevanceScore: relevanceScore(for: memo)
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            scheduleAutoDismissIfEligible(activity: activity, memo: memo)
            return activity.id
        } catch {
            print("Live Activity 시작 실패: \(error)")
            return nil
        }
    }

    /// iOS `.after` 소멸 정책의 최대 예약 가능 시간(4시간).
    private static let maxScheduledDismissal: TimeInterval = 4 * 60 * 60

    /// 짧은(≤4h) 비상호작용 autoClear 메모는 시스템이 정확한 시각에 제거하도록 예약한다.
    /// 푸시 없이 백그라운드에서 정시 소멸이 가능한 유일한 경로다.
    /// (4시간 초과·상호작용형은 앱 포그라운드 진입 시 `cleanupExpired`로 정리)
    private func scheduleAutoDismissIfEligible(activity: Activity<MemoAttributes>, memo: Memo) {
        guard memo.displayMode == .autoClear,
              !memo.renderType.isInteractive,
              let clearDate = memo.clearDate,
              clearDate > Date(),
              clearDate <= Date().addingTimeInterval(Self.maxScheduledDismissal) else {
            return
        }

        let content = ActivityContent(
            state: buildState(from: memo),
            staleDate: clearDate,
            relevanceScore: relevanceScore(for: memo)
        )
        Task {
            await activity.end(content, dismissalPolicy: .after(clearDate))
        }
    }

    public func update(activityId: String, memo: Memo) async {
        let state = buildState(from: memo)
        let content = ActivityContent(
            state: state,
            staleDate: memo.clearDate,
            relevanceScore: relevanceScore(for: memo)
        )

        for activity in Activity<MemoAttributes>.activities where activity.id == activityId {
            await activity.update(content)
        }
    }

    /// 저장된 activityId가 어긋나도 동작하도록 attributes의 memoId로 매칭해 갱신한다.
    public func update(memoId: String, memo: Memo) async {
        let state = buildState(from: memo)
        let content = ActivityContent(
            state: state,
            staleDate: memo.clearDate,
            relevanceScore: relevanceScore(for: memo)
        )

        for activity in Activity<MemoAttributes>.activities where activity.attributes.memoId == memoId {
            await activity.update(content)
        }
    }

    /// autoClear 완료 트리거(체크 완료·100% 도달)가 충족되면 소멸, 아니면 갱신한다.
    /// 완료 상태를 잠깐 보여준 뒤 사라지도록 2초 지연 소멸을 사용한다.
    /// - Returns: 소멸을 예약했으면 `true` (호출부에서 activityId 정리)
    @discardableResult
    public func updateOrAutoClear(memo: Memo) async -> Bool {
        let memoId = memo.id.uuidString

        guard shouldAutoClearOnCompletion(memo) else {
            await update(memoId: memoId, memo: memo)
            return false
        }

        let content = ActivityContent(
            state: buildState(from: memo),
            staleDate: memo.clearDate,
            relevanceScore: relevanceScore(for: memo)
        )
        for activity in Activity<MemoAttributes>.activities where activity.attributes.memoId == memoId {
            await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(2)))
        }
        return true
    }

    /// autoClear + 완료 트리거(.done/.full) 조건이 충족됐는지 판정한다.
    private func shouldAutoClearOnCompletion(_ memo: Memo) -> Bool {
        guard memo.displayMode == .autoClear else { return false }
        switch memo.clearTrigger {
        case .done:
            guard let items = memo.items, !items.isEmpty else { return false }
            return items.allSatisfy(\.done)
        case .full:
            return (memo.progress ?? 0) >= 1.0
        default:
            return false
        }
    }

    /// 순서(sortOrder)가 바뀌었을 때 실행 중인 LA들의 relevanceScore를 갱신해
    /// 잠금화면 정렬에 반영한다.
    public func refreshOrder(memos: [Memo]) async {
        let activeIds = Set(Activity<MemoAttributes>.activities.map { $0.attributes.memoId })
        for memo in memos where activeIds.contains(memo.id.uuidString) {
            await update(memoId: memo.id.uuidString, memo: memo)
        }
    }

    /// sortOrder가 작을수록(리스트 위) 높은 점수 → 잠금화면에서 우선 정렬된다.
    private func relevanceScore(for memo: Memo) -> Double {
        Double(max(0, 1000 - memo.sortOrder))
    }

    public func end(activityId: String) async {
        for activity in Activity<MemoAttributes>.activities where activity.id == activityId {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    public func endAll() async {
        for activity in Activity<MemoAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// 앱 재진입 시 만료된 Activity 정리 + activityId 동기화.
    /// 소멸 시각(clearDate)이 지난 Activity는 실제로 종료한다.
    public func cleanupExpired(repository: MemoRepository) {
        let runningIds = Set(Activity<MemoAttributes>.activities.map(\.id))
        let activeMemos = repository.fetchActive()

        for memo in activeMemos {
            guard let activityId = memo.activityId else { continue }

            // 이미 종료된(목록에 없는) Activity → activityId만 정리
            if !runningIds.contains(activityId) {
                repository.clearActivityId(memo)
                continue
            }

            // 소멸 시각이 지난 Activity → 실제 종료 후 activityId 정리
            if let clearDate = memo.clearDate, clearDate <= Date() {
                Task { await end(activityId: activityId) }
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
            updatedAt: Date(),
            clearDate: memo.clearDate
        )
    }
}
