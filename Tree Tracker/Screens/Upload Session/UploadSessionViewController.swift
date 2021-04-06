import UIKit
import AVFoundation
import CoreLocation
import Combine

final class UploadSessionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    let viewModel: UploadSessionViewModel

    private lazy var actionButton: RoundedTappableButton = {
        let button = RoundedTappableButton()
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private var photoSessionCancel: (() -> Void)?
    private var photoSessionCompletion: ((Result<UIImage, Error>) -> Void)?
    private var oservables = Set<AnyCancellable>()

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

        actionButton.isHidden = true
        view.addSubview(actionButton)
        actionButton.center(in: view)
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
            .store(in: &oservables)

        viewModel.$alert
            .sink { [weak self] alert in
                self?.present(alert: alert)
            }
            .store(in: &oservables)
    }
    
    private func removeCurrentCameraViewIfNeeded(completion: @escaping () -> Void) {
        if presentedViewController is UIImagePickerController {
            dismiss(animated: true, completion: completion)
        } else {
            completion()
        }
    }

    private func presentPhotoSession(cancel: @escaping () -> Void, completion: @escaping (Result<UIImage, Error>) -> Void) {
        removeCurrentCameraViewIfNeeded { [weak self] in
            self?.photoSessionCancel = cancel
            self?.photoSessionCompletion = completion
            self?.actionButton.isHidden = true

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
            self?.actionButton.isHidden = false
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
