import Foundation
import SwiftData

public enum RenderType: String, Codable, CaseIterable {
    case plain
    case checklist
    case dday
    case countdown
    case progress

    /// 사용자가 Live Activity에서 직접 조작하는 타입(체크리스트·진행바).
    /// 상호작용형은 소멸 예약(.after) 대상에서 제외한다 — 예약 시 업데이트가 막히기 때문.
    public var isInteractive: Bool {
        switch self {
        case .checklist, .progress: true
        case .plain, .dday, .countdown: false
        }
    }

    /// 이 타입을 보여줄 표면.
    ///
    /// 디데이·달성률은 며칠에서 몇 달 단위로 지속돼 Live Activity의 8시간 수명과 맞지 않는다.
    /// 수명이 긴 타입은 사라지지 않는 위젯에 둔다.
    public var surface: Surface {
        switch self {
        case .dday, .progress: .widget
        case .plain, .checklist, .countdown: .memo
        }
    }
}

/// 메모를 보여주는 표면. 앱의 탭 구성도 이 값을 따른다.
public enum Surface: String, Codable, CaseIterable {
    /// Live Activity — 잠금화면에 띄웠다 내리는 하루 단위 메모
    case memo
    /// 위젯 — 사용자가 배치하면 사라지지 않는 장기 지속 메모
    case widget

    /// 이 표면에 속하는 메모 타입.
    public var renderTypes: [RenderType] {
        RenderType.allCases.filter { $0.surface == self }
    }
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

    public static func available(for type: RenderType) -> [Self] {
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
    /// 자동소멸까지의 시간(시간 단위). 상한은 `maxClearAfterHours`.
    public var clearAfterHours: Int = Memo.maxClearAfterHours
    /// 서체 태그. 현재 UI에서 선택지를 제공하지 않는다.
    /// iOS 시스템 폰트의 serif(New York)·rounded(SF Rounded)에 한글 글리프가 없어
    /// 한국어 메모에서는 아무 변화가 없었다. 한글 지원 폰트를 번들에 넣으면 되살린다.
    /// 필드를 지우면 SwiftData 스키마가 또 바뀌므로 값만 보존한다.
    public var font: String
    public var colorTag: String
    public var activityId: String?
    /// Live Activity를 실제로 띄운 시각.
    /// 소멸 시각은 메모를 마지막으로 고친 시각이 아니라 이 시각을 기준으로 삼는다.
    /// (체크박스를 토글할 때마다 `updatedAt`이 갱신돼 카운트다운이 되감기던 문제)
    public var activityStartedAt: Date?
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
        clearAfterHours: Int = Memo.maxClearAfterHours,
        font: String = "default",
        colorTag: String = "green",
        activityId: String? = nil,
        activityStartedAt: Date? = nil,
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
        self.activityStartedAt = activityStartedAt
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = sortOrder
    }

    /// Live Activity는 iOS 정책상 활성화 후 최대 12시간(활성 8시간 + 소멸 4시간)이 지나면
    /// 앱 설정과 무관하게 시스템이 강제로 종료한다. 어떤 트리거를 고르든 이 시각을 넘길 수 없다.
    public static let systemMaxDuration: TimeInterval = 12 * 60 * 60

    /// 사용자가 고를 수 있는 자동소멸 시간의 상한.
    /// 8시간이 지나면 갱신이 멈추므로 그보다 긴 값을 고르게 하면
    /// 설정과 실제 동작이 어긋난다.
    public static let maxClearAfterHours = 8

    /// Live Activity가 실제로 "동작"하는 시간.
    /// 8시간이 지나면 시스템이 활동을 종료해 다이나믹 아일랜드에서 즉시 사라지고,
    /// 잠금화면에는 최대 4시간 더 남지만 갱신은 멈춘다.
    /// 사용자에게 보여줄 남은 시간은 12시간이 아니라 이 값을 기준으로 해야 한다.
    /// 출처: Apple - Displaying live data with Live Activities
    public static let systemActiveDuration: TimeInterval = 8 * 60 * 60

    /// Live Activity에 카운트다운으로 노출할 소멸 시각.
    /// 사용자가 직접 시간을 지정한 경우에만 값을 돌려준다.
    /// - `.hours`: 사용자가 고른 N시간 → 노출
    /// - `.target`: 타입 콘텐츠(D-day·카운트다운)가 같은 시각을 이미 보여주므로 제외
    /// - `.done`/`.full`/`pinned`: 시간 기반 트리거가 아니므로 제외
    ///   (`pinned`의 12시간은 사용자 의도가 아니라 플랫폼 제약이다)
    public var userClearDate: Date? {
        guard displayMode == .autoClear, clearTrigger == .hours else { return nil }
        return clearDate
    }

    /// 소멸 시각 계산의 기준 시점.
    /// Live Activity가 떠 있으면 그 시작 시각을, 아니면 마지막 수정 시각을 쓴다.
    private var clearAnchor: Date { activityStartedAt ?? updatedAt }

    /// 화면에 표시할 만료 시각.
    /// 사용자가 지정한 소멸 시각과 시스템 활성 상한(8시간) 중 이른 쪽이다.
    /// - Parameter startedAt: 지금 막 띄우는 경우의 시작 시각.
    ///   저장된 `activityStartedAt`보다 우선한다.
    public func activeDeadline(startedAt: Date? = nil) -> Date? {
        let anchor = startedAt ?? clearAnchor
        let activeCap = anchor.addingTimeInterval(Self.systemActiveDuration)
        guard let clearDate else { return activeCap }
        return min(clearDate, activeCap)
    }

    public var clearDate: Date? {
        let systemCap = clearAnchor.addingTimeInterval(Self.systemMaxDuration)
        switch displayMode {
        case .pinned:
            return systemCap
        case .autoClear:
            switch clearTrigger {
            case .target:
                guard let targetDate else { return systemCap }
                return min(targetDate, systemCap)
            case .hours, .none:
                let requested = clearAnchor.addingTimeInterval(TimeInterval(clearAfterHours) * 3600)
                return min(requested, systemCap)
            case .done, .full:
                return systemCap
            }
        }
    }
}
