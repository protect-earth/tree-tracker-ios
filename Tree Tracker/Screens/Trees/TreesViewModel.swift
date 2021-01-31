import Foundation

final class TreesViewModel: TableListViewModel {
    @Published var title: String
    @Published var data: [ListSection<TreesListItem>]
    @Published var rightNavigationButtons: [NavigationBarButtonModel]
    @Published var actionButton: ButtonModel?

    var titlePublisher: Published<String>.Publisher { $title }
    var actionButtonPublisher: Published<ButtonModel?>.Publisher { $actionButton }
    var rightNavigationButtonsPublisher: Published<[NavigationBarButtonModel]>.Publisher { $rightNavigationButtons }
    var dataPublisher: Published<[ListSection<TreesListItem>]>.Publisher { $data }

    private var api: Api
    private var database: Database
    private var sites: [Site] = []
    private var species: [Species] = []
    private var supervisors: [Supervisor] = []

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database) {
        self.title = "Uploaded Trees"
        self.api = api
        self.database = database
        self.data = []
        self.rightNavigationButtons = []

        self.rightNavigationButtons = [
            .init(
                title: .system(.refresh),
                action: { [weak self] in self?.sync() },
                isEnabled: true
            )
        ]

        lazilyLoadAllSpeciesIfPossible()
        lazilyLoadAllSitesIfPossible()
        lazilyLoadAllSupervisorsIfPossible()
    }

    func loadData() {
        fetchDatabaseContent { [weak self] in
            self?.presentTreesFromDatabase()
        }
    }

    func sync() {
        lazilyLoadAllRemoteTreesIfPossible()
        lazilyLoadAllSpeciesIfPossible()
        lazilyLoadAllSitesIfPossible()
        lazilyLoadAllSupervisorsIfPossible()
    }
    
    private func fetchDatabaseContent(completion: @escaping () -> Void) {
        database.fetch(Site.self, Supervisor.self, Species.self) { [weak self] sites, supervisors, species in
            self?.sites = sites.sorted(by: \.name, order: .ascending)
            self?.supervisors = supervisors.sorted(by: \.name, order: .ascending)
            self?.species = species.sorted(by: \.name, order: .ascending)
            completion()
        }
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

    private func lazilyLoadAllSpeciesIfPossible(offset: String? = nil) {
        api.species(offset: offset) { [weak self] result in
            switch result {
            case let .success(paginatedResults):
                self?.database.save(paginatedResults.records.map { $0.toSpecies() })
                if let offset = paginatedResults.offset {
                    self?.lazilyLoadAllSpeciesIfPossible(offset: offset)
                }
            case let .failure(error):
                print("Error when saving airtable records: \(error)")
            }
        }
    }

    private func lazilyLoadAllSupervisorsIfPossible(offset: String? = nil) {
        api.supervisors(offset: offset) { [weak self] result in
            switch result {
            case let .success(paginatedResults):
                self?.database.save(paginatedResults.records.map { $0.toSupervisor() })
                if let offset = paginatedResults.offset {
                    self?.lazilyLoadAllSupervisorsIfPossible(offset: offset)
                }
            case let .failure(error):
                print("Error when saving airtable records: \(error)")
            }
        }
    }

    private func lazilyLoadAllSitesIfPossible(offset: String? = nil) {
        api.sites(offset: offset) { [weak self] result in
            switch result {
            case let .success(paginatedResults):
                self?.database.save(paginatedResults.records.map { $0.toSite() })
                if let offset = paginatedResults.offset {
                    self?.lazilyLoadAllSitesIfPossible(offset: offset)
                }
            case let .failure(error):
                print("Error when saving airtable records: \(error)")
            }
        }
    }

    private func presentTreesFromDatabase() {
        database.fetchRemoteTrees { [weak self] trees in
            self?.data = [.untitled(id: "trees", trees.map { tree in
                let imageLoader = (tree.thumbnailUrl ?? tree.imageUrl).map { AnyImageLoader(imageLoader: URLImageLoader(url: $0)) }
                let info = self?.species.first { $0.id == tree.species }?.name ?? "Unknown specie"
                return .tree(id: "\(tree.id)",
                             imageLoader: imageLoader,
                             progress: 0,
                             info: info,
                             detail: tree.supervisor,
                             tapAction: Action(id: "tree_action_\(tree.id)") {
                                print("tap action")
                             })
            })]
        }
    }
}
