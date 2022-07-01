import Foundation

struct ProtectEarthSupervisor: Codable {
    let id: String
    let name: String
    
    func toSupervisor() -> Supervisor {
        return .init(id: id, name: name)
    }
}
