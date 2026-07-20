import Foundation

@Observable
final class ProManager {
    static let shared = ProManager()

    private let key = "vellure_is_pro"

    var isPro: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    private init() {}
}
