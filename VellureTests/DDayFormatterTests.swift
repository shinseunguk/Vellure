import XCTest
import VellureCore

final class DDayFormatterTests: XCTestCase {

    /// 기기 설정과 무관하게 같은 결과가 나오도록 달력을 고정한다.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year, month: month, day: day, hour: hour, minute: minute
        )
        guard let date = components.date else {
            XCTFail("테스트 날짜를 만들 수 없습니다: \(year)-\(month)-\(day)")
            return .now
        }
        return date
    }

    private func string(target: Date, reference: Date) -> String {
        DDayFormatter.string(for: target, from: reference, calendar: calendar)
    }

    // MARK: - 당일

    func test_string_whenTargetIsSameDay_shouldReturnDDay() {
        let result = string(
            target: date(2026, 9, 7, 9, 0),
            reference: date(2026, 9, 7, 15, 0)
        )
        XCTAssertEqual(result, "D-Day")
    }

    /// 당일을 "D-0"으로 표기하면 앱 카드와 Live Activity의 값이 어긋난다.
    func test_string_whenTargetIsSameDay_shouldNotReturnDZero() {
        let result = string(
            target: date(2026, 9, 7, 23, 59),
            reference: date(2026, 9, 7, 0, 1)
        )
        XCTAssertNotEqual(result, "D-0")
    }

    // MARK: - 미래

    func test_string_whenTargetIsTomorrow_shouldReturnDMinusOne() {
        let result = string(
            target: date(2026, 9, 8, 9, 0),
            reference: date(2026, 9, 7, 15, 0)
        )
        XCTAssertEqual(result, "D-1")
    }

    /// 남은 시간이 24시간이 안 되더라도 날짜가 다르면 D-1이다.
    /// 시각 기준으로 계산하면 이 경우가 D-0으로 떨어진다.
    func test_string_whenTargetIsNextDayWithinTwentyFourHours_shouldReturnDMinusOne() {
        let result = string(
            target: date(2026, 9, 8, 1, 0),
            reference: date(2026, 9, 7, 23, 0)
        )
        XCTAssertEqual(result, "D-1")
    }

    func test_string_whenTargetIsFarFuture_shouldReturnDayCount() {
        let result = string(
            target: date(2026, 12, 25),
            reference: date(2026, 9, 7)
        )
        XCTAssertEqual(result, "D-109")
    }

    // MARK: - 과거

    func test_string_whenTargetIsYesterday_shouldReturnDPlusOne() {
        let result = string(
            target: date(2026, 9, 6, 23, 0),
            reference: date(2026, 9, 7, 1, 0)
        )
        XCTAssertEqual(result, "D+1")
    }

    func test_string_whenTargetIsPast_shouldReturnPositiveDayCount() {
        let result = string(
            target: date(2026, 9, 1),
            reference: date(2026, 9, 7)
        )
        XCTAssertEqual(result, "D+6")
    }

    // MARK: - 시각 독립성

    /// 같은 날짜라면 하루 중 언제 조회하든 값이 같아야 한다.
    func test_string_whenReferenceTimeVaries_shouldStayConstant() {
        let target = date(2026, 9, 10)
        let results = [0, 6, 12, 18, 23].map { hour in
            string(target: target, reference: date(2026, 9, 7, hour, 30))
        }
        XCTAssertEqual(Set(results), ["D-3"])
    }
}
