import SwiftUI
import VellureCore

/// 앱의 루트 탭 컨테이너.
///
/// 메모를 수명에 맞는 표면으로 나눈다.
/// 잠금화면 메모(Live Activity)는 8시간이면 갱신이 멈추고, 위젯은 사라지지 않는다.
/// 두 성격을 한 목록에 섞으면 "표시 중" 같은 상태 개념이 한쪽에만 성립해 화면이 어긋난다.
public struct ContentView: View {
    @State private var selection: Surface = .memo
    @State private var showMigrationNotice = false

    /// 마지막으로 안내를 마친 구조 버전. v1.0에는 없던 키다.
    @AppStorage(StructureNotice.storageKey) private var lastSeenStructureVersion = ""

    public init() {}

    public var body: some View {
        TabView(selection: $selection) {
            HomeView(surface: .memo)
                .tabItem {
                    Label("tab.memo", systemImage: "note.text")
                }
                .tag(Surface.memo)

            HomeView(surface: .widget)
                .tabItem {
                    Label("tab.widget", systemImage: "square.grid.2x2")
                }
                .tag(Surface.widget)
        }
        .tint(Theme.accent)
        .fullScreenCover(isPresented: $showMigrationNotice) {
            MigrationNoticeView { selection = .widget }
        }
        .task { presentMigrationNoticeIfNeeded() }
    }

    /// v1.0에서 올라온 사용자에게만 탭 분리를 한 번 알린다.
    ///
    /// 신규 설치는 온보딩을 띄우는 시점에 이미 현재 버전이 찍히므로 여기 걸리지 않는다.
    private func presentMigrationNoticeIfNeeded() {
        guard lastSeenStructureVersion != StructureNotice.currentVersion else { return }

        let needsNotice = StructureNotice.needsNotice(lastSeenVersion: lastSeenStructureVersion)
        StructureNotice.markAsCurrent()
        guard needsNotice else { return }

        showMigrationNotice = true
    }
}
