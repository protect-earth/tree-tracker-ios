import Foundation

private extension LogCategory {
    static var treeList = LogCategory(name: "TreeList")
}

final class UploadHistoryViewModel: CollectionViewModel {
    @DelayedPublished var alert: AlertModel
    @Published var title: String
    @Published var data: [ListSection<CollectionListItem>]
    @Published var rightNavigationButtons: [NavigationBarButtonModel]
    @Published var actionButton: ButtonModel?

    var alertPublisher: DelayedPublished<AlertModel>.Publisher { $alert }
    var titlePublisher: Published<String>.Publisher { $title }
    var actionButtonPublisher: Published<ButtonModel?>.Publisher { $actionButton }
    var rightNavigationButtonsPublisher: Published<[NavigationBarButtonModel]>.Publisher { $rightNavigationButtons }
    var dataPublisher: Published<[ListSection<CollectionListItem>]>.Publisher { $data }

    private let api: Api
    private let database: Database
    private let logger: Logging
    private var sites: [Site] = []
    private var species: [Species] = []
    private var supervisors: [Supervisor] = []

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, logger: Logging = CurrentEnvironment.logger) {
        self.title = "Upload History"
        self.api = api
        self.database = database
        self.logger = logger
        self.data = []
        self.rightNavigationButtons = []
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

    private func presentTreesFromDatabase() {
        database.fetchUploadedTrees { [weak self] trees in
            let sortedTrees = trees.sorted(by: \.createDate, order: .descending)
            self?.data = [.untitled(id: "trees", sortedTrees.map { tree in
                let imageLoader = (tree.thumbnailUrl ?? tree.imageUrl).map { AnyImageLoader(imageLoader: URLImageLoader(url: $0)) }
                let info = self?.species.first { $0.id == tree.species }?.name ?? "Unknown specie"
                return .tree(id: "\(tree.id)",
                             imageLoader: imageLoader,
                             progress: 0,
                             info: info,
                             detail: tree.supervisor,
                             tapAction: Action(id: "tree_action_\(tree.id)") {
                                self?.logger.log(.treeList, "tap action")
                             })
            })]
        }
    }
}
