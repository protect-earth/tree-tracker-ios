import Foundation

protocol TreesNavigating {
    func triggerAddTreesFlow(completion: @escaping ([Tree]) -> Void)
}

final class TreesViewModel {
    @Published var title: String
    @Published var data: [ListSection<TreesListItem>]
    @Published var syncProgress: SyncProgress?
    @Published var syncButton: ButtonModel?
    @Published var navigationButtons: [NavigationBarButtonModel]

    private var api: Api
    private var database: Database
    private var navigation: TreesNavigating

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, navigation: TreesNavigating) {
        self.title = "Tree Tracker"
        self.api = api
        self.database = database
        self.navigation = navigation
        self.data = []
        self.syncButton = nil
        self.navigationButtons = []

        self.syncButton = ButtonModel(
            title: .text("Sync"),
            action: { [weak self] in
                self?.sync()
            },
            isEnabled: true
        )
        self.navigationButtons = [
            .init(
                title: .system(.add),
                action: { [weak self] in self?.addTrees() },
                isEnabled: true
            )
        ]
    }

    func loadData() {
        presentTreesFromDatabase()
        lazilyLoadAllRemoteTreesIfPossible()
    }

    func sync() {
        print("syncing...")
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

    private func uploadLocalTreesRecursively() {
        database.fetchTreesToSync { [weak self] trees in
            if let tree = trees.first {
                self?.api.upload(tree: tree, completion: { result in
                    switch result {
                    case let .success(airtableTree):
                        self?.database.update(tree: tree, with: airtableTree)
                    case let .failure(error):
                        print("Error when uploading a local tree: \(error)")
                    }
                })
            }
        }
    }

    private func presentTreesFromDatabase() {
        database.fetchAll { [weak self] trees in
            print("trees to show: \(trees.count)")
            self?.data = [.untitled(id: "trees", trees.map { tree in
                let id = tree.remoteId.map(String.init) ?? tree.phImageId ?? UUID().uuidString
                return .tree(id: id,
                             image: nil,
                             name: tree.species,
                             species: tree.species,
                             supervisor: tree.supervisor,
                             tapAction: Action(id: "tree_action_\(id)") {
                                print("tap action")
                             })
            })]
            print("presented \(trees.count) trees")
        }
    }

    private func addTrees() {
        navigation.triggerAddTreesFlow { [weak self] trees in
            self?.database.save(trees)
        }
    }
}
