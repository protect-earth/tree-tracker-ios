import Foundation

struct AirtableSpecies: Decodable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "Name"
        case fields
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        let container = try root.nestedContainer(keyedBy: CodingKeys.self, forKey: .fields)

        id = try root.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }

    func toSpecies() -> Species {
        return .init(id: id, name: name)
    }
}
