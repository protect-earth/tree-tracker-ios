import Foundation

private extension LogCategory {
    static var entities = LogCategory(name: "Entities")
}

final class EntitiesViewModel: TableViewModel {
    @DelayedPublished var alert: AlertModel
    @Published var title: String
    @Published var data: [ListSection<TableListItem>]
    @Published var rightNavigationButtons: [NavigationBarButtonModel]
    @Published var actionButton: ButtonModel?

    var alertPublisher: DelayedPublished<AlertModel>.Publisher { $alert }
    var titlePublisher: Published<String>.Publisher { $title }
    var actionButtonPublisher: Published<ButtonModel?>.Publisher { $actionButton }
    var rightNavigationButtonsPublisher: Published<[NavigationBarButtonModel]>.Publisher { $rightNavigationButtons }
    var dataPublisher: Published<[ListSection<TableListItem>]>.Publisher { $data }

    private let api: Api
    private let database: Database
    private let logger: Logging
    private var sites: [Site] = []
    private var species: [Species] = []
    private var supervisors: [Supervisor] = []

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, logger: Logging = CurrentEnvironment.logger) {
        self.title = "Entities"
        self.api = api
        self.database = database
        self.logger = logger
        self.data = []
        self.rightNavigationButtons = []

        self.rightNavigationButtons = [
            .init(
                title: .system(.refresh),
                action: { [weak self] in self?.sync() },
                isEnabled: true
            )
        ]

        preheatEntities()
    }

    func onAppear() {
        refreshData(syncOnEmptyData: true)
    }

    private func preheatEntities() {
        fetchDatabaseContent { [weak self] in
            if self?.sites.isEmpty == true || self?.supervisors.isEmpty == true || self?.species.isEmpty == true {
                self?.sync()
            }
        }
    }
    
    private func refreshData(syncOnEmptyData: Bool = false) {
        fetchDatabaseContent { [weak self] in
            self?.presentContentFromDatabase()
            if syncOnEmptyData, self?.sites.isEmpty == true || self?.supervisors.isEmpty == true || self?.species.isEmpty == true {
                self?.sync()
            }
        }
    }

    func sync() {
        fetchAndReplaceAllSitesFromRemote()
        fetchAndReplaceAllSpeciesFromRemote()
        fetchAndReplaceAllSupervisorsFromRemote()
    }
    
    private func fetchDatabaseContent(completion: @escaping () -> Void) {
        database.fetch(Site.self, Supervisor.self, Species.self) { [weak self] sites, supervisors, species in
            self?.sites = sites.sorted(by: \.name, order: .ascending)
            self?.supervisors = supervisors.sorted(by: \.name, order: .ascending)
            self?.species = species.sorted(by: \.name, order: .ascending)
            completion()
        }
    }

    private func fetchAndReplaceAllSpeciesFromRemote(offset: String? = nil, currentSpecies: [Species] = []) {
        var newSpecies = currentSpecies
        api.species(offset: offset) { [weak self] result in
            switch result {
            case let .success(paginatedResults):
                newSpecies.append(contentsOf: paginatedResults.records.map { $0.toSpecies() })
                if let offset = paginatedResults.offset {
                    self?.fetchAndReplaceAllSpeciesFromRemote(offset: offset, currentSpecies: newSpecies)
                } else {
                    self?.database.replace(newSpecies) {
                        self?.refreshData()
                    }
                }
            case let .failure(error):
                self?.logger.log(.entities, "Error when fetching airtable records for Species: \(error)")
            }
        }
    }
    
    private func fetchAndReplaceAllSupervisorsFromRemote(offset: String? = nil, currentSupervisors: [Supervisor] = []) {
        var newSupervisors = currentSupervisors
        api.supervisors(offset: offset) { [weak self] result in
            switch result {
            case let .success(paginatedResults):
                newSupervisors.append(contentsOf: paginatedResults.records.map { $0.toSupervisor() })
                if let offset = paginatedResults.offset {
                    self?.fetchAndReplaceAllSupervisorsFromRemote(offset: offset, currentSupervisors: newSupervisors)
                } else {
                    self?.database.replace(newSupervisors) {
                        self?.refreshData()
                    }
                }
            case let .failure(error):
                self?.logger.log(.entities, "Error when fetching airtable records for Supervisors: \(error)")
            }
        }
    }
    
    private func fetchAndReplaceAllSitesFromRemote(offset: String? = nil, currentSites: [Site] = []) {
        var newSites = currentSites
        api.sites(offset: offset) { [weak self] result in
            switch result {
            case let .success(paginatedResults):
                newSites.append(contentsOf: paginatedResults.records.map { $0.toSite() })
                if let offset = paginatedResults.offset {
                    self?.fetchAndReplaceAllSitesFromRemote(offset: offset, currentSites: newSites)
                } else {
                    self?.database.replace(newSites) {
                        self?.refreshData()
                    }
                }
            case let .failure(error):
                self?.logger.log(.entities, "Error when fetching airtable records for Sites: \(error)")
            }
        }
    }

    private func presentContentFromDatabase() {
        self.data = [
            .titled("Sites", sites.map { site in
                return .text(id: site.id, text: site.name, tapAction: Action(id: "site_action_\(site.id)") { [weak self] in
                    print("Site tapped")
                })
            }),
            .titled("Supervisors", supervisors.map { supervisor in
                return .text(id: supervisor.id, text: supervisor.name, tapAction: Action(id: "supervisor_action_\(supervisor.id)") { [weak self] in
                    print("Supervisor tapped")
                })
            }),
            .titled("Species", species.map { species in
                return .text(id: species.id, text: species.name, tapAction: Action(id: "species_action_\(species.id)") { [weak self] in
                    print("Species tapped")
                })
            }),
        ]
    }
}
