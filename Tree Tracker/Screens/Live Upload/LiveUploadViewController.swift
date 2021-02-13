import UIKit
import AVFoundation
import CoreLocation
import Combine

final class LiveUploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    let viewModel: LiveUploadViewModel

    private var currentCameraView: UIImagePickerController?

    private lazy var actionButton: RoundedTappableButton = {
        let button = RoundedTappableButton()
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private var photoSessionCancel: (() -> Void)?
    private var photoSessionCompletion: ((Result<UIImage, Error>) -> Void)?
    private var oservables = Set<AnyCancellable>()

    init(viewModel: LiveUploadViewModel) {
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

        currentCameraView?.startVideoCapture()
        viewModel.onAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        currentCameraView?.stopVideoCapture()
    }

    private func setup(viewModel: LiveUploadViewModel) {
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

    private func removeCurrentCameraView() {
        currentCameraView?.view.removeFromSuperview()
        currentCameraView = nil
    }

    private func presentPhotoSession(cancel: @escaping () -> Void, completion: @escaping (Result<UIImage, Error>) -> Void) {
        removeCurrentCameraView()
        photoSessionCancel = cancel
        photoSessionCompletion = completion
        actionButton.isHidden = true

        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.image"]
        picker.sourceType = .camera
        picker.delegate = self
        add(picker, to: view, insets: .some(top: 0.0, bottom: 16.0))

        self.currentCameraView = picker
    }

    private func present(actionButton model: ButtonModel) {
        removeCurrentCameraView()
        actionButton.set(model: model)
        actionButton.isHidden = false
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
