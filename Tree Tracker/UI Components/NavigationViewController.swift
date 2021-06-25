import UIKit

class NavigationViewController: UINavigationController {
    var prefersLargeTitles: Bool {
        get { navigationBar.prefersLargeTitles }
        set {
            navigationBar.prefersLargeTitles = newValue
            navigationBar.tintColor = prefersLargeTitles ? .white : .black
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        prefersLargeTitles = false
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        prefersLargeTitles = false
    }

    init(rootViewController: UIViewController, prefersLargeTitles: Bool) {
        super.init(rootViewController: rootViewController)

        self.prefersLargeTitles = prefersLargeTitles
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
