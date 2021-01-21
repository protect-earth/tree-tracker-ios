import UIKit

final class MainFlowViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let upload = UploadListFlowViewController()

        let trees = NavigationViewController(rootViewController: TreesViewController(viewModel: TreesViewModel()))

        viewControllers = [upload, trees]

        upload.tabBarItem = UITabBarItem(title: "", image: .uploadIcon, selectedImage: .uploadIcon)
        trees.tabBarItem = UITabBarItem(title: "", image: .listIcon, selectedImage: .listIcon)
    }
}
