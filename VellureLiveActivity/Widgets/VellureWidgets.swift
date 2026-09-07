import SwiftUI
import VellureCore
import WidgetKit

/// 잠금화면 위젯. 시계 위·아래 칸에 디데이와 달성률을 담는다.
///
/// 잠금화면은 칸 크기가 고정이라 목록을 넣을 수 없다.
/// 여러 개를 보려면 위젯을 여러 개 배치하고 각각 다른 메모를 지정한다.
struct VellureLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WidgetKind.lockScreen,
            intent: SelectMemoIntent.self,
            provider: MemoWidgetProvider()
        ) { entry in
            MemoWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("widget.lockScreen.name")
        .description("widget.lockScreen.description")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

/// 홈화면 위젯.
/// small은 지정한 메모 하나를, medium은 위젯 탭 정렬 순서대로 여러 건을 보여준다.
struct VellureHomeScreenWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WidgetKind.homeScreen,
            intent: SelectMemoIntent.self,
            provider: MemoWidgetProvider()
        ) { entry in
            MemoWidgetView(entry: entry)
                // iOS 17부터 위젯은 배경을 컨테이너에 선언해야 한다. 빠뜨리면 렌더링되지 않는다.
                .containerBackground(Theme.cardBackground, for: .widget)
        }
        .configurationDisplayName("widget.homeScreen.name")
        .description("widget.homeScreen.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// 위젯 종류 식별자. 타임라인 갱신 요청에서도 같은 값을 쓴다.
enum WidgetKind {
    static let lockScreen = "VellureLockScreenWidget"
    static let homeScreen = "VellureHomeScreenWidget"
}

#if DEBUG
#Preview("잠금화면 · 사각", as: .accessoryRectangular) {
    VellureLockScreenWidget()
} timeline: {
    MemoWidgetEntry.placeholder()
    MemoWidgetEntry.placeholder(.progress)
}

#Preview("홈화면 · small", as: .systemSmall) {
    VellureHomeScreenWidget()
} timeline: {
    MemoWidgetEntry.placeholder()
    MemoWidgetEntry.placeholder(.progress)
}

#Preview("홈화면 · medium", as: .systemMedium) {
    VellureHomeScreenWidget()
} timeline: {
    MemoWidgetEntry.placeholder()
}
#endif
