import UIKit
import Combine

final class TreeDetailsViewController: UIViewController {
    let viewModel: TreeDetailsViewModel

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)

        return stackView
    }()

    private lazy var imageViewWrapper: UIView = {
        let view = UIView()
        view.addSubview(imageView)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .vertical)

        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()

    private let actionButton: TappableButton = {
        let button = RoundedTappableButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private var observables = Set<AnyCancellable>()

    init(viewModel: TreeDetailsViewModel) {
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

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(actionButton)

        stackView.addArrangedSubview(imageViewWrapper)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -100.0),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor),

            actionButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10.0),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            imageView.centerXAnchor.constraint(equalTo: imageViewWrapper.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: imageViewWrapper.topAnchor),
            imageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height / 2.0),
            imageView.bottomAnchor.constraint(equalTo: imageViewWrapper.bottomAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(viewModel: viewModel)
    }

    private func setup(viewModel: TreeDetailsViewModel) {
        viewModel.titlePublisher
            .sink { [weak self] title in
                self?.title = title
            }
            .store(in: &observables)

        viewModel.imageLoaderPublisher
            .sink { [weak self] imageLoader in
                imageLoader?.loadThumbnail { image in
                    self?.imageView.image = image
                }
            }
            .store(in: &observables)

        viewModel.cancelButtonPublisher
            .sink { [weak self] cancelButton in
                let buttons = [cancelButton].compactMap { $0 }
                self?.update(navigationButtons: buttons)
            }
            .store(in: &observables)

        viewModel.fieldsPublisher
            .sink { [weak self] fields in
                self?.update(fields: fields)
            }
            .store(in: &observables)

        viewModel.saveButtonPublisher
            .sink { [weak self] button in
                guard let button = button else { return }

                self?.actionButton.set(model: button)
            }
            .store(in: &observables)
    }

    private func update(navigationButtons: [NavigationBarButtonModel]) {
        navigationItem.leftBarButtonItems = navigationButtons
            .map { button in
                return BarButtonItem(model: button)
            }
    }

    private func update(fields: [TextFieldModel]) {
        let currentFieldsCount = stackView.arrangedSubviews.filter({ $0 is TextField }).count
        if currentFieldsCount != fields.count {
            if currentFieldsCount < fields.count {
                let fieldsToAdd = fields.count - currentFieldsCount
                for _ in 0..<fieldsToAdd {
                    stackView.addArrangedSubview(buildTextField())
                }
            } else {
                let fieldsToRemove = currentFieldsCount - fields.count
                for _ in 0..<fieldsToRemove {
                    if let view = stackView.arrangedSubviews.first(where: { $0 is TextField }) {
                        stackView.removeArrangedSubview(view)
                    }
                }
            }
        }

        let textFields = stackView.arrangedSubviews.compactMap { $0 as? TextField }
        for (textField, field) in zip(textFields, fields) {
            textField.set(model: field)
        }
    }

    private func buildTextField() -> TextField {
        let textField = TextField()
        textField.textColor = .black

        return textField
    }
}
