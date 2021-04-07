import UIKit
import AVFoundation
import CoreLocation
import Combine

final class UploadSessionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    let viewModel: UploadSessionViewModel

    private lazy var actionButton: RoundedTappableButton = {
        let button = RoundedTappableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 18.0)

        return button
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
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.spacing = 16.0

        return stackView
    }()

    private var photoSessionCancel: (() -> Void)?
    private var photoSessionCompletion: ((Result<UIImage, Error>) -> Void)?
    private var observables = Set<AnyCancellable>()

    init(viewModel: UploadSessionViewModel) {
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

        view.addSubview(stackView)

        stackView.addArrangedSubview(textFieldsStackView)
        stackView.addArrangedSubview(actionButton)

        stackView.center(in: view)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(viewModel: viewModel)
        viewModel.onLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.onAppear()
    }

    private func setup(viewModel: UploadSessionViewModel) {
        viewModel.$state
            .sink { [weak self] state in
                switch state {
                case let .actionButton(button):
                    self?.present(actionButton: button)
                case let .takeAPicture(cancel, completion):
                    self?.presentPhotoSession(cancel: cancel, completion: completion)
                }
            }
            .store(in: &observables)

        viewModel.$fields
            .sink { [weak self] fields in
                self?.update(fields: fields)
            }
            .store(in: &observables)
        
        viewModel.$alert
            .sink { [weak self] alert in
                self?.present(alert: alert)
            }
            .store(in: &observables)
    }
    
    private func removeCurrentCameraViewIfNeeded(completion: @escaping () -> Void) {
        if presentedViewController is UIImagePickerController {
            dismiss(animated: true, completion: completion)
        } else {
            completion()
        }
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
    
    private func buildTextField() -> TextField {
        let textField = TextField()
        textField.textColor = .black
        textField.borderStyle = .roundedRect
        textField.widthAnchor.constraint(equalToConstant: 250.0).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 48.0).isActive = true

        return textField
    }

    private func presentPhotoSession(cancel: @escaping () -> Void, completion: @escaping (Result<UIImage, Error>) -> Void) {
        removeCurrentCameraViewIfNeeded { [weak self] in
            self?.photoSessionCancel = cancel
            self?.photoSessionCompletion = completion

            let picker = RotatingUIImagePickerController()
            picker.modalPresentationStyle = .overCurrentContext
            picker.mediaTypes = ["public.image"]
            picker.sourceType = .camera
            picker.delegate = self
            self?.present(picker, animated: true, completion: nil)
        }
    }

    private func present(actionButton model: ButtonModel) {
        removeCurrentCameraViewIfNeeded { [weak self] in
            self?.actionButton.set(model: model)
        }
    }

    private func present(alert: AlertModel) {
        present(UIAlertController.from(model: alert), animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        photoSessionCancel?()
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = (info[.originalImage] as? UIImage) ?? (info[.editedImage] as? UIImage) else {
            photoSessionCompletion?(.failure(NSError(domain: "", code: 0, userInfo: nil)))
            return
        }

        picker.stopVideoCapture()
        photoSessionCompletion?(.success(image))
    }
}
