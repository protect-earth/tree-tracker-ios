import Foundation
import GRDB

struct RemoteTree: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable {
    let id: Int
    let supervisor: String
    let species: String
    let site: String
    let notes: String?
    var coordinates: String?
    let what3words: String?
    var imageUrl: String?
    var thumbnailUrl: String?
    let imageMd5: String?
    var createDate: Date?
    var uploadDate: Date?

    // Because these are not accessible when synthesized by Swift, please do not remove it
    enum CodingKeys: String, CodingKey {
        case id
        case supervisor
        case species
        case site
        case notes
        case coordinates
        case what3words
        case imageUrl
        case thumbnailUrl
        case imageMd5
        case createDate
        case uploadDate
    }
}
