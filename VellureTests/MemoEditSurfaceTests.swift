import XCTest
import VellureCore

/// 작성 화면이 표면에 맞는 타입만 제시하는지 확인한다.
/// ViewModel은 VellurePresentation 내부 타입이라 여기서는 분류 규칙 자체를 검증한다.
final class MemoEditSurfaceTests: XCTestCase {

    /// 메모 탭에서 새로 만들 때 기본으로 잡히는 타입.
    /// 위젯 표면 타입이 잡히면 저장하는 순간 다른 탭으로 사라진다.
    func test_defaultType_forMemoSurface_shouldStayInMemoSurface() {
        let defaultType = Surface.memo.renderTypes.first
        XCTAssertNotNil(defaultType)
        XCTAssertEqual(defaultType?.surface, .memo)
    }

    func test_defaultType_forWidgetSurface_shouldStayInWidgetSurface() {
        let defaultType = Surface.widget.renderTypes.first
        XCTAssertNotNil(defaultType)
        XCTAssertEqual(defaultType?.surface, .widget)
    }

    /// 선택지가 표면을 넘지 않아야 저장 후 메모가 같은 탭에 남는다.
    func test_availableTypes_shouldNotCrossSurface() {
        for surface in Surface.allCases {
            for type in surface.renderTypes {
                XCTAssertEqual(
                    type.surface,
                    surface,
                    "\(type)이 \(surface) 선택지에 있지만 실제 표면은 \(type.surface)입니다."
                )
            }
        }
    }

    /// 기존 메모를 고칠 때 현재 타입이 선택지에 반드시 포함돼야 한다.
    func test_availableTypes_shouldContainEveryTypeOwnSurface() {
        for type in RenderType.allCases {
            XCTAssertTrue(
                type.surface.renderTypes.contains(type),
                "\(type)을 편집할 때 현재 타입이 선택지에서 빠집니다."
            )
        }
    }
}
