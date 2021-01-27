import Foundation
import GRDB

struct Supervisor: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
