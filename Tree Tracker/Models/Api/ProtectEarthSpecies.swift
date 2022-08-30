import Foundation

struct ProtectEarthSpecies: Codable {
    let id: String
    let name: String
    
    func toSpecies() -> Species {
        return .init(id: id, name: name)
    }
}
