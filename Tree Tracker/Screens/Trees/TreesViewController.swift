import UIKit
import PhotosUI
import Combine

final class TreesViewController: UIViewController {
    let viewModel: TreesViewModel

    private lazy var layout: GridCollectionViewLayout = {
        let layout = GridCollectionViewLayout(columns: 4)
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true

        return collectionView
    }()

    private var observables = Set<AnyCancellable>()
    private lazy var dataSource = buildDataSource()

    init(viewModel: TreesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        nonViewDependentSetup(viewModel: viewModel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(named: "PrimaryColor")

        collectionView.dataSource = dataSource

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(viewModel: viewModel)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let isLandscape = view.frame.width > view.frame.height
        let columns = isLandscape ? 10 : 4

        if layout.columns != columns {
            layout.columns = columns
            collectionView.alwaysBounceVertical = isLandscape
            collectionView.alwaysBounceHorizontal = !isLandscape
            layout.invalidateLayout()
        }
    }

    private func nonViewDependentSetup(viewModel: TreesViewModel) {
        viewModel.$title
            .sink { [weak self] title in
                self?.title = title
            }
            .store(in: &observables)
    }

    private func setup(viewModel: TreesViewModel) {
        viewModel.$data
            .sink { [weak self] data in
                self?.dataSource.update(data: data)
            }
            .store(in: &observables)

        viewModel.$navigationButtons
            .sink { [weak self] navigationButtons in
                self?.update(navigationButtons: navigationButtons)
            }
            .store(in: &observables)

        viewModel.loadData()
    }

    private func update(navigationButtons: [NavigationBarButtonModel]) {
        navigationItem.rightBarButtonItems = navigationButtons
            .map { button in
                return BarButtonItem(model: button)
            }
    }

    private func buildDataSource() -> CollectionViewDataSource<TreesListItem> {
        return CollectionViewDataSource(collectionView: collectionView, cellTypes: [TreeCollectionViewCell.self]) { collectionView, indexPath, model -> UICollectionViewCell? in
            switch model {
            case let .tree(_, imageLoader, progress, info, detail, tapAction):
                let cell = collectionView.dequeue(cell: TreeCollectionViewCell.self, indexPath: indexPath)
                cell.set(imageLoader: imageLoader, progress: progress, info: info, detail: detail, tapAction: tapAction)

                return cell
            }
        }
    }
}
