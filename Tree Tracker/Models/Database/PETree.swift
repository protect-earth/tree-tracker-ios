import Foundation
import GRDB

struct PETree: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable {
    
    let id: String // uuid()
    let phImageId: String
    let supervisor: String
    let species: String
    let site: String
    let notes: String?
    var coordinates: String?
    var imageUrl: String?
    var imageMd5: String?
    var imageCreateDate: Date?
    var recordCreateDate: Date?
    var uploadDate: Date?
    var sentFromThisDevice: Bool = false

    // Because these are not accessible when synthesized by Swift, please do not remove it
    enum CodingKeys: String, CodingKey {
        case id
        case phImageId
        case supervisor
        case species
        case site
        case notes
        case coordinates
        case imageUrl
        case imageMd5
        case imageCreateDate
        case recordCreateDate
        case uploadDate
        case sentFromThisDevice
    }
    
    static func from(_ localTree: LocalTree) -> PETree {
        return PETree(id: UUID().uuidString,
                      phImageId: localTree.phImageId,
                      supervisor: localTree.supervisor,
                      species: localTree.species,
                      site: localTree.site,
                      notes: localTree.notes,
                      coordinates: localTree.coordinates,
                      imageMd5: localTree.imageMd5,
                      imageCreateDate: localTree.createDate)
    }
}
