import Foundation

/// 홈 구조가 바뀌었을 때 기존 사용자에게만 한 번 안내하기 위한 표식.
///
/// 신규 설치는 온보딩에서 새 구조를 그대로 보므로 안내 대상이 아니다.
/// 온보딩을 띄우는 시점에 현재 버전을 찍어두어, 온보딩을 마치고 홈에 들어올 때
/// "구조가 바뀌었다"는 안내가 뜨지 않게 한다.
public enum StructureNotice {
    /// 탭 구조가 도입된 버전. 다음에 구조가 또 바뀌면 이 값을 올린다.
    public static let currentVersion = "1.1"
    public static let storageKey = "lastSeenStructureVersion"

    /// 이미 현재 구조를 아는 사용자로 기록한다.
    public static func markAsCurrent(defaults: UserDefaults = .standard) {
        defaults.set(currentVersion, forKey: storageKey)
    }

    /// 안내를 보여줘야 하는 사용자인지.
    /// 기록이 비어 있다는 것은 이 키가 없던 시절(v1.0)부터 쓰던 사용자라는 뜻이다.
    public static func needsNotice(lastSeenVersion: String) -> Bool {
        lastSeenVersion.isEmpty
    }
}
