import UIKit

class PortraitUITabBarController: UITabBarController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
