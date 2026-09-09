#if DEBUG
import Foundation
import VellureCore
import VellureData

/// UI 테스트가 기대하는 화면 상태를 실행 시점에 만들어준다.
///
/// 테스트가 기기에 남아 있던 데이터에 의존하면, 빈 상태로 시작하는 CI에서 무너진다.
/// 실제로 그렇게 깨진 적이 있어 시드를 실행 인자로 주입한다.
public enum UITestSeed {
    public static let launchArgument = "-uiTestSeed"

    public static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// 두 표면 모두에 메모를 채운다. 한쪽이 비면 그 탭의 테스트가 의미를 잃는다.
    ///
    /// 온보딩과 구조 변경 안내도 함께 넘긴다. 이걸 화면에서 탭으로 넘기게 두면
    /// 러너가 느릴 때 첫 화면이 늦게 떠 탭바를 찾지 못한 채 테스트가 무너진다.
    @MainActor
    public static func apply(to repository: MemoRepository) {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        StructureNotice.markAsCurrent()

        for memo in repository.fetchAll() {
            repository.delete(memo)
        }

        repository.create(renderType: .plain, content: "주차 위치 B2 구역 47")
        repository.create(
            renderType: .checklist,
            content: "외출 준비물",
            items: [ChecklistItem(title: "지갑"), ChecklistItem(title: "충전기")]
        )
        repository.create(
            renderType: .countdown,
            content: "팀 회의 시작",
            targetDate: Calendar.current.date(byAdding: .hour, value: 2, to: .now)
        )
        repository.create(
            renderType: .dday,
            content: "제주도 여행",
            targetDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
            colorTag: "gold"
        )
        repository.create(
            renderType: .progress,
            content: "러닝 30일 챌린지",
            progress: 0.62,
            colorTag: "blue"
        )
    }
}
#endif
