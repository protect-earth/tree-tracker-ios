import Foundation

protocol UploadListNavigating: AnyObject {
    func triggerAddTreesFlow(completion: @escaping () -> Void)
    func triggerFillDetailsFlow(phImageIds: [String], completion: @escaping () -> Void)
    func triggerEditDetailsFlow(tree: LocalTree, completion: @escaping () -> Void)
}

final class UploadListViewModel {
    @Published var title: String
    @Published var data: [ListSection<TreesListItem>]
    @Published var syncProgress: SyncProgress?
    @Published var syncButton: ButtonModel?
    @Published var navigationButtons: [NavigationBarButtonModel]

    private var api: Api
    private var database: Database
    private weak var navigation: UploadListNavigating?

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, navigation: UploadListNavigating) {
        self.title = "Upload queue"
        self.api = api
        self.database = database
        self.navigation = navigation
        self.data = []
        self.syncButton = nil
        self.navigationButtons = []

        self.syncButton = ButtonModel(
            title: .text("Upload"),
            action: { [weak self] in
                self?.upload()
            },
            isEnabled: true
        )
        self.navigationButtons = [
            .init(
                title: .system(.add),
                action: { [weak self] in self?.navigation?.triggerAddTreesFlow { self?.loadData() }  },
                isEnabled: true
            )
        ]
    }

    func loadData() {
        presentTreesFromDatabase()
    }

    func upload() {
        uploadLocalTreesRecursively()
    }

    private func uploadLocalTreesRecursively() {
        print("Uploading images...")
        database.fetchLocalTrees { [weak self] trees in
            if let tree = trees.first {
                print("Now uploading tree: \(tree)")
                self?.api.upload(tree: tree, completion: { result in
                    switch result {
                    case let .success(airtableTree):
                        print("Successfully uploaded tree.")
                        self?.database.save([airtableTree])
                        self?.database.remove(tree: tree) {
                            self?.uploadLocalTreesRecursively()
                        }
                    case let .failure(error):
                        print("Error when uploading a local tree: \(error)")
                    }
                })
            }
        }
    }

    private func presentTreesFromDatabase() {
        database.fetchLocalTrees { [weak self] trees in
            self?.data = [.untitled(id: "trees", trees.map { tree in
                let imageLoader = AnyImageLoader(imageLoader: PHImageLoader(phImageId: tree.phImageId))
                return .tree(id: tree.phImageId,
                             imageLoader: imageLoader,
                             info: tree.species,
                             detail: tree.supervisor,
                             tapAction: Action(id: "tree_action_\(tree.phImageId)") {
                                self?.navigation?.triggerEditDetailsFlow(tree: tree) {
                                    self?.loadData()
                                }
                             })
            })]
        }
    }
}
