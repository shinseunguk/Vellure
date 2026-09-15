import XCTest
import VellureCore
@testable import VellurePresentation

/// 지난 날짜를 목표일로 쓸 수 있는 타입과, 타입 전환 시 보정 규칙을 확인한다.
final class PastTargetDateTests: XCTestCase {

    // MARK: - 타입별 허용 여부

    /// D-day는 지난 날도 의미가 있다 — 만난 지 100일, 금연 30일차.
    func test_allowsPastTarget_forDDay_shouldBeTrue() {
        XCTAssertTrue(RenderType.dday.allowsPastTarget)
    }

    /// 카운트다운은 남은 시간을 세므로 지난 시각이 성립하지 않는다.
    func test_allowsPastTarget_forCountdown_shouldBeFalse() {
        XCTAssertFalse(RenderType.countdown.allowsPastTarget)
    }

    func test_allowsPastTarget_forNonDateTypes_shouldBeFalse() {
        XCTAssertFalse(RenderType.plain.allowsPastTarget)
        XCTAssertFalse(RenderType.checklist.allowsPastTarget)
        XCTAssertFalse(RenderType.progress.allowsPastTarget)
    }

    // MARK: - 지난 목표일 표기

    /// 지난 날짜로 만든 D-day가 D+N으로 나와야 카운트업이 성립한다.
    func test_string_forPastTarget_shouldCountUp() {
        let hundredDaysAgo = Calendar.current.date(byAdding: .day, value: -100, to: .now)

        XCTAssertEqual(DDayFormatter.string(for: try XCTUnwrap(hundredDaysAgo)), "D+100")
    }

    // MARK: - 타입 전환 시 보정

    /// 지난 날짜를 고른 D-day에서 카운트다운으로 넘어가면 목표 시각이 이미 지나 있어
    /// 저장하자마자 완료된 카운트다운이 된다.
    @MainActor
    func test_selectType_toCountdown_whenTargetIsPast_shouldMoveToFuture() throws {
        let viewModel = try makeViewModel()
        viewModel.targetDate = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -30, to: .now))

        viewModel.selectType(.countdown)

        XCTAssertGreaterThan(viewModel.targetDate, .now, "카운트다운 목표 시각이 과거로 남았다")
    }

    /// D-day로 돌아갈 때는 지난 날짜를 건드리지 않아야 한다.
    @MainActor
    func test_selectType_toDDay_whenTargetIsPast_shouldKeepDate() throws {
        let viewModel = try makeViewModel()
        let past = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -30, to: .now))
        viewModel.targetDate = past

        viewModel.selectType(.dday)

        XCTAssertEqual(viewModel.targetDate, past, "D-day에서 지난 목표일이 보정됐다")
    }

    @MainActor
    func test_selectType_toCountdown_whenTargetIsFuture_shouldKeepDate() throws {
        let viewModel = try makeViewModel()
        let future = try XCTUnwrap(Calendar.current.date(byAdding: .hour, value: 3, to: .now))
        viewModel.targetDate = future

        viewModel.selectType(.countdown)

        XCTAssertEqual(viewModel.targetDate, future, "미래 목표일이 불필요하게 바뀌었다")
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel() throws -> MemoEditViewModel {
        let preview = try XCTUnwrap(PreviewSupport.makeRepository(seeded: false))
        return MemoEditViewModel(repository: preview.repository, surface: .widget)
    }
}
