import Foundation

enum ListSection<ListItem: Hashable & Identifiable>: Hashable, Identifiable {
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
    
    var title: String? {
        switch self {
        case let .titled(title, _):
            return title
        case .untitled:
            return nil
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

    func section(replacing item: ListItem) -> ListSection {
        var newItems = items
        guard let index = newItems.firstIndex(where: { $0.id == item.id }) else {
            return self
        }

        newItems[index] = item
        
        switch self {
        case let .titled(title, _):
            return .titled(title, newItems)
        case let .untitled(id, _):
            return .untitled(id: id, newItems)
        }
    }
}
