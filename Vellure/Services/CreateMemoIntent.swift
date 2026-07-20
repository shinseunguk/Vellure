import AppIntents
import SwiftData

struct CreateMemoIntent: AppIntent {
    static var title: LocalizedStringResource = "메모 추가"
    static var description: IntentDescription = "벨루어에 새 메모를 추가합니다"

    @Parameter(title: "내용")
    var content: String

    @Parameter(title: "잠금화면에 표시", default: true)
    var startActivity: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$content) 메모 추가") {
            \.$startActivity
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([Memo.self])
        let config = ModelConfiguration(
            "Vellure",
            schema: schema,
            groupContainer: .identifier(Constants.appGroupId)
        )

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return .result(dialog: "메모 생성에 실패했습니다")
        }

        let context = ModelContext(container)
        let memo = Memo(content: content)
        context.insert(memo)

        if startActivity {
            if let activityId = LiveActivityService.shared.start(memo: memo) {
                memo.activityId = activityId
            }
        }

        try? context.save()

        return .result(dialog: "메모가 추가되었습니다: \(content)")
    }
}
