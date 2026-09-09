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
        /// 화면 상단 제목. 탭 라벨과 글자가 같아 이름만 구분해 둔다.
        static let memoTitle = "메모"
        static let widgetTitle = "위젯"
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // 방향이 남아 있으면 레이아웃이 달라져 요소를 못 찾는 경우가 생긴다.
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        // 기기에 남은 데이터에 기대면 빈 상태로 시작하는 CI에서 무너진다.
        app.launchArguments = ["-uiTestSeed"]
        app.launch()
        dismissStorageNoticeIfNeeded()
        skipOnboardingIfNeeded()
        dismissMigrationNoticeIfNeeded()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - 탭 전환

    func test_tabBar_shouldOfferMemoAndWidgetTabs() {
        XCTAssertTrue(app.tabBars.buttons[Label.memoTab].waitForExistence(timeout: 20))
        XCTAssertTrue(app.tabBars.buttons[Label.widgetTab].exists)
    }

    func test_tabs_shouldSwitchBetweenSurfaces() {
        // 화면 제목으로 판정한다. 목록 내용은 데이터에 따라 달라진다.
        selectTab(Label.widgetTab)
        XCTAssertTrue(app.staticTexts[Label.widgetTitle].waitForExistence(timeout: 3))

        selectTab(Label.memoTab)
        XCTAssertTrue(app.staticTexts[Label.memoTitle].waitForExistence(timeout: 3))
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

    /// CI 러너는 실행이 느려 첫 화면이 늦게 뜬다. 넉넉히 기다린다.
    private func selectTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        if !tab.waitForExistence(timeout: 20) {
            // 무엇이 떠 있는지 모르면 원인을 짐작만 하게 된다. 로그에 남긴다.
            print("=== APP STATE: \(app.state.rawValue) ===")
            print("=== UI HIERARCHY ===")
            print(app.debugDescription)
        }
        XCTAssertTrue(tab.exists, "\(label) 탭을 찾을 수 없다")
        tab.tap()
    }

    /// 헤더의 새 메모 버튼을 집는다.
    /// 빈 상태 화면에도 같은 라벨의 버튼이 있어, 첫 번째 것만 골라야 모호해지지 않는다.
    private func openNewMemo() {
        let buttons = app.buttons.matching(identifier: Label.newMemo)
        XCTAssertTrue(buttons.firstMatch.waitForExistence(timeout: 5), "새 메모 버튼을 찾을 수 없다")
        buttons.firstMatch.tap()
    }

    /// 서명 없이 빌드하면 App Group을 쓸 수 없어 저장소가 메모리로 폴백하고,
    /// 그 사실을 알리는 알럿이 화면을 덮는다. CI가 이 상태다.
    private func dismissStorageNoticeIfNeeded() {
        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 5) else { return }
        alert.buttons.firstMatch.tap()
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
