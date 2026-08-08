import Foundation
import SwiftData

enum RenderType: String, Codable, CaseIterable {
    case plain
    case checklist
    case dday
    case countdown
    case progress
}

enum DisplayMode: String, Codable, CaseIterable {
    case pinned
    case autoClear
}

enum ClearTrigger: String, Codable, CaseIterable {
    case target   // 목표 시각 도달 시
    case hours    // N시간 경과 후
    case done     // 체크 완료 시
    case full     // 100% 도달 시

    static func available(for type: RenderType) -> [ClearTrigger] {
        switch type {
        case .plain: [.hours]
        case .checklist: [.hours, .done]
        case .dday, .countdown: [.target, .hours]
        case .progress: [.hours, .full]
        }
    }
}

@Model
final class Memo {
    var id: UUID
    var renderType: RenderType
    var content: String
    var items: [ChecklistItem]?
    var targetDate: Date?
    var progress: Double?
    var displayMode: DisplayMode
    var clearTrigger: ClearTrigger?
    var clearAfterHours: Int = 12
    var font: String
    var colorTag: String
    var activityId: String?
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        renderType: RenderType = .plain,
        content: String = "",
        items: [ChecklistItem]? = nil,
        targetDate: Date? = nil,
        progress: Double? = nil,
        displayMode: DisplayMode = .pinned,
        clearTrigger: ClearTrigger? = nil,
        clearAfterHours: Int = 12,
        font: String = "default",
        colorTag: String = "green",
        activityId: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.renderType = renderType
        self.content = content
        self.items = items
        self.targetDate = targetDate
        self.progress = progress
        self.displayMode = displayMode
        self.clearTrigger = clearTrigger
        self.clearAfterHours = clearAfterHours
        self.font = font
        self.colorTag = colorTag
        self.activityId = activityId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = sortOrder
    }

    /// Live Activity는 iOS 정책상 활성화 후 최대 12시간(활성 8시간 + 소멸 4시간)이 지나면
    /// 앱 설정과 무관하게 시스템이 강제로 종료한다. 어떤 트리거를 고르든 이 시각을 넘길 수 없다.
    private static let systemMaxDuration: TimeInterval = 12 * 60 * 60

    var clearDate: Date? {
        let systemCap = updatedAt.addingTimeInterval(Memo.systemMaxDuration)
        switch displayMode {
        case .pinned:
            return systemCap
        case .autoClear:
            switch clearTrigger {
            case .target:
                guard let targetDate else { return systemCap }
                return min(targetDate, systemCap)
            case .hours, .none:
                let requested = updatedAt.addingTimeInterval(TimeInterval(clearAfterHours) * 3600)
                return min(requested, systemCap)
            case .done, .full:
                return systemCap
            }
        }
    }
}
