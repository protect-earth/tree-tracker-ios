import Foundation
import GRDB

struct UploadedTree: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable {
    let id: String
    let phImageId: String
    var uploadDate: Date

    // Because these are not accessible when synthesized by Swift, please do not remove it
    enum CodingKeys: String, CodingKey {
        case id
        case phImageId
        case uploadDate
    }
    
    static func fromTree(_ tree: LocalTree) -> UploadedTree {
        return UploadedTree(id: tree.treeId,
                            phImageId: tree.phImageId,
                            uploadDate: Date())
    }
}
