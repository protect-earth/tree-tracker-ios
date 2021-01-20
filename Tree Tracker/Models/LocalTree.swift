import Foundation
import GRDB

struct LocalTree: Codable, FetchableRecord, PersistableRecord, TableRecord {
    let phImageId: String
    var createDate: Date?
    var supervisor: String
    var species: String
    var notes: String?
    var coordinates: String?
    var imageMd5: String?

    enum CodingKeys: String, CodingKey {
        case phImageId
        case createDate
        case supervisor
        case species
        case notes
        case coordinates
        case imageMd5
    }

    func toAirtableTree(imageUrl: String) -> AirtableTreeEncodable {
        return AirtableTreeEncodable(supervisor: supervisor, species: species, notes: notes, coordinates: coordinates, imageUrl: imageUrl, imageMd5: imageMd5, uploadDate: Date(), createDate: createDate)
    }
}
