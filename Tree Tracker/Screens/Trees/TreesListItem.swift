import UIKit

enum TreesListItem: Identifiable, Hashable {
    case tree(id: String, image: UIImage?, name: String, species: String?, supervisor: String?, tapAction: Action?)

    var id: String {
        switch self {
        case let .tree(id, _, _, _, _, _): return id
        }
    }
}
