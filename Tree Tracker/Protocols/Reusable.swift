import UIKit

protocol Reusable {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        return "\(self)"
    }
}

extension UITableView {
    func register(cell: (Reusable & UITableViewCell).Type) {
        register(cell, forCellReuseIdentifier: cell.reuseIdentifier)
    }

    func register(cells: [(Reusable & UITableViewCell).Type]) {
        cells.forEach(register(cell:))
    }

    func register(cells: (Reusable & UITableViewCell).Type...) {
        cells.forEach(register(cell:))
    }

    func register<SectionHeader: Reusable & UITableViewHeaderFooterView>(sectionHeader: SectionHeader.Type) {
        register(sectionHeader, forHeaderFooterViewReuseIdentifier: sectionHeader.reuseIdentifier)
    }

    func dequeue<CellType: Reusable>(cell: CellType.Type, indexPath: IndexPath) -> CellType {
        return dequeueReusableCell(withIdentifier: cell.reuseIdentifier, for: indexPath) as! CellType
    }

    func dequeue<SectionHeader: Reusable>(sectionHeader: SectionHeader.Type) -> SectionHeader {
        return dequeueReusableHeaderFooterView(withIdentifier: sectionHeader.reuseIdentifier) as! SectionHeader
    }
}

extension UICollectionView {
    func register(cell: (Reusable & UICollectionViewCell).Type) {
        register(cell, forCellWithReuseIdentifier: cell.reuseIdentifier)
    }

    func register(cells: [(Reusable & UICollectionViewCell).Type]) {
        cells.forEach(register(cell:))
    }

    func register(cells: (Reusable & UICollectionViewCell).Type...) {
        cells.forEach(register(cell:))
    }

    func register<SectionHeader: Reusable & UICollectionReusableView>(sectionHeader: SectionHeader.Type) {
        register(sectionHeader, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionHeader.reuseIdentifier)
    }

    func dequeue<CellType: Reusable>(cell: CellType.Type, indexPath: IndexPath) -> CellType {
        return dequeueReusableCell(withReuseIdentifier: cell.reuseIdentifier, for: indexPath) as! CellType
    }

    func dequeue<CellType: Reusable>(cell: CellType.Type, row: Int) -> CellType {
        let indexPath = IndexPath(row: row, section: 0)
        return self.dequeue(cell: cell, indexPath: indexPath)
    }

    func dequeue<SectionHeader: Reusable>(sectionHeader: SectionHeader.Type, indexPath: IndexPath) -> SectionHeader {
        return dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionHeader.reuseIdentifier, for: indexPath) as! SectionHeader
    }
}
