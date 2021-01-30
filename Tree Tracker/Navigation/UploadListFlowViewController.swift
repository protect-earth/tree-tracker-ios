import UIKit
import PhotosUI
import BSImagePicker

final class UploadListFlowViewController: NavigationViewController, UploadListNavigating, TreeDetailsNavigating, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let assetLocator = PHAssetLocator()
    private var saveTreesCompletion: (() -> Void)?

    override init() {
        super.init()

        let rootViewController = UploadListViewController(viewModel: UploadListViewModel(navigation: self))
        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = .white
        viewControllers = [rootViewController]
    }

    func triggerAddTreesFlow(completion: @escaping () -> Void) {
        saveTreesCompletion = completion
        askForPermissionsAndPresentPickerIfPossible()
    }

    func triggerFillDetailsFlow(phImageIds: [String], completion: @escaping () -> Void) {
        saveTreesCompletion = completion
        let assets = assetLocator.findAssets(for: phImageIds)
        askForDetailsAndStore(assets: assets)
    }

    func triggerEditDetailsFlow(tree: LocalTree, completion: @escaping () -> Void) {
        saveTreesCompletion = completion
        presentEdit(tree: tree)
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
                self.presentExternalPhotoPicker()
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
        
        let viewModel = AddLocalTreeViewModel(assets: assets, navigation: self)
        let viewController = TreeDetailsViewController(viewModel: viewModel)
        let navigationController = NavigationViewController(rootViewController: viewController, prefersLargeTitles: false)

        viewControllers.last?.present(navigationController, animated: true, completion: nil)
    }

    private func presentEdit(tree: LocalTree) {
        let viewModel = EditLocalTreeViewModel(tree: tree, navigation: self)
        let viewController = TreeDetailsViewController(viewModel: viewModel)
        let navigationController = NavigationViewController(rootViewController: viewController, prefersLargeTitles: false)

        viewControllers.last?.present(navigationController, animated: true, completion: nil)
    }


    func detailsFilledSuccessfully() {
        viewControllers.last?.presentedViewController?.dismiss(animated: true) { [weak self] in
            self?.saveTreesCompletion?()
        }
    }

    func abandonedFillingTheDetails() {
        viewControllers.last?.presentedViewController?.dismiss(animated: true) { [weak self] in
            self?.saveTreesCompletion?()
        }
    }
}

@available(iOS 14, *)
extension UploadListFlowViewController: PHPickerViewControllerDelegate {
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

extension UploadListFlowViewController {
    private func presentExternalPhotoPicker() {
        let imagePickerController = ImagePickerController()
        imagePickerController.settings.fetch.assets.supportedMediaTypes = [.image]
        presentImagePicker(imagePickerController, select: nil, deselect: nil, cancel: nil) { [weak self] assets in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.askForDetailsAndStore(assets: assets)
            }
        }
    }
}
