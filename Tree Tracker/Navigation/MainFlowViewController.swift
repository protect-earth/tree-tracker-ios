import UIKit
import Photos

final class MainFlowViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let liveUpload = UploadSessionViewController(viewModel: UploadSessionViewModel(navigation: self))
        let uploadQueue = UploadListFlowViewController()
        let uploadHistory = NavigationViewController(rootViewController: CollectionViewController(viewModel: UploadHistoryViewModel()))
        let entities = NavigationViewController(rootViewController: TableViewController(viewModel: EntitiesViewModel()))

        viewControllers = [liveUpload, uploadQueue, uploadHistory, entities]

        liveUpload.tabBarItem = UITabBarItem(title: "", image: .cameraIcon, selectedImage: .cameraIcon)
        uploadQueue.tabBarItem = UITabBarItem(title: "", image: .uploadIcon, selectedImage: .uploadIcon)
        uploadHistory.tabBarItem = UITabBarItem(title: "", image: .historyIcon, selectedImage: .historyIcon)
        entities.tabBarItem = UITabBarItem(title: "", image: .listIcon, selectedImage: .listIcon)

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
