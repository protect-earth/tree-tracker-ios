import Foundation
import UIKit

struct ButtonModel: Hashable {
    enum Title: Hashable {
        case loading
        case text(String)
    }

    let title: Title
    let action: (() -> Void)?
    let isEnabled: Bool

    static func == (lhs: ButtonModel, rhs: ButtonModel) -> Bool {
        return lhs.title == rhs.title && lhs.isEnabled == rhs.isEnabled
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(isEnabled)
    }
}

struct NavigationBarButtonModel: Hashable {
    enum Title: Hashable {
        case system(UIBarButtonItem.SystemItem)
        case text(String)
    }

    let title: Title
    let action: (() -> Void)?
    let isEnabled: Bool

    static func == (lhs: NavigationBarButtonModel, rhs: NavigationBarButtonModel) -> Bool {
        return lhs.title == rhs.title && lhs.isEnabled == rhs.isEnabled
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(isEnabled)
    }
}
