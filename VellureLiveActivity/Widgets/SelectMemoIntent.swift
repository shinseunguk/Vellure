import AppIntents
import WidgetKit

/// 위젯을 길게 눌러 어떤 메모를 보여줄지 고르는 설정.
struct SelectMemoIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.config.title"
    static var description = IntentDescription("widget.config.description")

    @Parameter(title: "widget.config.memo")
    var memo: MemoEntity?

    init() {}

    init(memo: MemoEntity?) {
        self.memo = memo
    }
}
