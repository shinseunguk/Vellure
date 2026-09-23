import Foundation
import OSLog
import UserNotifications
import VellureCore

/// 만료 예고 알림 담당.
///
/// Live Activity는 시작 후 8시간이면 시스템이 갱신을 멈추고, 이 상한은 앱이 늘릴 수 없다.
/// 그 시점에 로컬 알림을 보내 사용자가 탭 한 번으로 다시 올릴 수 있게 한다.
/// (8시간 대응 스택 1층 — docs/plan/mvp2.md 참조)
public final class ExpiryNoticeService {
    public static let shared = ExpiryNoticeService()

    /// 설정 토글 저장 키. 값이 없으면 켜진 것으로 본다 — 실제 노출은 시스템 알림 권한이 한 번 더 거른다.
    public static let enabledKey = "expiryNoticeEnabled"
    private static let identifierPrefix = "expiry-"

    private let logger = Logger(subsystem: "dev.ukseung.Vellure", category: "ExpiryNotice")

    private init() {}

    public var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    static func identifier(for memoId: String) -> String {
        identifierPrefix + memoId
    }

    /// 알림 식별자에서 memoId를 꺼낸다. 만료 예고 알림이 아니면 nil.
    /// 알림 탭을 재게시로 연결하는 쪽(응답 델리게이트)이 쓴다.
    public static func memoId(from identifier: String) -> String? {
        guard identifier.hasPrefix(identifierPrefix) else { return nil }
        return String(identifier.dropFirst(identifierPrefix.count))
    }

    /// 만료 시점에 로컬 알림을 예약한다. 같은 메모의 기존 예약은 교체된다.
    /// 권한이 거부돼 있으면 조용히 넘어간다 — 게시 자체는 이미 성공했다.
    public func schedule(memoId: String, memoTitle: String, at date: Date) async {
        guard isEnabled, date > Date() else { return }

        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else {
            logger.notice("만료 예고 예약 생략: 알림 권한 없음")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = Bundle.main.localizedString(forKey: "notice.expiry.title", value: nil, table: nil)
        content.body = String(
            format: Bundle.main.localizedString(forKey: "notice.expiry.body", value: nil, table: nil),
            memoTitle
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: Self.identifier(for: memoId),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: date.timeIntervalSinceNow,
                repeats: false
            )
        )
        do {
            try await center.add(request)
            logger.notice("만료 예고 예약 완료")
        } catch {
            logger.error("만료 예고 예약 실패: \(String(describing: error), privacy: .public)")
        }
    }

    /// 카드를 내리거나 메모를 지울 때 예약을 거둔다.
    public func cancel(memoId: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.identifier(for: memoId)])
    }

    /// 만료 예고 예약을 모두 거둔다. 설정에서 껐을 때 쓴다.
    public func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
