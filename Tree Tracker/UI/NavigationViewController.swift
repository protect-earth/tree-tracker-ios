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

    private func setup() {
        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = .white
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
