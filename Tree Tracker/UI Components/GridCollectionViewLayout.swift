import UIKit

final class GridCollectionViewLayout: UICollectionViewLayout {
    var columnSpacing: CGFloat = 8
    var rowSpacing: CGFloat = 16
    var sectionSpacing: CGFloat = 32
    var columns: Int

    private var attributes = [UICollectionViewLayoutAttributes]()

    private var contentHeight: CGFloat = 0.0
    private var contentWidth: CGFloat = 0.0

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    init(columns: Int) {
        self.columns = columns
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        guard attributes.isEmpty, let collectionView = collectionView, collectionView.frame.width > 0.0, columns > 0, collectionView.numberOfSections > 0 else { return }

        contentWidth = collectionView.bounds.width
        contentHeight = 0.0

        let items = collectionView.numberOfItems(inSection: 0)
        let itemWidth = (contentWidth - CGFloat(columns - 1) * columnSpacing) / CGFloat(columns)
        let itemHeight = itemWidth

        contentWidth = 0.0
        for item in 0 ..< items {
            let indexPath = IndexPath(item: item, section: 0)
            let columnHeight = itemHeight + rowSpacing
            let xOffset = CGFloat(item % columns) * (itemWidth + columnSpacing)
            let yOffset = floor(CGFloat(item) / CGFloat(columns)) * columnHeight

            let frame = CGRect(x: xOffset, y: yOffset, width: itemWidth, height: itemHeight)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            self.attributes.append(attributes)

            contentWidth = max(contentWidth, frame.maxX)
            contentHeight = max(contentHeight, frame.maxY)
        }
    }

    override func invalidateLayout() {
        attributes = []
        super.invalidateLayout()
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributes[safe: indexPath.item]
    }
}
