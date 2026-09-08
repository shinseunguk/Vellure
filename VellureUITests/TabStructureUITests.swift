import XCTest

/// v1.1 탭 구조가 실제 화면에서 의도대로 동작하는지 확인한다.
///
/// 표면별 차이(게시 버튼 노출, 작성 타입 선택지)는 뷰 조건부 렌더링이라
/// 단위 테스트로 잡히지 않는다. 실제로 그려진 화면에서 확인해야 한다.
final class TabStructureUITests: XCTestCase {

    private enum Label {
        static let memoTab = "메모"
        static let widgetTab = "위젯"
        static let publish = "잠금화면에 올리기"
        static let unpublish = "잠금화면에서 내리기"
        static let newMemo = "새 메모 작성"
        static let skipOnboarding = "건너뛰기"
        static let displayMode = "표시 모드"
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // 방향이 남아 있으면 레이아웃이 달라져 요소를 못 찾는 경우가 생긴다.
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launch()
        skipOnboardingIfNeeded()
        dismissMigrationNoticeIfNeeded()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - 탭 전환

    func test_tabBar_shouldOfferMemoAndWidgetTabs() {
        XCTAssertTrue(app.tabBars.buttons[Label.memoTab].exists)
        XCTAssertTrue(app.tabBars.buttons[Label.widgetTab].exists)
    }

    func test_tabs_shouldSwitchBetweenSurfaces() {
        selectTab(Label.widgetTab)
        XCTAssertTrue(app.staticTexts["D-day"].waitForExistence(timeout: 3))

        selectTab(Label.memoTab)
        XCTAssertTrue(app.staticTexts["일반"].waitForExistence(timeout: 3))
    }

    // MARK: - 잠금화면 게시 버튼 (#92)

    /// 위젯 탭은 위젯을 다루는 자리다. 여기서 잠금화면에 올리면 이름과 동작이 어긋난다.
    func test_widgetTab_shouldNotOfferLockScreenPublishing() {
        selectTab(Label.widgetTab)
        XCTAssertTrue(app.staticTexts["D-day"].waitForExistence(timeout: 3), "위젯 탭에 카드가 그려져야 한다")

        XCTAssertEqual(publishButtonCount(Label.publish), 0, "위젯 탭에 잠금화면 게시 버튼이 남아 있다")
    }

    func test_memoTab_shouldOfferLockScreenPublishing() {
        selectTab(Label.memoTab)
        XCTAssertTrue(app.staticTexts["일반"].waitForExistence(timeout: 3), "메모 탭에 카드가 그려져야 한다")

        let hasToggle = publishButtonCount(Label.publish) > 0 || publishButtonCount(Label.unpublish) > 0
        XCTAssertTrue(hasToggle, "메모 탭에는 잠금화면 게시 버튼이 있어야 한다")
    }

    // MARK: - 작성 타입 선택지 (#77)

    /// 메모 탭에서 D-day를 만들면 저장하는 순간 위젯 탭으로 넘어가 사라진 것처럼 보인다.
    func test_createFlow_inMemoTab_shouldNotOfferWidgetTypes() {
        selectTab(Label.memoTab)
        openNewMemo()

        XCTAssertTrue(app.buttons["일반"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["D-day"].exists, "메모 탭 작성 화면에 D-day가 노출된다")
        XCTAssertFalse(app.buttons["진행바"].exists, "메모 탭 작성 화면에 진행바가 노출된다")
    }

    func test_createFlow_inWidgetTab_shouldNotOfferMemoTypes() {
        selectTab(Label.widgetTab)
        openNewMemo()

        XCTAssertTrue(app.buttons["D-day"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["일반"].exists, "위젯 탭 작성 화면에 일반이 노출된다")
        XCTAssertFalse(app.buttons["체크리스트"].exists, "위젯 탭 작성 화면에 체크리스트가 노출된다")
    }

    // MARK: - 표시 모드 (LA 전용 설정)

    /// 위젯은 사용자가 뺄 때까지 사라지지 않는다. 소멸 시점을 정하는 설정이 있으면
    /// 곧 없어진다는 뜻으로 읽혀 위젯이 약속하는 것과 반대가 된다.
    func test_createFlow_inWidgetTab_shouldNotOfferDisplayMode() {
        selectTab(Label.widgetTab)
        openNewMemo()

        XCTAssertTrue(app.buttons["D-day"].waitForExistence(timeout: 3), "작성 화면이 열려야 한다")
        XCTAssertFalse(app.staticTexts[Label.displayMode].exists, "위젯 작성 화면에 표시 모드가 노출된다")
    }

    func test_createFlow_inMemoTab_shouldOfferDisplayMode() {
        selectTab(Label.memoTab)
        openNewMemo()

        XCTAssertTrue(app.staticTexts[Label.displayMode].waitForExistence(timeout: 3),
                      "메모 작성 화면에는 표시 모드가 있어야 한다")
    }

    // MARK: - Helpers

    /// 같은 레이블의 버튼이 여러 개일 수 있어 쿼리로 센다.
    private func publishButtonCount(_ label: String) -> Int {
        app.buttons.matching(identifier: label).count
    }

    private func selectTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(label) 탭을 찾을 수 없다")
        tab.tap()
    }

    private func openNewMemo() {
        let button = app.buttons[Label.newMemo]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "새 메모 버튼을 찾을 수 없다")
        button.tap()
    }

    /// 신규 설치 상태로 실행되면 온보딩이 먼저 뜬다.
    private func skipOnboardingIfNeeded() {
        let skip = app.buttons[Label.skipOnboarding]
        guard skip.waitForExistence(timeout: 3) else { return }
        skip.tap()
    }

    /// 기존 사용자 상태로 실행되면 탭 분리 안내가 먼저 뜬다.
    private func dismissMigrationNoticeIfNeeded() {
        let later = app.buttons["나중에"]
        guard later.waitForExistence(timeout: 2) else { return }
        later.tap()
    }
}
