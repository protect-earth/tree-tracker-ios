import UIKit
import Photos

final class MainFlowViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let liveUpload = UploadSessionViewController(viewModel: UploadSessionViewModel(navigation: self))
        let uploadQueue = UploadListFlowViewController()
        let settings = SettingsNavigationController()

        viewControllers = [liveUpload, uploadQueue, settings]

        liveUpload.tabBarItem = UITabBarItem(title: "Session", image: .cameraIcon, selectedImage: .cameraIcon)
        uploadQueue.tabBarItem = UITabBarItem(title: "Queue", image: .uploadIcon, selectedImage: .uploadIcon)
        settings.tabBarItem = UITabBarItem(title: "Settings", image: .settingsIcon, selectedImage: .settingsIcon)

        // Open on upload queue by default
        selectedIndex = 1
    }
}

extension MainFlowViewController: UploadSessionNavigating {
    func triggerAskForDetailsAndStoreFlow(assets: [PHAsset], site: Site?, supervisor: Supervisor?, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let controller = (self.selectedViewController as? UINavigationController)?.visibleViewController ?? self.selectedViewController?.presentedViewController ?? self.selectedViewController
            controller?.present(TreeDetailsFlowViewController(assets: assets, site: site, supervisor: supervisor, completion: completion), animated: true, completion: nil)
        }
    }
}
