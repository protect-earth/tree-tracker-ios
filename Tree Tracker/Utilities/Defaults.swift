import Foundation

struct Defaults {
    enum Key: String {
        case supervisor
        case species
        case notes
    }

    private let userDefaults = UserDefaults.standard

    subscript(_ key: Key) -> String? {
        get {
            userDefaults.string(forKey: key.rawValue)
        }

        nonmutating set {
            userDefaults.set(newValue, forKey: key.rawValue)
        }
    }
}
