import Foundation
import UserNotifications
import VellureCore
import VellureData

/// 만료 예고 알림 탭을 재게시로 잇는다.
///
/// Live Activity는 포그라운드에서만 시작할 수 있는데, 알림을 탭한 순간
/// 앱이 막 포그라운드로 온 상태이므로 이 시점의 재게시는 시스템이 허용한다.
final class ExpiryNoticeResponder: NSObject, UNUserNotificationCenterDelegate {
    private let repository: MemoRepository

    init(repository: MemoRepository) {
        self.repository = repository
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let memoId = ExpiryNoticeService.memoId(from: response.notification.request.identifier),
              let uuid = UUID(uuidString: memoId) else { return }
        await republish(uuid)
    }

    /// 앱을 쓰는 중에 만료가 오면 배너로 알린다.
    /// 잠금화면 카드는 소리 없이 멈추기 때문에, 앱 안에서는 이 배너가 유일한 신호다.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    @MainActor
    private func republish(_ id: UUID) async {
        guard let memo = repository.fetch(by: id) else { return }
        do {
            let activityId = try await LiveActivityService.shared.start(memo: memo)
            repository.setActivity(memo, activityId: activityId)
        } catch {
            // 재게시가 실패해도 앱은 이미 열려 있다. 사용자가 화면에서 다시 시도할 수 있다.
        }
    }
}
