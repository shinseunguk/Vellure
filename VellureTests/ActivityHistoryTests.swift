import XCTest
import VellureCore

/// 게시 이력이 실제로 저장되고 다시 읽히는지 확인한다.
/// 이 기록은 "8시간이 안 됐는데 사라졌다"를 사실과 대조하는 유일한 수단이라
/// 조용히 비어 있으면 안 된다.
final class ActivityHistoryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ActivityHistory.clear()
    }

    override func tearDown() {
        ActivityHistory.clear()
        super.tearDown()
    }

    func test_recordStart_shouldBeReadBack() {
        ActivityHistory.recordStart(memoId: "memo-1", title: "주차 위치", displayMode: "pinned")

        let records = ActivityHistory.recent()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.memoId, "memo-1")
        XCTAssertEqual(records.first?.title, "주차 위치")
        XCTAssertNil(records.first?.endedAt, "아직 내리지 않았는데 종료로 기록됐다")
    }

    func test_recordEnd_shouldMarkReasonOnOpenRecord() {
        ActivityHistory.recordStart(memoId: "memo-1", title: "주차 위치", displayMode: "pinned")
        ActivityHistory.recordEnd(memoId: "memo-1", reason: .disappeared)

        let record = ActivityHistory.recent().first
        XCTAssertEqual(record?.reason, .disappeared)
        XCTAssertNotNil(record?.endedAt)
    }

    /// 같은 메모를 다시 올렸을 때 이미 끝난 기록을 덮어쓰면 이력이 어긋난다.
    func test_recordEnd_shouldNotTouchClosedRecord() {
        ActivityHistory.recordStart(memoId: "memo-1", title: "첫 번째", displayMode: "pinned")
        ActivityHistory.recordEnd(memoId: "memo-1", reason: .user)
        ActivityHistory.recordStart(memoId: "memo-1", title: "두 번째", displayMode: "pinned")
        ActivityHistory.recordEnd(memoId: "memo-1", reason: .expired)

        let records = ActivityHistory.recent()
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.first?.reason, .expired, "최근 기록에 종료가 적혀야 한다")
        XCTAssertEqual(records.last?.reason, .user, "이미 끝난 기록이 덮어써졌다")
    }

    func test_recent_shouldKeepOnlyLatestEntries() {
        for index in 0..<(ActivityHistory.limit + 5) {
            ActivityHistory.recordStart(memoId: "memo-\(index)", title: "메모 \(index)", displayMode: "pinned")
        }

        let records = ActivityHistory.recent()
        XCTAssertEqual(records.count, ActivityHistory.limit)
        XCTAssertEqual(records.first?.memoId, "memo-\(ActivityHistory.limit + 4)", "최근 것이 앞에 와야 한다")
    }

    func test_excerpt_shouldTrimLongTitle() {
        let long = String(repeating: "가", count: 40)
        ActivityHistory.recordStart(memoId: "memo-1", title: long, displayMode: "pinned")

        let title = ActivityHistory.recent().first?.title ?? ""
        XCTAssertLessThan(title.count, long.count, "긴 내용이 그대로 복사됐다")
        XCTAssertTrue(title.hasSuffix("…"))
    }
}
