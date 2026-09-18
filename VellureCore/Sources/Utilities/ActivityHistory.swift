import Foundation

/// 잠금화면 카드가 언제 올라가고 언제 내려갔는지 남기는 기록.
///
/// 통합 로그(OSLog)는 케이블로 Mac에 연결해야 볼 수 있어, 정작 이상하다고 느낀
/// 순간에 확인할 수 없다. 앱 안에서 바로 볼 수 있어야 "8시간이 안 됐는데
/// 사라졌다" 같은 이야기를 사실과 대조할 수 있다.
public enum ActivityHistory {
    /// 확장에서도 남기므로 App Group 저장소를 쓴다.
    public static let storageKey = "activityHistory"
    /// 보관 건수. 최근 것만 보면 되고, 기록 자체가 커질 이유가 없다.
    public static let limit = 20

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: Constants.appGroupId) ?? .standard
    }

    public static func recent() -> [ActivityRecord] {
        guard let data = defaults.data(forKey: storageKey),
              let records = try? JSONDecoder().decode([ActivityRecord].self, from: data) else {
            return []
        }
        return records
    }

    /// 카드를 올린 기록을 남긴다.
    public static func recordStart(
        memoId: String,
        title: String,
        displayMode: String,
        startedAt: Date = Date()
    ) {
        var records = recent()
        records.insert(
            ActivityRecord(
                memoId: memoId,
                title: ActivityRecord.excerpt(title),
                displayMode: displayMode,
                startedAt: startedAt
            ),
            at: 0
        )
        save(Array(records.prefix(limit)))
    }

    /// 아직 끝나지 않은 가장 최근 기록에 종료를 적는다.
    /// 같은 메모를 여러 번 올렸을 수 있으므로 memoId로 찾는다.
    public static func recordEnd(memoId: String, reason: ActivityRecord.EndReason, at date: Date = Date()) {
        var records = recent()
        guard let index = records.firstIndex(where: { $0.memoId == memoId && $0.endedAt == nil }) else {
            return
        }
        records[index].endedAt = date
        records[index].reason = reason
        save(records)
    }

    public static func clear() {
        defaults.removeObject(forKey: storageKey)
    }

    private static func save(_ records: [ActivityRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

/// 카드 한 장의 수명.
public struct ActivityRecord: Codable, Identifiable, Sendable {
    /// 카드가 사라진 이유.
    public enum EndReason: String, Codable, Sendable {
        /// 사용자가 내렸다
        case user
        /// 표시 시간(8시간)이 지나 앱이 정리했다
        case expired
        /// 설정한 자동소멸 조건이 충족됐다
        case autoClear
        /// 앱이 내린 적 없는데 사라졌다 (재설치·재부팅·시스템 정리)
        case disappeared
    }

    public let id: UUID
    public let memoId: String
    /// 어떤 메모였는지 알아볼 만큼만. 전체 내용을 복사해 두지 않는다.
    public let title: String
    public let displayMode: String
    public let startedAt: Date
    public var endedAt: Date?
    public var reason: EndReason?

    public init(
        id: UUID = UUID(),
        memoId: String,
        title: String,
        displayMode: String,
        startedAt: Date,
        endedAt: Date? = nil,
        reason: EndReason? = nil
    ) {
        self.id = id
        self.memoId = memoId
        self.title = title
        self.displayMode = displayMode
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.reason = reason
    }

    /// 목록에 한 줄로 들어갈 만큼만 남긴다.
    public static func excerpt(_ text: String, limit: Int = 20) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)) + "…"
    }

    /// 화면에 떠 있던 시간(분).
    public var livedMinutes: Int {
        Int((endedAt ?? Date()).timeIntervalSince(startedAt) / 60)
    }

    /// 표시 상한(8시간)을 채우지 못하고 사라졌는지.
    public var endedEarly: Bool {
        guard let endedAt else { return false }
        return endedAt.timeIntervalSince(startedAt) < Memo.systemActiveDuration - 60
    }
}
