import Foundation

protocol UploadListNavigating: AnyObject {
    func triggerAddTreesFlow(completion: @escaping () -> Void)
    func triggerFillDetailsFlow(phImageIds: [String], completion: @escaping () -> Void)
    func triggerEditDetailsFlow(tree: LocalTree, completion: @escaping () -> Void)
}

final class UploadListViewModel {
    @Published var title: String
    @Published var data: [ListSection<TreesListItem>]
    @Published var syncButton: ButtonModel?
    @Published var navigationButtons: [NavigationBarButtonModel]

    private var api: Api
    private var database: Database
    private var currentUpload: Cancellable?
    private weak var navigation: UploadListNavigating?

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, navigation: UploadListNavigating) {
        self.title = "Upload queue"
        self.api = api
        self.database = database
        self.navigation = navigation
        self.data = []
        self.syncButton = nil
        self.navigationButtons = []

        presentUploadButton(isUploading: false)

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

    private func presentUploadButton(isUploading: Bool) {
        self.syncButton = ButtonModel(
            title: .text(isUploading ? "Stop uploading" : "Upload"),
            action: { [weak self] in
                if isUploading {
                    self?.stopUploading()
                } else {
                    self?.upload()
                }
                self?.presentUploadButton(isUploading: !isUploading)
            },
            isEnabled: true
        )
    }

    func upload() {
        uploadLocalTreesRecursively()
    }

    private func stopUploading() {
        print("Uploading cancelled.")
        currentUpload?.cancel()
        presentTreesFromDatabase()
    }

    private func uploadLocalTreesRecursively() {
        print("Uploading images...")
        database.fetchLocalTrees { [weak self] trees in
            guard let tree = trees.first else {
                print("No more items to upload - bailing.")
                self?.presentUploadButton(isUploading: false)
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
            self?.data = [.untitled(id: "trees", trees.compactMap { tree in
                return self?.buildItem(tree: tree, progress: 0.0)
            })]
        }
    }

    private func buildItem(tree: LocalTree, progress: Double) -> TreesListItem {
        let imageLoader = AnyImageLoader(imageLoader: PHImageLoader(phImageId: tree.phImageId))
        return .tree(id: tree.phImageId,
                     imageLoader: imageLoader,
                     progress: progress,
                     info: tree.species,
                     detail: tree.supervisor,
                     tapAction: Action(id: "tree_action_\(tree.phImageId)") { [weak self] in
                        self?.navigation?.triggerEditDetailsFlow(tree: tree) {
                            self?.loadData()
                        }
                     })
    }
}
