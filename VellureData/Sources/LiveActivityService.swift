import ActivityKit
import Foundation
import OSLog
import VellureCore

public final class LiveActivityService {
    public static let shared = LiveActivityService()

    /// 릴리스 빌드에서도 남는 진단 로그. 메모 내용 등 민감정보는 담지 않는다.
    private let logger = Logger(subsystem: "com.ukseung.Vellure", category: "LiveActivity")

    private init() {}

    public var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// 실제로 잠금화면에 떠 있는 Live Activity의 memoId 집합.
    /// 저장된 activityId는 요청이 성공했다는 기록일 뿐 현재 표시 여부를 보장하지 않으므로,
    /// "표시 중" 판정은 반드시 이 값을 기준으로 한다.
    ///
    /// 기준은 *갱신 가능한가*가 아니라 *화면에 보이는가*다.
    /// `.ended`는 갱신은 못 하지만 잠금화면에는 최대 4시간 더 남아 있으므로 포함한다.
    /// (제외하면 소멸 예약된 메모가 화면에 보이는데도 비활성으로 분류된다)
    public var runningMemoIds: Set<String> {
        Set(
            Activity<MemoAttributes>.activities
                .filter { $0.activityState != .dismissed }
                .map(\.attributes.memoId)
        )
    }

    /// Live Activity를 띄우고 activityId를 돌려준다.
    /// 실패하면 이유를 담은 `LiveActivityError`를 던진다.
    /// (예전에는 nil을 반환해 호출부가 실패를 알 수 없었고, 사용자에게도 아무 안내가 없었다)
    public func start(memo: Memo) throws -> String {
        guard isSupported else {
            logger.warning("Live Activity 시작 거부: 설정에서 비활성화됨")
            throw LiveActivityError.notEnabled
        }

        let attributes = MemoAttributes(
            memoId: memo.id.uuidString,
            displayMode: memo.displayMode.rawValue
        )

        // 소멸 시각은 "지금 띄우는 시점" 기준이어야 한다.
        // memo.clearDate는 activityStartedAt이 아직 없으면 updatedAt을 기준으로 삼으므로,
        // 오래전에 쓴 메모를 올릴 때 staleDate가 과거가 되는 것을 막는다.
        // staleDate는 12시간(clearDate)이 아니라 8시간(activeDeadline)이어야 한다.
        // 8시간이 지나면 시스템이 활동을 종료해 갱신이 멈추므로, 그 시점에
        // isStale이 켜지며 뷰가 다시 그려져야 사용자에게 멈춤을 알릴 수 있다.
        let startedAt = Date()
        let content = ActivityContent(
            state: buildState(from: memo, startedAt: startedAt),
            staleDate: memo.activeDeadline(startedAt: startedAt),
            relevanceScore: relevanceScore(for: memo)
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            scheduleAutoDismissIfEligible(activity: activity, memo: memo, startedAt: startedAt)
            logger.info("Live Activity 시작 성공")
            return activity.id
        } catch {
            let mapped = Self.mapped(error)
            logger.error("Live Activity 시작 실패: \(mapped.diagnosticCode, privacy: .public)")
            throw mapped
        }
    }

    /// ActivityKit 오류를 사용자에게 보여줄 수 있는 형태로 옮긴다.
    private static func mapped(_ error: Error) -> LiveActivityError {
        guard let authorizationError = error as? ActivityAuthorizationError else {
            return .unknown(String(describing: type(of: error)))
        }
        switch authorizationError {
        case .denied, .unsupported, .unentitled:
            return .notEnabled
        case .targetMaximumExceeded, .globalMaximumExceeded:
            return .tooManyActivities
        case .attributesTooLarge:
            return .contentTooLarge
        default:
            return .unknown(String(describing: authorizationError))
        }
    }

    /// 시작 시각을 기준으로 한 소멸 시각.
    /// 아직 memo.activityStartedAt이 저장되기 전이라 여기서 직접 계산한다.
    private func clearDate(for memo: Memo, startedAt: Date) -> Date? {
        let systemCap = startedAt.addingTimeInterval(Memo.systemMaxDuration)
        switch memo.displayMode {
        case .pinned:
            return systemCap
        case .autoClear:
            switch memo.clearTrigger {
            case .target:
                guard let targetDate = memo.targetDate else { return systemCap }
                return min(targetDate, systemCap)
            case .hours, .none:
                let requested = startedAt.addingTimeInterval(TimeInterval(memo.clearAfterHours) * 3600)
                return min(requested, systemCap)
            case .done, .full:
                return systemCap
            }
        }
    }

    /// iOS `.after` 소멸 정책의 최대 예약 가능 시간(4시간).
    private static let maxScheduledDismissal: TimeInterval = 4 * 60 * 60

    /// 짧은(≤4h) 비상호작용 autoClear 메모는 시스템이 정확한 시각에 제거하도록 예약한다.
    /// 푸시 없이 백그라운드에서 정시 소멸이 가능한 유일한 경로다.
    /// (4시간 초과·상호작용형은 앱 포그라운드 진입 시 `cleanupExpired`로 정리)
    private func scheduleAutoDismissIfEligible(
        activity: Activity<MemoAttributes>,
        memo: Memo,
        startedAt: Date? = nil
    ) {
        guard memo.displayMode == .autoClear,
              !memo.renderType.isInteractive,
              let clearDate = startedAt.map({ clearDate(for: memo, startedAt: $0) }) ?? memo.clearDate,
              clearDate > Date(),
              clearDate <= Date().addingTimeInterval(Self.maxScheduledDismissal) else {
            return
        }

        let content = ActivityContent(
            state: buildState(from: memo, startedAt: startedAt),
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
            staleDate: memo.activeDeadline(),
            relevanceScore: relevanceScore(for: memo)
        )

        for activity in Activity<MemoAttributes>.activities where activity.id == activityId {
            await activity.update(content)
            // 편집으로 트리거·목표 시각이 바뀌었을 수 있다.
            // 예약을 다시 걸지 않으면 "목표 시각 도달 시"로 바꿔도 소멸하지 않는다.
            scheduleAutoDismissIfEligible(activity: activity, memo: memo)
        }
    }

    /// 저장된 activityId가 어긋나도 동작하도록 attributes의 memoId로 매칭해 갱신한다.
    public func update(memoId: String, memo: Memo) async {
        let state = buildState(from: memo)
        let content = ActivityContent(
            state: state,
            staleDate: memo.activeDeadline(),
            relevanceScore: relevanceScore(for: memo)
        )

        for activity in Activity<MemoAttributes>.activities where activity.attributes.memoId == memoId {
            await activity.update(content)
            scheduleAutoDismissIfEligible(activity: activity, memo: memo)
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
            staleDate: memo.activeDeadline(),
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
    /// 앱 진입 시 만료된 Live Activity를 잠금화면에서 내린다.
    ///
    /// 8시간이 지나면 시스템이 활동을 종료해 갱신이 멈춘다.
    /// 그 뒤로 최대 4시간은 잠금화면에 남지만, 체크박스를 눌러도 화면이 바뀌지 않고
    /// 완료 시 자동소멸도 동작하지 않는 "죽은 카드"다. 남겨둘 이유가 없으므로 즉시 내린다.
    ///
    /// 8시간 정각에 내리지 못하는 것은 앱이 꺼져 있으면 코드가 돌지 않기 때문이다.
    /// 앱을 여는 시점이 로컬 앱이 개입할 수 있는 가장 이른 순간이다.
    public func cleanupExpired(repository: MemoRepository) {
        let runningIds = Set(Activity<MemoAttributes>.activities.map(\.id))
        let activeMemos = repository.fetchActive()

        for memo in activeMemos {
            guard let activityId = memo.activityId else { continue }

            // 이미 사라진(목록에 없는) Activity → activityId만 정리
            if !runningIds.contains(activityId) {
                repository.clearActivityId(memo)
                continue
            }

            // 갱신이 멈춘(8시간 경과) Activity → 잠금화면에서 내리고 기록도 정리
            if let deadline = memo.activeDeadline(), deadline <= Date() {
                Task { await end(activityId: activityId) }
                repository.clearActivityId(memo)
            }
        }
    }

    // MARK: - 실시간 동기화 (앱 사용 중 LA 제거 감지)

    private var isSyncObserving = false

    /// 앱 실행 중 LA가 잠금화면에서 사라지면 즉시 저장된 activityId를 정리해
    /// 리스트의 "표시 중" 상태를 실제 LA와 맞춘다.
    /// 실행 목록에서 제거된 것만 정리하므로, `.ended`(종료됐지만 화면에 남은) 상태는 유지된다.
    /// (백그라운드에서 사라진 건 포그라운드 진입 시 `cleanupExpired`가 정리)
    @MainActor
    public func startActivitySync(repository: MemoRepository) {
        guard !isSyncObserving else { return }
        isSyncObserving = true

        reconcileActiveMemos(repository: repository)

        Task { @MainActor in
            for activity in Activity<MemoAttributes>.activities {
                observeDismissal(of: activity, repository: repository)
            }
            for await activity in Activity<MemoAttributes>.activityUpdates {
                observeDismissal(of: activity, repository: repository)
            }
        }
    }

    /// 개별 Activity의 상태 스트림을 관찰하다 제거(dismissed)되거나 스트림이 끝나면 정리한다.
    @MainActor
    private func observeDismissal(of activity: Activity<MemoAttributes>, repository: MemoRepository) {
        Task { @MainActor in
            for await state in activity.activityStateUpdates where state == .dismissed {
                reconcileActiveMemos(repository: repository)
            }
            reconcileActiveMemos(repository: repository)
        }
    }

    /// 실행 목록에 없는(사라진) 저장 activityId를 정리한다.
    @MainActor
    public func reconcileActiveMemos(repository: MemoRepository) {
        let runningIds = Set(Activity<MemoAttributes>.activities.map(\.id))
        for memo in repository.fetchActive() {
            if let activityId = memo.activityId, !runningIds.contains(activityId) {
                repository.clearActivityId(memo)
            }
        }
    }

    // MARK: - Private

    /// - Parameter startedAt: Live Activity를 지금 막 띄우는 경우의 시작 시각.
    ///   저장소에 `activityStartedAt`이 반영되기 전이라 호출부가 직접 넘겨야 한다.
    ///   nil이면 메모에 저장된 값을 쓴다.
    private func buildState(from memo: Memo, startedAt: Date? = nil) -> MemoAttributes.ContentState {
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
            // 표시용은 사용자가 지정한 소멸 시각만.
            // 시스템 만료(staleDate)는 ActivityContent 쪽에서 별도로 memo.clearDate를 쓴다.
            clearDate: memo.userClearDate,
            expiresAt: memo.activeDeadline(startedAt: startedAt)
        )
    }
}
