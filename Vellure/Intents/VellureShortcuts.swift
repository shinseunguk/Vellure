import AppIntents

struct VellureShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateMemoIntent(),
            phrases: [
                "\(.applicationName)에 메모 추가",
                "\(.applicationName)에 메모 남겨줘",
                "\(.applicationName) 새 메모",
            ],
            shortTitle: "메모 추가",
            systemImageName: "note.text.badge.plus"
        )

        AppShortcut(
            intent: ShowMemosIntent(),
            phrases: [
                "\(.applicationName) 메모 보여줘",
                "\(.applicationName) 메모 목록",
            ],
            shortTitle: "메모 보기",
            systemImageName: "list.bullet"
        )
    }
}
