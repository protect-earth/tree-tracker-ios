import UIKit

final class TableViewDataSource<ListItem: Hashable>: UITableViewDiffableDataSource<ListSection<ListItem>, ListItem>, UITableViewDelegate {

    private var data = [ListSection<ListItem>]()
    private var currentItems: [ListSection<ListItem>] {
         return snapshot().sectionIdentifiers.map { $0.section(with: snapshot().itemIdentifiers(inSection: $0)) }
     }

    convenience init(tableView: UITableView, cellTypes: [(UITableViewCell & Reusable).Type], customCellDequeue: ((UITableView, IndexPath, ListItem) -> UITableViewCell?)? = nil) {
         self.init(tableView: tableView) { tableView, indexPath, item in
             if let cell = customCellDequeue?(tableView, indexPath, item) {
                 return cell
             } else {
                 assertionFailure("Item \"\(item)\" is not implemented for Table View.")
                 return UITableViewCell()
             }
         }

        tableView.register(cells: cellTypes)
     }

    func update(data: [ListSection<ListItem>], animating: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<ListSection<ListItem>, ListItem>()

        for section in data {
            let rows = section.items
            let sectionWithoutItems = section.section(with: [])
            snapshot.appendSections([sectionWithoutItems])
            snapshot.appendItems(rows, toSection: sectionWithoutItems)
        }

        apply(snapshot, animatingDifferences: animating)
    }
}
