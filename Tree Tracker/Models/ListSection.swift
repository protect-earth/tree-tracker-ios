import Foundation

enum ListSection<ListItem: Hashable>: Hashable, Identifiable {
    case titled(String, [ListItem])
    case untitled(id: String = "untitled", [ListItem])

    var items: [ListItem] {
        switch self {
        case let .titled(_, rows):
            return rows
        case let .untitled(_, rows):
            return rows
        }
    }

    var id: String {
        switch self {
        case let .titled(id, _), let .untitled(id, _):
            return id
        }
    }

    func section(with items: [ListItem]) -> ListSection {
        switch self {
        case let .titled(title, _):
            return .titled(title, items)
        case let .untitled(id, _):
            return .untitled(id: id, items)
        }
    }
}
