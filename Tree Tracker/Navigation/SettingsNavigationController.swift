import Foundation
import UIKit

class SettingsNavigationController: UINavigationController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let top = SettingsController(style: UITableView.Style.grouped)
        
        self.viewControllers = [top]
        
        self.title = "Settings"
    }
    
    // boilerplate
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    
    
}
