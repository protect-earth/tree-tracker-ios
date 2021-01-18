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
