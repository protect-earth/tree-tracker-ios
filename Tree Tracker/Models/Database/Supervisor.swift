import Foundation
import GRDB

struct Supervisor: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable {
    let id: String
    let name: String

    // Because these are not accessible when synthesized by Swift, please do not remove it
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
