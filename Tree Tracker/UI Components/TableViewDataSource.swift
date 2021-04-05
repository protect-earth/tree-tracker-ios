import UIKit

final class TableViewDataSource<ListItem: Hashable & Identifiable>: UITableViewDiffableDataSource<ListSection<ListItem>, ListItem>, UITableViewDelegate {
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
        self.data = data
        var snapshot = NSDiffableDataSourceSnapshot<ListSection<ListItem>, ListItem>()

        for section in data {
            let rows = section.items
            let sectionWithoutItems = section.section(with: [])
            snapshot.appendSections([sectionWithoutItems])
            snapshot.appendItems(rows, toSection: sectionWithoutItems)
        }

        apply(snapshot, animatingDifferences: animating)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = data[safe: section]?.title else { return nil }
        
        let label = UILabel()
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16.0, weight: .semibold)
        label.text = title
        
        let view = UIView()
        view.addSubview(label)
        
        label.pin(to: view, insets: .some(top: 8.0, bottom: 8.0))
        
        return view
    }
}
