import Foundation
import SwiftData

/// 앱과 위젯 확장이 공유하는 단일 ModelContainer.
/// 한 프로세스 안에서 컨테이너가 중복 생성되어 스토어가 충돌하는 것을 방지한다.
public enum AppModelContainer {
    public static let shared: ModelContainer = {
        let schema = Schema([Memo.self])

        // App Group을 사용할 수 있는 환경에서만 공유 컨테이너를 쓴다.
        // 서명이 없는 CI 등에서는 엔타이틀먼트가 없어 nil이 반환되며,
        // 이때 App Group을 강제로 요구하면 SwiftData가 fatalError로 크래시하므로
        // 로컬 컨테이너로 폴백한다.
        let isAppGroupAvailable = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupId) != nil

        let config = isAppGroupAvailable
            ? ModelConfiguration("Vellure", schema: schema, groupContainer: .identifier(Constants.appGroupId))
            : ModelConfiguration("Vellure", schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }()
}
