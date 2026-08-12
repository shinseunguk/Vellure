import SwiftUI
import SwiftData
import VellureCore
import VellureData
import VellurePresentation

@main
struct VellureApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var showSplash = true

    private let container: ModelContainer
    private let repository: MemoRepository

    init() {
        container = AppModelContainer.shared
        repository = MemoRepository(modelContext: container.mainContext)
    }

    private var selectedScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if hasCompletedOnboarding {
                        HomeView()
                            .environment(repository)
                    } else {
                        OnboardingView {
                            hasCompletedOnboarding = true
                        }
                        .environment(repository)
                    }
                }
                .preferredColorScheme(selectedScheme)

                if showSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.35)) {
                            showSplash = false
                        }
                    }
                    .preferredColorScheme(selectedScheme)
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .task {
                LiveActivityService.shared.startActivitySync(repository: repository)
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
