import Foundation

extension JSONEncoder {
    static var _iso8601ms: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(._iso8601ms)

        return encoder
    }
}
