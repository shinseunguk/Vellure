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
                        ContentView()
                            .environment(repository)
                    } else {
                        OnboardingView {
                            hasCompletedOnboarding = true
                        }
                        .environment(repository)
                        // 신규 설치는 온보딩에서 현재 구조를 그대로 본다.
                        // 여기서 표식을 남기지 않으면 온보딩 직후 홈에서
                        // "구조가 바뀌었다"는 안내가 신규 사용자에게 뜬다.
                        .onAppear { StructureNotice.markAsCurrent() }
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
            .storageNoticeAlert()
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
