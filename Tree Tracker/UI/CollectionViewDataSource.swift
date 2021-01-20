import UIKit

final class CollectionViewDataSource<ListItem: Hashable>: UICollectionViewDiffableDataSource<ListSection<ListItem>, ListItem> {

    private var data = [ListSection<ListItem>]()
    private var currentItems: [ListSection<ListItem>] {
         return snapshot().sectionIdentifiers.map { $0.section(with: snapshot().itemIdentifiers(inSection: $0)) }
     }

    convenience init(collectionView: UICollectionView, cellTypes: [(UICollectionViewCell & Reusable).Type], customCellDequeue: ((UICollectionView, IndexPath, ListItem) -> UICollectionViewCell?)? = nil) {
         self.init(collectionView: collectionView) { collectionView, indexPath, item in
             if let cell = customCellDequeue?(collectionView, indexPath, item) {
                 return cell
             } else {
                 assertionFailure("Item \"\(item)\" is not implemented for Collection View.")
                 return UICollectionViewCell()
             }
         }

        collectionView.register(cells: cellTypes)
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
