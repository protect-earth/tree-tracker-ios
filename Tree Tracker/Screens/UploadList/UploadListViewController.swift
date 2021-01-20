import UIKit
import PhotosUI
import Combine

final class UploadListViewController: UIViewController {
    let viewModel: UploadListViewModel

    private lazy var layout: UICollectionViewLayout = {
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

    private let actionButton: TappableButton = {
        let button = RoundedTappableButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private var observables = Set<AnyCancellable>()
    private lazy var dataSource = buildDataSource()

    init(viewModel: UploadListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10.0),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(viewModel: viewModel)
    }

    private func setup(viewModel: UploadListViewModel) {
        viewModel.$title
            .sink { [weak self] title in
                self?.title = title
            }
            .store(in: &observables)

        viewModel.$syncButton
            .sink { [weak self] button in
                guard let button = button else { return }

                self?.actionButton.set(model: button)
            }
            .store(in: &observables)

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
            case let .tree(_, imageLoader, info, detail, tapAction):
                let cell = collectionView.dequeue(cell: TreeCollectionViewCell.self, indexPath: indexPath)
                cell.set(imageLoader: imageLoader, info: info, detail: detail, tapAction: tapAction)

                return cell
            }
        }
    }
}
