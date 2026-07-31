#if DEBUG
import Foundation
import SwiftData
import VellureCore
import VellureData

/// SwiftUI 프리뷰 전용 지원 유틸리티.
/// 인메모리 SwiftData 컨테이너와 샘플 데이터를 제공한다.
@MainActor
enum PreviewSupport {
    /// 인메모리 컨테이너와 여기에 연결된 Repository를 생성한다.
    /// - Parameter seeded: 샘플 메모를 미리 채울지 여부
    /// - Returns: (repository, container) 튜플. 생성 실패 시 nil
    static func makeRepository(seeded: Bool = true) -> (repository: MemoRepository, container: ModelContainer)? {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: Memo.self, configurations: config) else {
            return nil
        }

        let repository = MemoRepository(modelContext: container.mainContext)
        if seeded {
            seed(into: repository)
        }
        return (repository, container)
    }

    /// 단일 샘플 메모를 반환한다. (컨테이너에 삽입하지 않음)
    static func sampleMemo(
        renderType: RenderType = .checklist,
        content: String = "여행 준비물",
        activityId: String? = "preview-activity"
    ) -> Memo {
        Memo(
            renderType: renderType,
            content: content,
            items: [
                ChecklistItem(title: "여권", done: true),
                ChecklistItem(title: "충전기", done: false)
            ],
            targetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
            progress: 0.5,
            activityId: activityId
        )
    }

    private static func seed(into repository: MemoRepository) {
        repository.create(renderType: .plain, content: "장보기 - 우유, 계란, 빵")
        repository.create(
            renderType: .checklist,
            content: "여행 준비물",
            items: [
                ChecklistItem(title: "여권", done: true),
                ChecklistItem(title: "충전기", done: false)
            ]
        )
        repository.create(
            renderType: .dday,
            content: "프로젝트 마감",
            targetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
            colorTag: "blue"
        )
        repository.create(
            renderType: .progress,
            content: "운동 목표 달성률",
            progress: 0.7,
            colorTag: "orange"
        )
    }
}
#endif
