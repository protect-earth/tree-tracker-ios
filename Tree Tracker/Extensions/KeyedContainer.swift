import Foundation

extension KeyedDecodingContainer {
    func decodeSingleStringInArray(forKey key: Self.Key) throws -> String {
        var container = try nestedUnkeyedContainer(forKey: key)

        return try container.decode(String.self)
    }
}

extension KeyedEncodingContainer {
    mutating func encodeSingleStringInArray(_ value: String, forKey key: Self.Key) throws {
        var container = nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }
}
