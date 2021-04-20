import Foundation
import GRDB

struct Species: Codable, Equatable, Identifiable, FetchableRecord, PersistableRecord, TableRecord {
    let id: String
    let name: String

    // Because these are not accessible when synthesized by Swift, please do not remove it
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
