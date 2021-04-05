import UIKit
import Combine

protocol TableViewModel {
    var alertPublisher: DelayedPublished<AlertModel>.Publisher { get }
    var titlePublisher: Published<String>.Publisher { get }
    var actionButtonPublisher: Published<ButtonModel?>.Publisher { get }
    var rightNavigationButtonsPublisher: Published<[NavigationBarButtonModel]>.Publisher { get }
    var dataPublisher: Published<[ListSection<TableListItem>]>.Publisher { get }

    func onAppear()
}

final class TableViewController: UIViewController {
    let viewModel: TableViewModel

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        return tableView
    }()

    private let actionButton: TappableButton = {
        let button = RoundedTappableButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private var observables = Set<AnyCancellable>()
    private lazy var dataSource = buildDataSource()

    init(viewModel: TableViewModel) {
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

        tableView.dataSource = dataSource
        tableView.delegate = dataSource

        view.addSubview(tableView)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.onAppear()
    }

    private func nonViewDependentSetup(viewModel: TableViewModel) {
        viewModel.titlePublisher
            .sink { [weak self] title in
                self?.navigationItem.title = title
            }
            .store(in: &observables)
    }

    private func setup(viewModel: TableViewModel) {
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

    private func buildDataSource() -> TableViewDataSource<TableListItem> {
        return TableViewDataSource(tableView: tableView, cellTypes: [TextTableViewCell.self]) { tableView, indexPath, model -> UITableViewCell? in
            switch model {
            case let .text(_, text, tapAction):
                let cell = tableView.dequeue(cell: TextTableViewCell.self, indexPath: indexPath)
                cell.set(text: text, tapAction: tapAction)

                return cell
            }
        }
    }
}
