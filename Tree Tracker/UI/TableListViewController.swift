import UIKit
import PhotosUI
import Combine

protocol TableListViewModel {
    var alertPublisher: DelayedPublished<AlertModel>.Publisher { get }
    var titlePublisher: Published<String>.Publisher { get }
    var actionButtonPublisher: Published<ButtonModel?>.Publisher { get }
    var rightNavigationButtonsPublisher: Published<[NavigationBarButtonModel]>.Publisher { get }
    var dataPublisher: Published<[ListSection<TreesListItem>]>.Publisher { get }

    func loadData()
}

final class TableListViewController: UIViewController {
    let viewModel: TableListViewModel

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

    init(viewModel: TableListViewModel) {
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

    private func nonViewDependentSetup(viewModel: TableListViewModel) {
        viewModel.titlePublisher
            .sink { [weak self] title in
                self?.navigationItem.title = title
            }
            .store(in: &observables)
    }

    private func setup(viewModel: TableListViewModel) {
        viewModel.actionButtonPublisher
            .sink { [weak self] model in
                if let model = model {
                    self?.actionButton.set(model: model)
                    self?.actionButton.isHidden = false
                } else {
                    self?.actionButton.isHidden = true
                }
            }
            .store(in: &observables)

        viewModel.dataPublisher
            .sink { [weak self] data in
                self?.dataSource.update(data: data)
            }
            .store(in: &observables)

        viewModel.rightNavigationButtonsPublisher
            .sink { [weak self] rightNavigationButtons in
                self?.update(rightNavigationButtons: rightNavigationButtons)
            }
            .store(in: &observables)

        viewModel.alertPublisher
            .sink { [weak self] alert in
                self?.present(alert: alert)
            }
            .store(in: &observables)

        viewModel.loadData()
    }

    private func update(rightNavigationButtons navigationButtons: [NavigationBarButtonModel]) {
        navigationItem.rightBarButtonItems = navigationButtons
            .map { button in
                return BarButtonItem(model: button)
            }
    }

    private func present(alert: AlertModel) {
        present(UIAlertController.from(model: alert), animated: true, completion: nil)
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
