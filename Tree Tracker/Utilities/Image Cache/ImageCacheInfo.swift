import Foundation
import GRDB

struct ImageCacheInfo: Codable, FetchableRecord, PersistableRecord, TableRecord {
    let url: String
    let imageData: Data
    let imageCost: Int64
    
    enum CodingKeys: String, CodingKey {
        case url
        case imageData
        case imageCost
    }
}
