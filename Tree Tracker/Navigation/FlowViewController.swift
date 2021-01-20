import UIKit
import PhotosUI

final class FlowViewController: UINavigationController, TreesNavigating, AskForDetailsAndStoreAssetsNavigating, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)

        let rootViewController = TreesViewController(viewModel: TreesViewModel(navigation: self))
        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = .white
        viewControllers = [rootViewController]
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func triggerAddTreesFlow(completion: @escaping ([Tree]) -> Void) {
        askForPermissionsAndPresentPickerIfPossible()
    }

    private func askForPermissionsAndPresentPickerIfPossible() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            presentPhotoPicker()
        default:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                switch status {
                case .authorized, .limited:
                    self?.presentPhotoPicker()
                default:
                    let errorAlert = UIAlertController.error("Tree Tracker doesn't have access to photo library, please update that in Settings in order to use the app to its full potential.")
                    self?.present(errorAlert, animated: true, completion: nil)
                }
            }
        }
    }

    private func presentPhotoPicker() {
        DispatchQueue.main.async {
            if #available(iOS 14, *) {
                self.presentNewPhotoPicker()
            } else {
                self.presentLegacyPhotoPicker()
            }
        }
    }

    private func presentLegacyPhotoPicker() {
        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.image"]
        picker.sourceType = .savedPhotosAlbum
        picker.delegate = self

        present(picker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            guard let asset = info[.phAsset] as? PHAsset else { return }

            self.askForDetailsAndStore(assets: [asset])
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    private func askForDetailsAndStore(assets: [PHAsset]) {
        guard !assets.isEmpty else { return }
        
        let viewModel = AskForDetailsAndStoreAssetsViewModel(assets: assets, navigation: self)
        let viewController = AskForDetailsAndStoreAssetsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)

        viewControllers.last?.present(navigationController, animated: true, completion: nil)
    }

    func detailsFilledSuccessfully() {
        viewControllers.last?.presentedViewController?.dismiss(animated: true, completion: nil)
    }

    func abandonedFillingTheDetails() {
        viewControllers.last?.presentedViewController?.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 14, *)
extension FlowViewController: PHPickerViewControllerDelegate {
    private func presentNewPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 0
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .overFullScreen

        present(picker, animated: true, completion: nil)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let identifiers = results.compactMap { $0.assetIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var assets = [PHAsset]()
        fetchResult.enumerateObjects { asset, index, stop in
            assets.append(asset)
        }

        picker.dismiss(animated: true) {
            self.askForDetailsAndStore(assets: assets)
        }
    }
}
