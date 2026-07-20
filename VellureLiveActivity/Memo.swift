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

@Model
final class Memo {
    var id: UUID
    var renderType: RenderType
    var content: String
    var items: [ChecklistItem]?
    var targetDate: Date?
    var progress: Double?
    var displayMode: DisplayMode
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
