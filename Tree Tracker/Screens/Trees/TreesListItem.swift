import UIKit

enum TreesListItem: Identifiable, Hashable {
    case tree(id: String, imageLoader: AnyImageLoader?, info: String, detail: String?, tapAction: Action?)

    var id: String {
        switch self {
        case let .tree(id, _, _, _, _): return id
        }
    }
}
