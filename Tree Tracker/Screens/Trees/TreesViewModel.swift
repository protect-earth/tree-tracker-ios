import Foundation

final class TreesViewModel {
    @Published var title: String
    @Published var data: [ListSection<TreesListItem>]
    @Published var navigationButtons: [NavigationBarButtonModel]

    private var api: Api
    private var database: Database

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database) {
        self.title = "Uploaded Trees"
        self.api = api
        self.database = database
        self.data = []
        self.navigationButtons = []

        self.navigationButtons = [
            .init(
                title: .system(.refresh),
                action: { [weak self] in self?.sync() },
                isEnabled: true
            )
        ]
    }

    func loadData() {
        presentTreesFromDatabase()
    }

    func sync() {
        lazilyLoadAllRemoteTreesIfPossible()
    }

    private func lazilyLoadAllRemoteTreesIfPossible(offset: String? = nil) {
        api.treesPlanted(offset: offset) { [weak self] result in
            switch result {
            case let .success(paginatedResults):
                self?.database.save(paginatedResults.records)
                if let offset = paginatedResults.offset {
                    self?.lazilyLoadAllRemoteTreesIfPossible(offset: offset)
                } else {
                    self?.presentTreesFromDatabase()
                }
            case let .failure(error):
                self?.presentTreesFromDatabase()
                print("Error when saving airtable records: \(error)")
            }
        }
    }

    private func presentTreesFromDatabase() {
        database.fetchRemoteTrees { [weak self] trees in
            self?.data = [.untitled(id: "trees", trees.map { tree in
                let imageLoader = (tree.thumbnailUrl ?? tree.imageUrl).map { AnyImageLoader(imageLoader: URLImageLoader(url: $0)) }
                return .tree(id: "\(tree.id)",
                             imageLoader: imageLoader,
                             progress: 0,
                             info: tree.species,
                             detail: tree.supervisor,
                             tapAction: Action(id: "tree_action_\(tree.id)") {
                                print("tap action")
                             })
            })]
        }
    }
}
