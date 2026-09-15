import Foundation

/// Live Activity를 띄우지 못한 이유.
/// 실패를 조용히 삼키지 않고 호출부까지 전달해 사용자에게 안내하기 위한 타입이다.
///
/// 사용자에게 보여줄 문구는 현지화가 필요하므로 Presentation 계층이 정한다.
/// 여기서는 원인 구분과 로그용 코드만 다룬다.
public enum LiveActivityError: Error, Equatable {
    /// 설정에서 실시간 현황(Live Activities)이 꺼져 있음
    case notEnabled
    /// 시스템이 허용하는 동시 실행 개수를 넘음
    case tooManyActivities
    /// 전달하려는 상태 데이터가 시스템 상한(4KB)을 넘음
    case contentTooLarge
    /// 잠금화면에 올릴 수 없는 타입. 디데이·달성률은 위젯으로 보여준다.
    case unsupportedType
    /// 그 밖의 실패. 원인 문자열을 함께 보관한다.
    case unknown(String)

    /// 로그용 축약 코드. 민감정보를 담지 않는다.
    public var diagnosticCode: String {
        switch self {
        case .notEnabled: "notEnabled"
        case .tooManyActivities: "tooManyActivities"
        case .contentTooLarge: "contentTooLarge"
        case .unsupportedType: "unsupportedType"
        case .unknown(let reason): "unknown(\(reason))"
        }
    }
}
