import UIKit

class NavigationViewController: UINavigationController {
    init() {
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        setup()
    }

    init(rootViewController: UIViewController, prefersLargeTitles: Bool) {
        super.init(rootViewController: rootViewController)

        setup(prefersLargeTitles: prefersLargeTitles)
    }

    private func setup(prefersLargeTitles: Bool = true) {
        navigationBar.prefersLargeTitles = prefersLargeTitles
        navigationBar.tintColor = prefersLargeTitles ? .white : .black
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
