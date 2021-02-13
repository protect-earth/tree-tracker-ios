import Foundation

protocol UploadListNavigating: AnyObject {
    func triggerAddTreesFlow(completion: @escaping (Bool) -> Void)
    func triggerEditDetailsFlow(tree: LocalTree, completion: @escaping (Bool) -> Void)
}

final class UploadListViewModel: TableListViewModel {
    @DelayedPublished var alert: AlertModel
    @Published var title: String
    @Published var data: [ListSection<TreesListItem>]
    @Published var actionButton: ButtonModel?
    @Published var rightNavigationButtons: [NavigationBarButtonModel]

    var alertPublisher: DelayedPublished<AlertModel>.Publisher { $alert }
    var titlePublisher: Published<String>.Publisher { $title }
    var actionButtonPublisher: Published<ButtonModel?>.Publisher { $actionButton }
    var rightNavigationButtonsPublisher: Published<[NavigationBarButtonModel]>.Publisher { $rightNavigationButtons }
    var dataPublisher: Published<[ListSection<TreesListItem>]>.Publisher { $data }

    private var api: Api
    private var database: Database
    private var screenLockManager: ScreenLockManaging
    private var sites: [Site] = []
    private var species: [Species] = []
    private var supervisors: [Supervisor] = []
    private var currentUpload: Cancellable?
    private weak var navigation: UploadListNavigating?

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, screenLockManager: ScreenLockManaging = UIScreenLockManager(), navigation: UploadListNavigating) {
        self.title = ""
        self.api = api
        self.database = database
        self.screenLockManager = screenLockManager
        self.navigation = navigation
        self.data = []
        self.actionButton = nil
        self.rightNavigationButtons = []

        presentTitle(itemsCount: 0)
        presentUploadButton(isUploading: false)
        presentNavigationButtons(isUploading: false)
    }

    func onAppear() {
        refreshData()
    }

    private func refreshData() {
        fetchDatabaseContent { [weak self] in
            self?.presentTreesFromDatabase()
        }
    }

    private func fetchDatabaseContent(completion: @escaping () -> Void) {
        database.fetch(Site.self, Supervisor.self, Species.self) { [weak self] sites, supervisors, species in
            self?.sites = sites.sorted(by: \.name, order: .ascending)
            self?.supervisors = supervisors.sorted(by: \.name, order: .ascending)
            self?.species = species.sorted(by: \.name, order: .ascending)
            completion()
        }
    }

    private func presentUploadButton(isUploading: Bool) {
        self.actionButton = ButtonModel(
            title: .text(isUploading ? "Stop uploading" : "Upload"),
            action: { [weak self] in
                if isUploading {
                    self?.cancelUploading()
                } else {
                    self?.upload()
                }
            },
            isEnabled: true
        )
    }

    private func presentNavigationButtons(isUploading: Bool) {
        self.rightNavigationButtons =
            [!isUploading ? .init(
                title: .system(.trash),
                action: { [weak self] in
                    self?.alert = AlertModel(title: "Confirm", message: "Are you sure you want to delete ALL trees from the queue?", buttons: [
                        .init(title: "Delete", style: .destructive, action: { [weak self] in
                            self?.stopUploading()
                            self?.clearQueue()
                        }),
                        .init(title: "Cancel", style: .cancel, action: nil),
                    ])
                },
                isEnabled: true
            ) : nil].compactMap { $0 } + [
                .init(
                title: .system(.add),
                action: { [weak self] in self?.navigation?.triggerAddTreesFlow { _ in self?.refreshData() }  },
                isEnabled: true
            )]
    }

    func upload() {
        presentUploadButton(isUploading: true)
        presentNavigationButtons(isUploading: true)
        screenLockManager.disableLocking()
        uploadLocalTreesRecursively()
    }

    private func stopUploading() {
        screenLockManager.allowLocking()
        presentUploadButton(isUploading: false)
        presentNavigationButtons(isUploading: false)
        presentTreesFromDatabase()
    }

    private func clearQueue() {
        database.removeLocalTrees { [weak self] in
            self?.presentTreesFromDatabase()
        }
    }

    private func cancelUploading() {
        print("Uploading cancelled.")
        currentUpload?.cancel()
        stopUploading()
    }

    private func uploadLocalTreesRecursively() {
        print("Uploading images...")
        database.fetchLocalTrees { [weak self] trees in
            guard let tree = trees.first else {
                print("No more items to upload - bailing.")
                self?.stopUploading()
                return
            }
            
            print("Now uploading tree: \(tree)")
            self?.currentUpload = self?.api.upload(
                tree: tree,
                progress: { progress in
                    NSLog("progress: \(progress)")
                    self?.update(uploadProgress: progress, for: tree)
                },
                completion: { result in
                    switch result {
                    case let .success(airtableTree):
                        print("Successfully uploaded tree.")
                        self?.database.save([airtableTree])
                        self?.database.remove(tree: tree) {
                            self?.presentTreesFromDatabase()
                            self?.uploadLocalTreesRecursively()
                        }
                    case let .failure(error):
                        self?.update(uploadProgress: 0.0, for: tree)
                        self?.presentUploadButton(isUploading: false)
                        print("Error when uploading a local tree: \(error)")
                    }
                }
            )
        }
    }

    private func update(uploadProgress: Double, for tree: LocalTree) {
        guard let section = data.first else { return }

        let newItem = buildItem(tree: tree, progress: uploadProgress)
        let newSection = section.section(replacing: newItem)
        data = [newSection]
    }

    private func presentTreesFromDatabase() {
        database.fetchLocalTrees { [weak self] trees in
            self?.presentTitle(itemsCount: trees.count)
            self?.data = [.untitled(id: "trees", trees.compactMap { tree in
                return self?.buildItem(tree: tree, progress: 0.0)
            })]
        }
    }

    private func presentTitle(itemsCount: Int) {
        if itemsCount > 0 {
            title = "Upload queue (\(itemsCount))"
        } else {
            title = "Upload queue"
        }
    }

    private func buildItem(tree: LocalTree, progress: Double) -> TreesListItem {
        let imageLoader = AnyImageLoader(imageLoader: PHImageLoader(phImageId: tree.phImageId))
        let info = species.first { $0.id == tree.species }?.name ?? "Unknown specie"
        return .tree(id: tree.phImageId,
                     imageLoader: imageLoader,
                     progress: progress,
                     info: info,
                     detail: tree.supervisor,
                     tapAction: Action(id: "tree_action_\(tree.phImageId)") { [weak self] in
                        self?.navigation?.triggerEditDetailsFlow(tree: tree) { _ in self?.refreshData() }
                     })
    }
}
