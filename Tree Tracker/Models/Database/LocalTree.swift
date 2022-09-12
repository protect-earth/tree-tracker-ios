import Foundation
import GRDB

struct LocalTree: Codable, FetchableRecord, PersistableRecord, TableRecord {
    let treeId: String
    let phImageId: String
    var createDate: Date?
    var supervisor: String
    var species: String
    var site: String
    var coordinates: String?
    var imageMd5: String?

    // Because these are not accessible when synthesized by Swift, please do not remove it
    enum CodingKeys: String, CodingKey {
        case treeId
        case phImageId
        case createDate
        case supervisor
        case species
        case site
        case coordinates
        case imageMd5
    }
}
