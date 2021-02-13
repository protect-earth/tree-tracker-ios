import UIKit

extension UIViewController {
    func add(_ child: UIViewController, to view: UIView, insets: UIEdgeInsets = .zero) {
        child.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
        child.view.pin(to: view, insets: insets)
    }
}
