import Foundation

struct ProtectEarthUpload: Codable {
    var imageUrl: String
    var latitude: Double
    var longitude: Double
    var plantedAt: Date
    let supervisor: ProtectEarthIdentifier
    let site: ProtectEarthIdentifier
    let species: ProtectEarthIdentifier
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case latitude
        case longitude
        case plantedAt = "planted_at"
        case supervisor
        case site
        case species
    }
}
