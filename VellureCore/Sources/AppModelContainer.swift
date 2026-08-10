import Foundation
import SwiftData

/// 앱과 위젯 확장이 공유하는 단일 ModelContainer.
/// 한 프로세스 안에서 컨테이너가 중복 생성되어 스토어가 충돌하는 것을 방지한다.
public enum AppModelContainer {
    public static let shared: ModelContainer = {
        let schema = Schema([Memo.self])
        let config = ModelConfiguration(
            "Vellure",
            schema: schema,
            groupContainer: .identifier(Constants.appGroupId)
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }()
}
