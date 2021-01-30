import Foundation

struct Defaults {
    enum Key: String {
        case supervisorId
        case speciesId
        case siteId
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
