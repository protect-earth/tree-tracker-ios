import Foundation
import CoreLocation

struct ProtectEarthSite: Codable {
    let id: String
    let name: String
    let location: String
    let url: URL?
    let plantedTrees: Int
    // TODO: Do we want to handle coordinates?
//    let coordinates: CLLocationCoordinate2D
    
    func toSite() -> Site {
        return .init(id: id, name: name)
    }
}
