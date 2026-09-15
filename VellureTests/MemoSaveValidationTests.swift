import XCTest
import VellureCore
@testable import VellurePresentation

/// 내용 없는 메모가 저장되지 않는지 확인한다.
///
/// 내용이 없으면 잠금화면·위젯에 날짜나 숫자만 남아 무엇에 대한 것인지 알 수 없다.
@MainActor
final class MemoSaveValidationTests: XCTestCase {

    func test_canSave_withoutContent_shouldBeFalse() throws {
        for type in [RenderType.plain, .dday, .countdown, .progress] {
            let viewModel = try makeViewModel()
            viewModel.selectType(type)
            viewModel.content = ""

            XCTAssertFalse(viewModel.canSave, "\(type)이 내용 없이 저장된다")
        }
    }

    func test_canSave_withWhitespaceOnly_shouldBeFalse() throws {
        let viewModel = try makeViewModel()
        viewModel.selectType(.dday)
        viewModel.content = "   \n  "

        XCTAssertFalse(viewModel.canSave, "공백만 있는 내용이 저장된다")
    }

    func test_canSave_withContent_shouldBeTrue() throws {
        for type in RenderType.allCases {
            let viewModel = try makeViewModel()
            viewModel.selectType(type)
            viewModel.content = "제주도 여행"

            XCTAssertTrue(viewModel.canSave, "\(type)이 내용이 있는데 저장되지 않는다")
        }
    }

    /// 체크리스트는 항목이 곧 내용이라 제목이 없어도 성립한다.
    func test_canSave_forChecklistWithItemsOnly_shouldBeTrue() throws {
        let viewModel = try makeViewModel()
        viewModel.selectType(.checklist)
        viewModel.content = ""
        viewModel.addChecklistItem(title: "지갑")

        XCTAssertTrue(viewModel.canSave, "항목이 있는 체크리스트가 저장되지 않는다")
    }

    func test_canSave_forChecklistWithBlankItems_shouldBeFalse() throws {
        let viewModel = try makeViewModel()
        viewModel.selectType(.checklist)
        viewModel.content = ""
        viewModel.addChecklistItem(title: "  ")

        XCTAssertFalse(viewModel.canSave, "빈 항목만 있는 체크리스트가 저장된다")
    }

    // MARK: - Helpers

    private func makeViewModel() throws -> MemoEditViewModel {
        let preview = try XCTUnwrap(PreviewSupport.makeRepository(seeded: false))
        return MemoEditViewModel(repository: preview.repository, surface: .memo)
    }
}
