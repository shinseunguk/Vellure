import ActivityKit
import Foundation

public struct MemoAttributes: ActivityAttributes {
    public let memoId: String
    public let displayMode: String

    public init(memoId: String, displayMode: String) {
        self.memoId = memoId
        self.displayMode = displayMode
    }

    public struct ContentState: Codable, Hashable {
        public var renderType: String
        public var content: String
        public var items: [LiveChecklistItem]?
        public var targetDate: Date?
        public var progress: Double?
        public var font: String
        public var colorTag: String
        public var updatedAt: Date

        public init(
            renderType: String,
            content: String,
            items: [LiveChecklistItem]? = nil,
            targetDate: Date? = nil,
            progress: Double? = nil,
            font: String,
            colorTag: String,
            updatedAt: Date
        ) {
            self.renderType = renderType
            self.content = content
            self.items = items
            self.targetDate = targetDate
            self.progress = progress
            self.font = font
            self.colorTag = colorTag
            self.updatedAt = updatedAt
        }
    }
}

public struct LiveChecklistItem: Codable, Hashable, Identifiable {
    public var id: String
    public var title: String
    public var done: Bool

    public init(id: String, title: String, done: Bool) {
        self.id = id
        self.title = title
        self.done = done
    }
}
