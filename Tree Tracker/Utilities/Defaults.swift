import Foundation

struct DefaultsKey<Type: Codable> {
    let key: String
}

extension DefaultsKey {
    static var supervisorId: DefaultsKey<String> { .init(key: "supervisorId") }
    static var speciesId: DefaultsKey<String> { .init(key: "speciesId") }
    static var siteId: DefaultsKey<String> { .init(key: "siteId") }
    static var recentSpecies: DefaultsKey<[RecentSpecies]> { .init(key: "recentSpecies") }
    
    enum Key: String {
        case supervisorId
        case speciesId
        case siteId
        case recentSpecies
    }
}

protocol DefaultsProviding {
    subscript<T: Codable>(_ key: DefaultsKey<T>) -> T? { get nonmutating set }
}

struct Defaults: DefaultsProviding {
    let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    subscript<T: Codable>(_ key: DefaultsKey<T>) -> T? {
        get {
            if T.self is String.Type {
                return userDefaults.string(forKey: key.key) as? T
            } else {
                return userDefaults.data(forKey: key.key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
            }
        }

        nonmutating set {
            if T.self is String.Type {
                userDefaults.set(newValue, forKey: key.key)
            } else {
                userDefaults.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: key.key)
            }
        }
    }
}
