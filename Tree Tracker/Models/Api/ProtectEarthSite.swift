import Foundation
import CoreLocation

struct ProtectEarthSite: Codable {
    let id: String
    let name: String
    
    func toSite() -> Site {
        return .init(id: id, name: name)
    }
}
