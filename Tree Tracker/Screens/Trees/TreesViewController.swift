import UIKit
import PhotosUI
import GRDB
import Combine

final class TreesViewController: UIViewController {
    let viewModel: TreesViewModel

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        return tableView
    }()

    private let actionButton: TappableButton = {
        let button = TappableButton(type: .system)
        button.backgroundColor = UIColor(named: "SecondaryColor")
        button.layer.cornerRadius = 8.0
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor(named: "SecondaryColor")?.cgColor
        button.setTitleColor(.black, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 16.0, bottom: 10.0, right: 16.0)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private var observables = Set<AnyCancellable>()
    private lazy var dataSource = buildDataSource()

    init(viewModel: TreesViewModel) {
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

        tableView.dataSource = dataSource

        view.addSubview(tableView)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10.0),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(viewModel: viewModel)
    }

    private func setup(viewModel: TreesViewModel) {
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

    private func buildDataSource() -> TableViewDataSource<TreesListItem> {
        return TableViewDataSource(tableView: tableView, cellTypes: [TreeTableViewCell.self]) { tableView, indexPath, model -> UITableViewCell? in
            switch model {
            case let .tree(_, image, name, species, supervisor, tapAction):
                let cell = tableView.dequeue(cell: TreeTableViewCell.self, indexPath: indexPath)
                cell.set(image: image, name: name, species: species, supervisor: supervisor, tapAction: tapAction)

                return cell
            }
        }
    }
}
