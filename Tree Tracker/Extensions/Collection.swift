import Foundation

enum CollectionSortingOrder {
    case ascending
    case descending
}

extension Collection {
    subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }

    var isNotEmpty: Bool {
        return !isEmpty
    }

    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, order: CollectionSortingOrder) -> [Element] {
        return sorted(by: {
            switch order {
            case .ascending:
                return $0[keyPath: keyPath] <= $1[keyPath: keyPath]
            case .descending:
                return $0[keyPath: keyPath] >= $1[keyPath: keyPath]
            }
        })
    }
}
