import Foundation
import OSLog
import SwiftData

/// 앱과 위젯 확장이 공유하는 단일 ModelContainer.
/// 한 프로세스 안에서 컨테이너가 중복 생성되어 스토어가 충돌하는 것을 방지한다.
///
/// 컨테이너를 열지 못해도 앱이 죽지 않도록 단계적으로 물러선다.
/// 저장소 손상·마이그레이션 실패로 앱이 아예 켜지지 않는 상황을 만들지 않기 위해서다.
public enum AppModelContainer {

    /// 컨테이너가 어떤 경로로 열렸는지. 뷰가 사용자에게 상황을 알리는 데 쓴다.
    public enum Status: Equatable {
        /// App Group 공유 저장소로 정상 생성 (위젯과 데이터를 공유한다)
        case shared
        /// App Group을 쓸 수 없어 앱 전용 저장소로 생성.
        /// 서명이 없는 CI 등에서 발생하며, 이때 위젯은 데이터를 볼 수 없다.
        case localOnly
        /// 저장소를 전혀 열 수 없어 메모리 컨테이너로 폴백.
        /// 이번 실행에서 만든 내용은 저장되지 않는다.
        case inMemory(reason: String)

        /// 사용자에게 알려야 하는 상태인지
        public var needsUserNotice: Bool {
            if case .inMemory = self { return true }
            return false
        }
    }

    public private(set) static var status: Status = .shared

    private static let logger = Logger(subsystem: "dev.ukseung.Vellure", category: "ModelContainer")

    public static let shared: ModelContainer = {
        let schema = Schema([Memo.self])

        // App Group을 사용할 수 있는 환경에서만 공유 컨테이너를 쓴다.
        // 서명이 없는 CI 등에서는 엔타이틀먼트가 없어 nil이 반환된다.
        let isAppGroupAvailable = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupId) != nil

        if isAppGroupAvailable {
            let config = ModelConfiguration(
                "Vellure",
                schema: schema,
                groupContainer: .identifier(Constants.appGroupId)
            )
            if let container = try? ModelContainer(for: schema, configurations: [config]) {
                status = .shared
                return container
            }
            logger.error("App Group 컨테이너 생성 실패 — 앱 전용 저장소로 재시도")
        }

        let localConfig = ModelConfiguration("Vellure", schema: schema)
        if let container = try? ModelContainer(for: schema, configurations: [localConfig]) {
            status = .localOnly
            return container
        }

        // 마지막 수단: 저장은 못 해도 앱은 켜지게 한다.
        return makeInMemoryContainer(schema: schema)
    }()

    /// 디스크 저장소를 열 수 없을 때 쓰는 임시 컨테이너.
    /// 여기서도 실패하면 더 물러설 곳이 없다.
    private static func makeInMemoryContainer(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration("Vellure", schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            status = .inMemory(reason: "저장소를 열 수 없음")
            logger.fault("디스크 컨테이너 생성 실패 — 메모리 컨테이너로 폴백")
            return container
        } catch {
            status = .inMemory(reason: String(describing: type(of: error)))
            logger.fault("메모리 컨테이너 생성도 실패")
            // ModelContainer는 옵셔널을 돌려줄 수 없고 여기서 더 물러설 방법이 없다.
            // 스키마 자체가 잘못된 개발 단계 오류이므로 그대로 중단한다.
            fatalError("ModelContainer를 어떤 방식으로도 생성할 수 없습니다: \(error)")
        }
    }
}
