import UIKit
import PhotosUI

final class FlowViewController: UINavigationController, TreesNavigating, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private lazy var defaults = CurrentEnvironment.defaults

    init() {
        super.init(nibName: nil, bundle: nil)

        let rootViewController = TreesViewController(viewModel: TreesViewModel(navigation: self))
        navigationBar.prefersLargeTitles = true
        viewControllers = [rootViewController]
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func triggerAddTreesFlow(completion: @escaping ([Tree]) -> Void) {
        if #available(iOS 14, *) {
            presentNewPhotoPicker()
        } else {
            presentLegacyPhotoPicker()
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
        picker.dismiss(animated: true, completion: nil)

        guard let asset = info[.phAsset] as? PHAsset else { return }

        askForDetailsAndStore(assets: [asset])
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    private func askForDetailsAndStore(assets: [PHAsset]) {
        print("ask for details of assets: \(assets)")
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
        askForDetailsAndStore(assets: assets)

        picker.dismiss(animated: true, completion: nil)
    }
}
