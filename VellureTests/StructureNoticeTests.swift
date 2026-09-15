import XCTest
@testable import VellurePresentation

final class StructureNoticeTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "StructureNoticeTests"

    override func setUpWithError() throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
    }

    /// v1.0부터 쓰던 사용자는 이 키가 없다.
    func test_needsNotice_whenNoRecord_shouldBeTrue() {
        XCTAssertTrue(StructureNotice.needsNotice(lastSeenVersion: ""))
    }

    func test_needsNotice_whenAlreadyMarked_shouldBeFalse() {
        XCTAssertFalse(StructureNotice.needsNotice(lastSeenVersion: StructureNotice.currentVersion))
    }

    func test_markAsCurrent_shouldStoreCurrentVersion() {
        StructureNotice.markAsCurrent(defaults: defaults)

        XCTAssertEqual(
            defaults.string(forKey: StructureNotice.storageKey),
            StructureNotice.currentVersion
        )
    }

    /// 신규 설치는 온보딩 시점에 표식이 찍혀 안내 대상에서 빠진다.
    /// 이 표식이 없으면 온보딩을 막 마친 사용자에게 "구조가 바뀌었다"는 안내가 뜬다.
    func test_markAsCurrent_shouldMakeNoticeUnnecessary() {
        StructureNotice.markAsCurrent(defaults: defaults)
        let stored = defaults.string(forKey: StructureNotice.storageKey) ?? ""

        XCTAssertFalse(StructureNotice.needsNotice(lastSeenVersion: stored))
    }
}
