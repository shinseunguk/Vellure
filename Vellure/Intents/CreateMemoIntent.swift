import AppIntents
import SwiftData
import VellureCore
import VellureData

struct CreateMemoIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.createMemo.title"
    static var description: IntentDescription = "Add a new memo to Vellure"

    @Parameter(title: "intent.createMemo.content")
    var content: String

    @Parameter(title: "intent.createMemo.startActivity", default: true)
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
            return .result(dialog: IntentDialog(stringLiteral: String(localized: "intent.createMemo.fail")))
        }

        let context = ModelContext(container)
        let memo = Memo(content: content)
        context.insert(memo)

        if startActivity {
            // 시리에서 만든 메모는 실패해도 메모 자체는 남긴다.
            // 실패 사유는 LiveActivityService가 로그로 남긴다.
            if let activityId = try? LiveActivityService.shared.start(memo: memo) {
                memo.activityId = activityId
                memo.activityStartedAt = Date()
            }
        }

        try? context.save()

        let message = String(format: String(localized: "intent.createMemo.success"), content)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
