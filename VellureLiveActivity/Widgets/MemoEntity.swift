import AppIntents
import Foundation
import SwiftData
import VellureCore

/// 위젯 설정에서 고를 수 있는 메모.
///
/// 잠금화면은 공간이 고정이라 목록을 담을 수 없다. 그래서 "위젯 하나가 메모 하나를 맡고,
/// 여러 개를 보려면 위젯을 여러 개 배치한다"는 구조를 택했다.
struct MemoEntity: AppEntity {
    let id: UUID
    let content: String
    let renderType: RenderType

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "widget.entity.memo")
    }

    static var defaultQuery = MemoEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        // 본문이 비어 있어도 목록에서 고를 수 있어야 하므로 타입 이름으로 대신한다.
        let title = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return DisplayRepresentation(
            title: "\(title.isEmpty ? renderType.displayName : title)",
            subtitle: "\(renderType.displayName)"
        )
    }

    init(id: UUID, content: String, renderType: RenderType) {
        self.id = id
        self.content = content
        self.renderType = renderType
    }

    init(memo: Memo) {
        self.init(id: memo.id, content: memo.content, renderType: memo.renderType)
    }
}

/// 위젯 설정 화면에 보여줄 메모 목록을 공급한다.
/// 위젯 표면(디데이·달성률)에 속한 메모만 후보로 올린다.
struct MemoEntityQuery: EntityQuery {

    func entities(for identifiers: [UUID]) async throws -> [MemoEntity] {
        let selected = Set(identifiers)
        return MemoWidgetStore.widgetMemos()
            .filter { selected.contains($0.id) }
            .map(MemoEntity.init)
    }

    func suggestedEntities() async throws -> [MemoEntity] {
        MemoWidgetStore.widgetMemos().map(MemoEntity.init)
    }

    /// 사용자가 아무것도 고르지 않았을 때 쓸 기본값.
    /// 위젯 탭 정렬의 첫 번째 메모를 보여줘, 추가 직후에도 빈 위젯이 되지 않게 한다.
    func defaultResult() async -> MemoEntity? {
        MemoWidgetStore.widgetMemos().first.map(MemoEntity.init)
    }
}
