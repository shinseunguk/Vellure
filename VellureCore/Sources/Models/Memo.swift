import Foundation
import SwiftData

public enum RenderType: String, Codable, CaseIterable {
    case plain
    case checklist
    case dday
    case countdown
    case progress
}

public enum DisplayMode: String, Codable, CaseIterable {
    case pinned
    case autoClear
}

public enum ClearTrigger: String, Codable, CaseIterable {
    case target   // 목표 시각 도달 시
    case hours    // N시간 경과 후
    case done     // 체크 완료 시
    case full     // 100% 도달 시

    public static func available(for type: RenderType) -> [ClearTrigger] {
        switch type {
        case .plain: [.hours]
        case .checklist: [.hours, .done]
        case .dday, .countdown: [.target, .hours]
        case .progress: [.hours, .full]
        }
    }
}

@Model
public final class Memo {
    public var id: UUID
    public var renderType: RenderType
    public var content: String
    public var items: [ChecklistItem]?
    public var targetDate: Date?
    public var progress: Double?
    public var displayMode: DisplayMode
    public var clearTrigger: ClearTrigger?
    public var clearAfterHours: Int = 12
    public var font: String
    public var colorTag: String
    public var activityId: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var sortOrder: Int

    public init(
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

    public var clearDate: Date? {
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
