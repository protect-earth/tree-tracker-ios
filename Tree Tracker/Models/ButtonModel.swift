import Foundation
import UIKit

struct ButtonModel {
    enum Title {
        case loading
        case text(String)
    }

    let title: Title
    let action: (() -> Void)?
    let isEnabled: Bool
}

struct NavigationBarButtonModel {
    enum Title {
        case system(UIBarButtonItem.SystemItem)
        case text(String)
    }

    let title: Title
    let action: (() -> Void)?
    let isEnabled: Bool
}
