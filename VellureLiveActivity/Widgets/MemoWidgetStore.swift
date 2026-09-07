import Foundation
import SwiftData
import VellureCore

/// 위젯이 App Group 공유 저장소에서 메모를 읽는 통로.
///
/// 앱과 같은 `AppModelContainer`를 쓴다. 위젯은 짧게 살아나 타임라인만 만들고 끝나므로
/// Repository를 두지 않고 필요한 조회만 직접 한다.
enum MemoWidgetStore {

    /// 위젯 표면에 속한 메모를 정렬 순서대로 돌려준다.
    ///
    /// `renderType.surface`는 계산 프로퍼티라 `#Predicate`에 넣을 수 없다.
    /// 메모 수가 많지 않으므로 정렬만 저장소에 맡기고 표면 판정은 메모리에서 한다.
    static func widgetMemos() -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        let context = ModelContext(AppModelContainer.shared)
        let memos = (try? context.fetch(descriptor)) ?? []
        return memos.filter { $0.renderType.surface == .widget }
    }

    /// id로 한 건을 찾는다. 위젯이 지정한 메모가 지워졌으면 nil이다.
    static func memo(id: UUID) -> Memo? {
        let descriptor = FetchDescriptor<Memo>(predicate: #Predicate { $0.id == id })
        let context = ModelContext(AppModelContainer.shared)
        return try? context.fetch(descriptor).first
    }
}
