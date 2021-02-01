import Combine
import Photos

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

    private let api: Api
    private let database: Database
    private let defaults: Defaults
    private let initialAssetCount: Int
    private var currentAsset: Int
    private var assets: [PHAsset]
    private var sites: [Site] = []
    private var species: [Species] = []
    private var supervisors: [Supervisor] = []
    private weak var navigation: TreeDetailsNavigating?

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, defaults: Defaults = CurrentEnvironment.defaults, assets: [PHAsset], navigation: TreeDetailsNavigating) {
        self.api = api
        self.database = database
        self.defaults = defaults
        self.navigation = navigation
        self.assets = assets
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

    private func presentCurrentAssetFields(asset: PHAsset, coordinates: String? = nil, species: Species? = nil, supervisor: Supervisor? = nil, site: Site? = nil, notes: String? = nil) {
        let defaultSpecies = self.species.first(where: { $0.id == defaults[.speciesId] })
        let defaultSupervisor = self.supervisors.first(where: { $0.id == defaults[.supervisorId] })
        let defaultSite = self.sites.first(where: { $0.id == defaults[.siteId] })

        var species = species ?? defaultSpecies
        var supervisor = supervisor ?? defaultSupervisor
        var site = site ?? defaultSite
        var notes = notes ?? ""
        var coordinates = coordinates ?? asset._coordinates

        fields = [
            .init(placeholder: "Coordinates",
                  text: coordinates,
                  input: .keyboard(.default),
                  returnKey: .done,
                  onChange: { coordinates = $0 }),
            .init(placeholder: "Species",
                  text: species?.name,
                  input: .keyboard(.selection(
                                    ["--"] + self.species.map(\.name),
                                    initialIndexSelected: self.species.firstIndex { $0.id == species?.id },
                                    indexSelected: { [weak self] selectedSpecies in
                                        species = self?.species[safe: selectedSpecies - 1]
                                        self?.presentCurrentAssetFields(asset: asset, coordinates: coordinates, species: species, supervisor: supervisor, site: site, notes: notes)
                                    }),
                                   .done()),
                  returnKey: .done,
                  onChange: { _ in }),
            .init(placeholder: "Supervisor",
                  text: supervisor?.name,
                  input: .keyboard(.selection(
                                    ["--"] + self.supervisors.map(\.name),
                                    initialIndexSelected: supervisors.firstIndex { $0.id == supervisor?.id },
                                    indexSelected: { [weak self] selectedSupervisor in
                                        supervisor = self?.supervisors[safe: selectedSupervisor - 1]
                                        self?.presentCurrentAssetFields(asset: asset, coordinates: coordinates, species: species, supervisor: supervisor, site: site, notes: notes)
                                    }),
                                   .done()),
                  returnKey: .done,
                  onChange: { _ in }),
            .init(placeholder: "Site",
                  text: site?.name,
                  input: .keyboard(.selection(
                                    ["--"] + self.sites.map(\.name),
                                    initialIndexSelected: self.sites.firstIndex { $0.id == site?.id },
                                    indexSelected: { [weak self] selectedSite in
                                        site = self?.sites[safe: selectedSite - 1]
                                        self?.presentCurrentAssetFields(asset: asset, coordinates: coordinates, species: species, supervisor: supervisor, site: site, notes: notes)
                                    }),
                                   .done()),
                  returnKey: .done,
                  onChange: { _ in }),
            .init(placeholder: "Notes",
                  text: notes,
                  input: .keyboard(.default),
                  returnKey: .done,
                  onChange: { notes = $0 }),
        ]

        if let species = species, let site = site, let supervisor = supervisor {
            saveButton = ButtonModel(
                title: .text("Save"),
                action: { [weak self] in
                    self?.save(asset: asset, coordinates: coordinates, species: species, site: site, supervisor: supervisor, notes: notes)
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

    private func save(asset: PHAsset, coordinates: String, species: Species, site: Site, supervisor: Supervisor, notes: String) {
        defaults[.speciesId] = species.id
        defaults[.supervisorId] = supervisor.id
        defaults[.siteId] = site.id

        let tree = LocalTree(phImageId: asset.localIdentifier, createDate: asset.creationDate, supervisor: supervisor.id, species: species.id, site: site.id, what3words: nil, notes: notes, coordinates: coordinates, imageMd5: nil)
        database.save([tree])
        assets.removeAll { $0 == asset }
        presentNextAssetToFillOrComplete()
    }
}

