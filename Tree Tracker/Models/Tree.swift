import Foundation
import GRDB

struct Tree: Codable, FetchableRecord, PersistableRecord, TableRecord {
    let supervisor: String
    let species: String
    let notes: String?
    var coordinates: String?
    var imageUrl: String?
    let imageMd5: String?
    let phImageId: String?
    var remoteId: Int?
    var uploadDate: Date?

    enum CodingKeys: String, CodingKey {
        case supervisor
        case species
        case notes
        case imageUrl
        case imageMd5
        case phImageId
        case remoteId
        case uploadDate
    }

    func toAirtableTree() -> AirtableTree {
        return AirtableTree(id: remoteId, supervisor: supervisor, species: species, notes: notes, coordinates: coordinates, imageUrl: imageUrl, imageMd5: imageMd5, uploadDate: uploadDate)
    }
}
