import Foundation

/// 홈 목록의 표시 상태 필터.
enum DisplayFilter: CaseIterable {
    case all
    case active
    case inactive

    var labelKey: String {
        switch self {
        case .all: "filter.display.all"
        case .active: "filter.display.active"
        case .inactive: "filter.display.inactive"
        }
    }
}
