import Combine
import Photos
import Resolver

protocol TreeDetailsNavigating: AnyObject {
    func detailsFilledSuccessfully()
    func abandonedFillingTheDetails()
}

protocol TreeDetailsViewModel {
    var alertPublisher: DelayedPublished<AlertModel>.Publisher { get }
    var imageLoaderPublisher: Published<PHImageLoader?>.Publisher { get }
    var titlePublisher: Published<String>.Publisher { get }
    var fieldsPublisher: Published<[TextFieldModel]>.Publisher { get }
    var cancelButtonPublisher: Published<NavigationBarButtonModel?>.Publisher { get }
    var saveButtonPublisher: Published<ButtonModel?>.Publisher { get }
    var topRightNavigationButtonPublisher: Published<NavigationBarButtonModel?>.Publisher { get }
}

final class AddLocalTreeViewModel: TreeDetailsViewModel {
    @DelayedPublished var alert: AlertModel
    @Published var imageLoader: PHImageLoader?
    @Published var title: String
    @Published var fields: [TextFieldModel]
    @Published var cancelButton: NavigationBarButtonModel?
    @Published var saveButton: ButtonModel?
    @Published var topRightNavigationButton: NavigationBarButtonModel?

    var alertPublisher: DelayedPublished<AlertModel>.Publisher { $alert }
    var imageLoaderPublisher: Published<PHImageLoader?>.Publisher { $imageLoader }
    var titlePublisher: Published<String>.Publisher { $title }
    var fieldsPublisher: Published<[TextFieldModel]>.Publisher { $fields }
    var cancelButtonPublisher: Published<NavigationBarButtonModel?>.Publisher { $cancelButton }
    var saveButtonPublisher: Published<ButtonModel?>.Publisher { $saveButton }
    var topRightNavigationButtonPublisher: Published<NavigationBarButtonModel?>.Publisher { $topRightNavigationButton }

    @Injected private var database: Database
    @Injected private var defaults: Defaults
    
    private let recentSpeciesManager: RecentSpeciesManaging
    private let initialAssetCount: Int
    private var currentAsset: Int
    private var assets: [PHAsset]
    private var staticSupervisor: Supervisor?
    private var staticSite: Site?
    private var sites: [Site] = []
    private var species: [Species] = []
    private var supervisors: [Supervisor] = []
    private weak var navigation: TreeDetailsNavigating?

    init(recentSpeciesManager: RecentSpeciesManaging = CurrentEnvironment.recentSpeciesManager, assets: [PHAsset], staticSupervisor: Supervisor?, staticSite: Site?, navigation: TreeDetailsNavigating) {
        self.recentSpeciesManager = recentSpeciesManager
        self.navigation = navigation
        self.assets = assets
        self.staticSupervisor = staticSupervisor
        self.staticSite = staticSite
        self.fields = []
        self.initialAssetCount = assets.count
        self.currentAsset = 0
        self.title = "Fill in the details"
        self.saveButton = ButtonModel(title: .loading, action: nil, isEnabled: false)
        self.cancelButton = nil
        self.imageLoader = nil

        self.cancelButton = NavigationBarButtonModel(
            title: .system(.close),
            action: { [weak self] in
                self?.navigation?.abandonedFillingTheDetails()
            },
            isEnabled: true)

        fetchDatabaseContent { [weak self] in
            self?.presentNextAssetToFillOrComplete()
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

    private func presentNextAssetToFillOrComplete() {
        guard let asset = assets.first else {
            self.navigation?.detailsFilledSuccessfully()
            return
        }

        currentAsset += 1

        if initialAssetCount > 0 && currentAsset <= initialAssetCount {
            self.title = "Fill in the details (\(currentAsset)/\(initialAssetCount))"
        } else {
            self.title = "Fill in the details"
        }

        self.imageLoader = PHImageLoader(phImageId: asset.localIdentifier)

        presentCurrentAssetFields(asset: asset)
    }

    private func presentCurrentAssetFields(asset: PHAsset, species: Species? = nil, supervisor: Supervisor? = nil, site: Site? = nil) {
        let defaultSpecies = self.species.first(where: { $0.id == defaults[.speciesId] })
        let defaultSupervisor = self.supervisors.first(where: { $0.id == defaults[.supervisorId] })
        let defaultSite = self.sites.first(where: { $0.id == defaults[.siteId] })

        var species = species ?? defaultSpecies
        var supervisor = supervisor ?? defaultSupervisor
        var site = site ?? defaultSite
        
        let recentSpecies = recentSpeciesManager.fetch().filter { self.species.contains($0) }
        let speciesWithRecentSpecies = recentSpecies + [Species(id: "", name: "--")] + self.species

        var fields: [TextFieldModel] = [
            .init(placeholder: "Species",
                  text: species?.name,
                  input: .keyboard(.selection(
                                    speciesWithRecentSpecies.map(\.name),
                                    initialIndexSelected: speciesWithRecentSpecies.firstIndex { $0.id == species?.id },
                                    indexSelected: { [weak self] selectedSpecies in
                                        species = speciesWithRecentSpecies[safe: selectedSpecies]
                                        self?.presentCurrentAssetFields(asset: asset, species: species, supervisor: supervisor, site: site)
                                    }),
                                   .done()),
                  returnKey: .done,
                  onChange: { _ in })
        ]
        
        if staticSupervisor == nil {
            fields.append(.init(placeholder: "Supervisor",
                                text: supervisor?.name,
                                input: .keyboard(.selection(
                                                  ["--"] + self.supervisors.map(\.name),
                                                  initialIndexSelected: supervisors.firstIndex { $0.id == supervisor?.id }.map { $0 + 1 },
                                                  indexSelected: { [weak self] selectedSupervisor in
                                                      supervisor = self?.supervisors[safe: selectedSupervisor - 1]
                                                      self?.presentCurrentAssetFields(asset: asset, species: species, supervisor: supervisor, site: site)
                                                  }),
                                                 .done()),
                                returnKey: .done,
                                onChange: { _ in }))
        }
        
        if staticSite == nil {
            fields.append(.init(placeholder: "Site",
                                text: site?.name,
                                input: .keyboard(.selection(
                                                  ["--"] + self.sites.map(\.name),
                                                  initialIndexSelected: self.sites.firstIndex { $0.id == site?.id }.map { $0 + 1 },
                                                  indexSelected: { [weak self] selectedSite in
                                                      site = self?.sites[safe: selectedSite - 1]
                                                      self?.presentCurrentAssetFields(asset: asset, species: species, supervisor: supervisor, site: site)
                                                  }),
                                                 .done()),
                                returnKey: .done,
                                onChange: { _ in }))
        }
        
        self.fields = fields

        if let species = species, species.id.isNotEmpty, let site = staticSite ?? site, let supervisor = staticSupervisor ?? supervisor {
            saveButton = ButtonModel(
                title: .text("Save"),
                action: { [weak self] in
                    self?.save(asset: asset, species: species, site: site, supervisor: supervisor)
                },
                isEnabled: true
            )
        } else {
            saveButton = ButtonModel(
                title: .text("Save"),
                action: { },
                isEnabled: false
            )
        }
    }

    private func save(asset: PHAsset, species: Species, site: Site, supervisor: Supervisor) {
        defaults[.speciesId] = species.id
        defaults[.supervisorId] = supervisor.id
        defaults[.siteId] = site.id
        
        recentSpeciesManager.add(species, timestamp: .now)

        let tree = LocalTree(treeId: UUID().uuidString,
                             phImageId: asset.localIdentifier,
                             createDate: asset.creationDate,
                             supervisor: supervisor.id,
                             species: species.id,
                             site: site.id,
                             coordinates: asset.stringifyCoordinates())
        database.save([tree])
        assets.removeAll { $0 == asset }
        presentNextAssetToFillOrComplete()
    }
}
