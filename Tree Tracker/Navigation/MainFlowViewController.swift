import UIKit
import Photos

final class MainFlowViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let liveUpload = LiveUploadViewController(viewModel: LiveUploadViewModel(navigation: self))
        let uploadQueue = UploadListFlowViewController()
        let allTrees = NavigationViewController(rootViewController: TableListViewController(viewModel: TreesViewModel()))

        viewControllers = [liveUpload, uploadQueue, allTrees]

        liveUpload.tabBarItem = UITabBarItem(title: "", image: .cameraIcon, selectedImage: .cameraIcon)
        uploadQueue.tabBarItem = UITabBarItem(title: "", image: .uploadIcon, selectedImage: .uploadIcon)
        allTrees.tabBarItem = UITabBarItem(title: "", image: .listIcon, selectedImage: .listIcon)

        selectedIndex = 1
    }
}

extension MainFlowViewController: LiveUploadNavigating {
    func triggerAskForDetailsAndStoreFlow(assets: [PHAsset], completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let controller = (self.selectedViewController as? UINavigationController)?.visibleViewController ?? self.selectedViewController?.presentedViewController ?? self.selectedViewController
            controller?.present(TreeDetailsFlowViewController(assets: assets, completion: completion), animated: true, completion: nil)
        }
    }
}
