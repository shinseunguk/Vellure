import AppIntents
import SwiftData

struct ShowMemosIntent: AppIntent {
    static var title: LocalizedStringResource = "메모 목록 보기"
    static var description: IntentDescription = "벨루어의 메모 목록을 보여줍니다"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([Memo.self])
        let config = ModelConfiguration(
            "Vellure",
            schema: schema,
            groupContainer: .identifier(Constants.appGroupId)
        )

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return .result(dialog: "메모를 불러올 수 없습니다")
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Memo>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        guard let memos = try? context.fetch(descriptor), !memos.isEmpty else {
            return .result(dialog: "저장된 메모가 없습니다")
        }

        let list = memos.prefix(5).map { "• \($0.content)" }.joined(separator: "\n")
        let suffix = memos.count > 5 ? "\n외 \(memos.count - 5)개" : ""
        return .result(dialog: "메모 \(memos.count)개:\n\(list)\(suffix)")
    }
}
