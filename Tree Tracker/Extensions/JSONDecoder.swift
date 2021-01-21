import Foundation

extension JSONDecoder {
    static var _iso8601ms: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(._iso8601ms)

        return decoder
    }
}
