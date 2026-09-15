import Foundation

public extension RenderType {

    /// 목록·섹션 헤더에서 타입을 나타내는 SF Symbol 이름.
    var iconName: String {
        switch self {
        case .plain: "note.text"
        case .checklist: "checklist"
        case .dday: "calendar"
        case .countdown: "timer"
        case .progress: "chart.bar.fill"
        }
    }

    /// 사용자에게 보여줄 타입 이름.
    var displayName: String {
        switch self {
        case .plain: String(localized: "type.plain")
        case .checklist: String(localized: "type.checklist")
        case .dday: String(localized: "type.dday")
        case .countdown: String(localized: "type.countdown")
        case .progress: String(localized: "type.progress")
        }
    }
}
