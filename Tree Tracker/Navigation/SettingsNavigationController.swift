import Foundation
import UIKit
import Resolver

/*
 Navigation controller for Settings - acts as a container for child view controllers
 */
class SettingsNavigationController: UINavigationController {
    
    @Injected var settingsContoller: SettingsController
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [settingsContoller]
        self.title = "Settings"
    }
    
    // boilerplate
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    
    
}
