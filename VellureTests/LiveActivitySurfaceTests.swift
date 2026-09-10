import XCTest
import SwiftData
import VellureCore
@testable import VellureData

/// 위젯 표면 타입이 잠금화면에 올라가지 않는지 확인한다.
///
/// UI에서 버튼을 감추는 것만으로는 부족하다. 시리·인텐트처럼 화면을 거치지 않는
/// 경로가 있어, 서비스에서 막아야 규칙이 실제로 지켜진다.
@MainActor
final class LiveActivitySurfaceTests: XCTestCase {

    private var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Memo.self, configurations: config)
    }

    override func tearDownWithError() throws {
        container = nil
    }

    // MARK: - 차단

    func test_start_forDDay_shouldThrowUnsupportedType() {
        assertRejected(.dday)
    }

    func test_start_forProgress_shouldThrowUnsupportedType() {
        assertRejected(.progress)
    }

    /// 표면 분류를 바꿨을 때 이 규칙이 따라오는지 함께 본다.
    func test_start_forEveryWidgetType_shouldBeRejected() {
        for type in Surface.widget.renderTypes {
            assertRejected(type)
        }
    }

    // MARK: - Helpers

    private func assertRejected(
        _ renderType: RenderType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let memo = Memo(renderType: renderType, content: "테스트")
        container.mainContext.insert(memo)

        XCTAssertThrowsError(try LiveActivityService.shared.start(memo: memo), file: file, line: line) { error in
            XCTAssertEqual(
                error as? LiveActivityError,
                .unsupportedType,
                "\(renderType)이 잠금화면에 올라갔다",
                file: file,
                line: line
            )
        }
    }
}
