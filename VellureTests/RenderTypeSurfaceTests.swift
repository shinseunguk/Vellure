import XCTest
import VellureCore

final class RenderTypeSurfaceTests: XCTestCase {

    // MARK: - 타입별 표면

    /// 디데이·달성률은 며칠 단위로 지속돼 Live Activity의 8시간 수명과 맞지 않는다.
    func test_surface_whenTypeIsLongLived_shouldBeWidget() {
        XCTAssertEqual(RenderType.dday.surface, .widget)
        XCTAssertEqual(RenderType.progress.surface, .widget)
    }

    /// 하루 안에 소화하는 타입은 Live Activity에 둔다.
    func test_surface_whenTypeIsShortLived_shouldBeMemo() {
        XCTAssertEqual(RenderType.plain.surface, .memo)
        XCTAssertEqual(RenderType.checklist.surface, .memo)
        XCTAssertEqual(RenderType.countdown.surface, .memo)
    }

    // MARK: - 분류의 완전성

    /// 새 타입을 추가하고 표면을 정하지 않으면 컴파일이 막히지만,
    /// 어느 한쪽 표면이 비는 것은 컴파일러가 잡지 못한다.
    func test_renderTypes_shouldCoverEveryTypeExactlyOnce() {
        let classified = Surface.allCases.flatMap(\.renderTypes)

        XCTAssertEqual(classified.count, RenderType.allCases.count)
        XCTAssertEqual(Set(classified), Set(RenderType.allCases))
    }

    func test_renderTypes_shouldNotBeEmptyForAnySurface() {
        for surface in Surface.allCases {
            XCTAssertFalse(
                surface.renderTypes.isEmpty,
                "\(surface) 표면에 속한 타입이 없습니다. 탭이 빈 화면으로 남습니다."
            )
        }
    }

    // MARK: - 표면별 구성

    func test_renderTypes_forMemo_shouldMatchLiveActivityTypes() {
        XCTAssertEqual(Surface.memo.renderTypes, [.plain, .checklist, .countdown])
    }

    func test_renderTypes_forWidget_shouldMatchWidgetTypes() {
        XCTAssertEqual(Surface.widget.renderTypes, [.dday, .progress])
    }
}
