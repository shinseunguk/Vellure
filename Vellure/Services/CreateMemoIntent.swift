import AppIntents
import SwiftData

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
            if let activityId = LiveActivityService.shared.start(memo: memo) {
                memo.activityId = activityId
            }
        }

        try? context.save()

        let message = String(format: String(localized: "intent.createMemo.success"), content)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
