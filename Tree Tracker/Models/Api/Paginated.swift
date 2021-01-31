import Foundation

struct Paginated<Model: Decodable>: Decodable {
    let offset: String?
    let records: [Model]
}
