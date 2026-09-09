import Foundation
import VellureCore
import VellureData

@Observable
final class MemoEditViewModel {
    private let repository: MemoRepository
    private var existingMemo: Memo?
    /// 작성 화면을 연 탭의 표면. 타입 선택지를 이 표면으로 한정한다.
    let surface: Surface

    var content: String = ""
    var renderType: RenderType = .plain
    var displayMode: DisplayMode = .pinned
    var clearTrigger: ClearTrigger = .hours
    var clearAfterHours: Int = Memo.maxClearAfterHours
    var font: String = "default"
    var colorTag: String = "green"
    var targetDate: Date = MemoEditViewModel.defaultTargetDate()
    var checklistItems: [ChecklistItem] = []
    var progress: Double = 0.0

    var isEditing: Bool { existingMemo != nil }

    /// 목표일을 정하지 않았을 때 쓰는 기본값.
    static func defaultTargetDate(from now: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
    }

    /// 타입을 바꾸고 딸린 값들을 새 타입에 맞게 맞춘다.
    ///
    /// 지난 날짜를 고른 D-day에서 카운트다운으로 넘어가면 목표 시각이 이미 지나 있어
    /// 저장하자마자 완료된 카운트다운이 된다. 그때는 기본값으로 되돌린다.
    func selectType(_ type: RenderType) {
        renderType = type

        let available = ClearTrigger.available(for: type)
        if !available.contains(clearTrigger) {
            clearTrigger = available.first ?? .hours
        }

        if !type.allowsPastTarget, targetDate < .now {
            targetDate = Self.defaultTargetDate()
        }
    }

    /// 이 화면에서 고를 수 있는 타입.
    /// 표면을 넘나드는 변환은 막는다 — 저장하는 순간 메모가 다른 탭으로 사라져
    /// 사용자에게는 삭제된 것처럼 보인다.
    var availableTypes: [RenderType] { surface.renderTypes }

    init(repository: MemoRepository, memo: Memo? = nil, surface: Surface = .memo) {
        self.repository = repository
        // 기존 메모를 고칠 때는 그 메모가 속한 표면을 따른다.
        // 그래야 현재 타입이 선택지에서 빠지는 일이 없다.
        self.surface = memo?.renderType.surface ?? surface
        // 새 메모는 작성 화면을 연 탭의 표면을 따른다.
        // 메모 탭에서 + 를 눌렀는데 D-day가 기본으로 잡히면 저장 후 다른 탭으로 사라진다.
        self.renderType = self.surface.renderTypes.first ?? .plain
        self.clearTrigger = ClearTrigger.available(for: self.renderType).first ?? .hours

        if let memo {
            self.existingMemo = memo
            self.content = memo.content
            self.renderType = memo.renderType
            self.displayMode = memo.displayMode
            self.clearTrigger = memo.clearTrigger ?? ClearTrigger.available(for: memo.renderType).first ?? .hours
            self.clearAfterHours = min(memo.clearAfterHours, Memo.maxClearAfterHours)
            self.font = memo.font
            self.colorTag = memo.colorTag
            self.targetDate = memo.targetDate ?? self.targetDate
            self.checklistItems = memo.items ?? []
            self.progress = memo.progress ?? 0.0
        }
    }

    @discardableResult
    func addChecklistItem(title: String) -> ChecklistItem {
        let item = ChecklistItem(title: title)
        checklistItems.append(item)
        return item
    }

    func removeChecklistItem(at offsets: IndexSet) {
        checklistItems.remove(atOffsets: offsets)
    }

    func updateChecklistItemTitle(_ item: ChecklistItem, title: String) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        checklistItems[index].title = title
    }

    func removeChecklistItem(_ item: ChecklistItem) {
        checklistItems.removeAll { $0.id == item.id }
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        checklistItems[index].done.toggle()
        updateProgress()
    }

    /// 저장 가능 여부. 일반 메모만 본문이 필수이고,
    /// 나머지 타입은 본문을 선택값으로 둔다(타입 데이터로 의미가 성립).
    var canSave: Bool {
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch renderType {
        case .plain:
            return hasContent
        case .checklist:
            let hasItems = checklistItems.contains { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
            return hasContent || hasItems
        case .dday, .countdown, .progress:
            return true
        }
    }

    func save() -> Memo {
        let items: [ChecklistItem]? = renderType == .checklist
            ? checklistItems.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
            : nil
        let target: Date? = (renderType == .dday || renderType == .countdown) ? targetDate : nil
        let prog: Double? = renderType == .progress ? progress : nil
        let trigger: ClearTrigger? = displayMode == .autoClear ? clearTrigger : nil

        if let memo = existingMemo {
            repository.update(
                memo,
                content: content,
                renderType: renderType,
                items: items,
                targetDate: target,
                progress: prog,
                displayMode: displayMode,
                clearTrigger: trigger,
                clearAfterHours: clearAfterHours,
                font: font,
                colorTag: colorTag
            )

            if let activityId = memo.activityId {
                Task {
                    await LiveActivityService.shared.update(activityId: activityId, memo: memo)
                }
            }

            return memo
        } else {
            return repository.create(
                renderType: renderType,
                content: content,
                items: items,
                targetDate: target,
                progress: prog,
                displayMode: displayMode,
                clearTrigger: trigger,
                clearAfterHours: clearAfterHours,
                font: font,
                colorTag: colorTag
            )
        }
    }

    private func updateProgress() {
        guard !checklistItems.isEmpty else {
            progress = 0.0
            return
        }
        let done = checklistItems.filter(\.done).count
        progress = Double(done) / Double(checklistItems.count)
    }
}
