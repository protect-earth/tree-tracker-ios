import UIKit
import Combine

final class TreeDetailsViewController: UIViewController {
    let viewModel: TreeDetailsViewModel

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView
    }()

    private let textFieldsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins.left = 16.0
        stackView.layoutMargins.right = 16.0
        stackView.spacing = 8.0
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)

        return stackView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16.0
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
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        return imageView
    }()

    private let actionButton: TappableButton = {
        let button = RoundedTappableButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 18.0)

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
        stackView.addArrangedSubview(textFieldsStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16.0),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -100.0),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor),

            actionButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10.0),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            imageView.leadingAnchor.constraint(equalTo: imageViewWrapper.leadingAnchor, constant: 16.0),
            imageView.trailingAnchor.constraint(equalTo: imageViewWrapper.trailingAnchor, constant: -16.0),
            imageView.topAnchor.constraint(equalTo: imageViewWrapper.topAnchor),
            imageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height / 2.3),
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
                imageLoader?.loadHighQualityImage { image in
                    self?.imageView.image = image
                }
            }
            .store(in: &observables)

        viewModel.cancelButtonPublisher
            .sink { [weak self] cancelButton in
                let buttons = [cancelButton].compactMap { $0 }
                self?.update(leftNavigationButtons: buttons)
            }
            .store(in: &observables)

        viewModel.topRightNavigationButtonPublisher
            .sink { [weak self] button in
                let buttons = [button].compactMap { $0 }
                self?.update(rightNavigationButtons: buttons)
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

        viewModel.alertPublisher
            .sink { [weak self] alert in
                self?.present(alert: alert)
            }
            .store(in: &observables)
    }

    private func update(leftNavigationButtons buttons: [NavigationBarButtonModel]) {
        navigationItem.leftBarButtonItems = buttons.map(BarButtonItem.init)
    }

    private func update(rightNavigationButtons buttons: [NavigationBarButtonModel]) {
        navigationItem.rightBarButtonItems = buttons.map(BarButtonItem.init)
    }

    private func update(fields models: [TextFieldModel]) {
        let currentFieldsCount = textFieldsStackView.arrangedSubviews.count
        if currentFieldsCount != models.count {
            if currentFieldsCount < models.count {
                let fieldsToAdd = models.count - currentFieldsCount
                for _ in 0..<fieldsToAdd {
                    textFieldsStackView.addArrangedSubview(buildTextField())
                }
            } else {
                let fieldsToRemove = currentFieldsCount - models.count
                for _ in 0..<fieldsToRemove {
                    if let view = textFieldsStackView.arrangedSubviews.first(where: { $0 is TextField }) {
                        textFieldsStackView.removeArrangedSubview(view)
                    }
                }
            }
        }

        let textFields = textFieldsStackView.arrangedSubviews.compactMap { $0 as? TextField }
        for (textField, model) in zip(textFields, models) {
            textField.set(model: model)
        }
    }

    private func present(alert: AlertModel) {
        present(UIAlertController.from(model: alert), animated: true, completion: nil)
    }

    private func buildTextField() -> TextField {
        let textField = TextField()
        textField.textColor = .black
        textField.borderStyle = .roundedRect
        textField.heightAnchor.constraint(equalToConstant: 48.0).isActive = true

        return textField
    }
}
