import ActivityKit
import Foundation

struct MemoAttributes: ActivityAttributes {
    let memoId: String
    let displayMode: String

    struct ContentState: Codable, Hashable {
        var renderType: String
        var content: String
        var items: [LiveChecklistItem]?
        var targetDate: Date?
        var progress: Double?
        var font: String
        var colorTag: String
        var updatedAt: Date
        var clearDate: Date?
    }
}

struct LiveChecklistItem: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var done: Bool
}
