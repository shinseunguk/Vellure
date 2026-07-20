import SwiftUI
import SwiftData

@main
struct VellureApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let container: ModelContainer
    private let repository: MemoRepository

    init() {
        let schema = Schema([Memo.self])
        let config = ModelConfiguration(
            "Vellure",
            schema: schema,
            groupContainer: .identifier(Constants.appGroupId)
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }

        repository = MemoRepository(modelContext: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
                    .environment(repository)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                LiveActivityService.shared.cleanupExpired(repository: repository)
            }
        }
    }
}
