import Foundation

struct ChecklistItem: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var done: Bool

    init(id: UUID = UUID(), title: String, done: Bool = false) {
        self.id = id
        self.title = title
        self.done = done
    }
}
