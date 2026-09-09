import Foundation
import VellureCore
import WidgetKit

/// 위젯 한 칸이 그릴 내용.
/// SwiftData 모델을 그대로 넘기지 않는다. 타임라인 항목은 값 타입이어야 안전하다.
struct MemoWidgetEntry: TimelineEntry {
    let date: Date
    let memo: MemoSnapshot?
    /// medium 패밀리가 쓰는 목록. 위젯 탭 정렬 순서를 그대로 따른다.
    let listMemos: [MemoSnapshot]
    /// 사용자가 고른 메모가 지워졌는지. 조용히 다른 메모로 바꾸지 않고 안내를 띄운다.
    let isMissing: Bool

    static func placeholder(_ renderType: RenderType = .dday) -> Self {
        let sample = MemoSnapshot(
            content: renderType == .dday ? "제주도 여행" : "러닝 30일",
            renderType: renderType,
            targetDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
            progress: 0.62,
            colorTag: "gold"
        )
        let second = MemoSnapshot(
            content: "전역",
            renderType: .dday,
            targetDate: Calendar.current.date(byAdding: .day, value: 243, to: .now),
            progress: nil,
            colorTag: "blue"
        )
        // 목록 미리보기는 타입이 섞여야 실제 모습에 가깝다.
        let third = MemoSnapshot(
            content: "러닝 30일 챌린지",
            renderType: .progress,
            targetDate: nil,
            progress: 0.62,
            colorTag: "rose"
        )
        return Self(
            date: .now,
            memo: sample,
            listMemos: [sample, second, third],
            isMissing: false
        )
    }
}

/// 타임라인에 실어 보내는 메모의 사본.
struct MemoSnapshot {
    let content: String
    let renderType: RenderType
    let targetDate: Date?
    let progress: Double?
    let colorTag: String

    init(content: String, renderType: RenderType, targetDate: Date?, progress: Double?, colorTag: String) {
        self.content = content
        self.renderType = renderType
        self.targetDate = targetDate
        self.progress = progress
        self.colorTag = colorTag
    }

    init(memo: Memo) {
        self.init(
            content: memo.content,
            renderType: memo.renderType,
            targetDate: memo.targetDate,
            progress: memo.progress,
            colorTag: memo.colorTag
        )
    }
}

// MARK: - 표시 값

extension MemoSnapshot {

    /// 위젯에 보여줄 제목. 본문이 비어 있으면 타입 이름으로 대신한다.
    var title: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? renderType.displayName : trimmed
    }

    /// 타입을 대표하는 한 덩어리 값. 좁은 칸에서는 이것만 남긴다.
    var headlineValue: String {
        switch renderType {
        case .dday:
            guard let targetDate else { return "-" }
            return DDayFormatter.string(for: targetDate)
        case .progress:
            return "\(Int((progress ?? 0) * 100))%"
        default:
            return title
        }
    }
}
