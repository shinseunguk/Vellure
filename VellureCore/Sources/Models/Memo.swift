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

@Model
public final class Memo {
    public var id: UUID
    public var renderType: RenderType
    public var content: String
    public var items: [ChecklistItem]?
    public var targetDate: Date?
    public var progress: Double?
    public var displayMode: DisplayMode
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
        self.font = font
        self.colorTag = colorTag
        self.activityId = activityId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = sortOrder
    }
}
