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

    fileprivate func unsafeSorted<T: Comparable>(by keyPath: KeyPath<Element, T?>, order: CollectionSortingOrder) -> [Element] {
        return sorted(by: {
            switch order {
            case .ascending:
                return $0[keyPath: keyPath]! <= $1[keyPath: keyPath]!
            case .descending:
                return $0[keyPath: keyPath]! >= $1[keyPath: keyPath]!
            }
        })
    }
}

extension Array {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T?>, order: CollectionSortingOrder, fallback: KeyPath<Element, T>, fallbackOrder: CollectionSortingOrder) -> [Element] {
        guard count > 1 else { return self }
        
        var copy = self
        let fallbackFirstIndex = copy.partition { $0[keyPath: keyPath] == nil }
        let firstPart = copy[0...fallbackFirstIndex - 1].unsafeSorted(by: keyPath, order: order)
        let secondPart = copy[fallbackFirstIndex...].sorted(by: fallback, order: fallbackOrder)

        return firstPart + secondPart
    }

    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T?>, order: CollectionSortingOrder) -> [Element] {
        guard count > 1 else { return self }

        var copy = self
        let fallbackFirstIndex = copy.partition { $0[keyPath: keyPath] == nil }
        let firstPart = copy[0...fallbackFirstIndex - 1].unsafeSorted(by: keyPath, order: order)
        let secondPart = copy[fallbackFirstIndex...]

        return firstPart + secondPart
    }
}
