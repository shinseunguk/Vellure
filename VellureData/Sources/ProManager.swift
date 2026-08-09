import Foundation

@Observable
public final class ProManager {
    public static let shared = ProManager()

    private let key = "vellure_is_pro"

    public var isPro: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    private init() {}
}
