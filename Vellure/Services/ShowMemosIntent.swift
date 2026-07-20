import AppIntents
import SwiftData

struct ShowMemosIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.showMemos.title"
    static var description: IntentDescription = "View memo list in Vellure"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([Memo.self])
        let config = ModelConfiguration(
            "Vellure",
            schema: schema,
            groupContainer: .identifier(Constants.appGroupId)
        )

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return .result(dialog: IntentDialog(stringLiteral: String(localized: "intent.showMemos.fail")))
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Memo>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        guard let memos = try? context.fetch(descriptor), !memos.isEmpty else {
            return .result(dialog: IntentDialog(stringLiteral: String(localized: "intent.showMemos.empty")))
        }

        let list = memos.prefix(5).map { "• \($0.content)" }.joined(separator: "\n")
        let suffix = memos.count > 5 ? "\n…+\(memos.count - 5)" : ""
        let message = String(format: String(localized: "intent.showMemos.result"), memos.count, list, suffix)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
