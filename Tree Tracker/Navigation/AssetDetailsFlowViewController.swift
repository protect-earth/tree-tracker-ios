import UIKit
import Photos

final class TreeDetailsFlowViewController: NavigationViewController {
    private var site: Site?
    private var supervisor: Supervisor?
    private var completion: ((Bool) -> Void)?

    init(assets: [PHAsset], site: Site?, supervisor: Supervisor?, completion: ((Bool) -> Void)?) {
        super.init()

        self.site = site
        self.supervisor = supervisor
        self.completion = completion
        setup()
        askForDetailsAndStore(assets: assets)
    }

    init(tree: LocalTree, site: Site?, supervisor: Supervisor?, completion: ((Bool) -> Void)?) {
        super.init()

        self.site = site
        self.supervisor = supervisor
        self.completion = completion
        setup()
        editDetails(of: tree)
    }

    private func setup() {
        prefersLargeTitles = false
    }

    private func askForDetailsAndStore(assets: [PHAsset]) {
        guard !assets.isEmpty else { return }

        let viewModel = AddLocalTreeViewModel(assets: assets, staticSupervisor: supervisor, staticSite: site, navigation: self)
        let viewController = TreeDetailsViewController(viewModel: viewModel)
        self.viewControllers = [viewController]
    }

    private func editDetails(of tree: LocalTree) {
        let viewModel = EditLocalTreeViewModel(tree: tree, navigation: self)
        let viewController = TreeDetailsViewController(viewModel: viewModel)
        self.viewControllers = [viewController]
    }
}

extension TreeDetailsFlowViewController: TreeDetailsNavigating {
    func detailsFilledSuccessfully() {
        dismiss(animated: true) { [weak self] in
            self?.completion?(true)
        }
    }

    func abandonedFillingTheDetails() {
        dismiss(animated: true) { [weak self] in
            self?.completion?(false)
        }
    }
}
