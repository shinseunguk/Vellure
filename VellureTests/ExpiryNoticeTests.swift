import XCTest
import VellureCore
@testable import VellureData

/// 만료 예고를 "언제" 보낼지에 대한 규칙을 확인한다.
///
/// 시스템 8시간 상한이 카드 수명을 자르는 경우에만 알린다.
/// 사용자가 정한 소멸이 먼저 오면 의도된 종료라 알릴 이유가 없다.
final class ExpiryNoticeTests: XCTestCase {

    private let startedAt = Date(timeIntervalSince1970: 1_700_000_000)

    private var activeCap: Date {
        startedAt.addingTimeInterval(Memo.systemActiveDuration)
    }

    func test_pinnedMemo_shouldNoticeAtEightHours() {
        let memo = Memo(renderType: .plain, content: "고정", displayMode: .pinned)

        let notice = LiveActivityService.shared.expiryNoticeDate(for: memo, startedAt: startedAt)

        XCTAssertEqual(notice, activeCap)
    }

    func test_shortAutoClear_shouldNotNotice() {
        let memo = Memo(
            renderType: .plain,
            content: "3시간 뒤 소멸",
            displayMode: .autoClear,
            clearTrigger: .hours,
            clearAfterHours: 3
        )

        XCTAssertNil(LiveActivityService.shared.expiryNoticeDate(for: memo, startedAt: startedAt))
    }

    func test_longAutoClear_shouldNoticeAtEightHours() {
        // 12시간을 요청해도 8시간 상한이 먼저 온다.
        let memo = Memo(
            renderType: .plain,
            content: "12시간 뒤 소멸",
            displayMode: .autoClear,
            clearTrigger: .hours,
            clearAfterHours: 12
        )

        let notice = LiveActivityService.shared.expiryNoticeDate(for: memo, startedAt: startedAt)

        XCTAssertEqual(notice, activeCap)
    }

    func test_identifier_roundTrip() {
        let memoId = UUID().uuidString

        let identifier = ExpiryNoticeService.identifier(for: memoId)

        XCTAssertEqual(ExpiryNoticeService.memoId(from: identifier), memoId)
    }

    func test_unrelatedIdentifier_shouldReturnNil() {
        XCTAssertNil(ExpiryNoticeService.memoId(from: "daily-reminder"))
    }
}
