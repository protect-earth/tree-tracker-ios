import Combine
import Photos

final class EditLocalTreeViewModel: TreeDetailsViewModel {
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
    private var tree: LocalTree
    private var sites: [Site] = []
    private var species: [Species] = []
    private var supervisors: [Supervisor] = []
    private weak var navigation: TreeDetailsNavigating?

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, defaults: Defaults = CurrentEnvironment.defaults, tree: LocalTree, navigation: TreeDetailsNavigating) {
        self.api = api
        self.database = database
        self.defaults = defaults
        self.navigation = navigation
        self.tree = tree
        self.fields = []
        self.title = "Edit tree"
        self.saveButton = ButtonModel(title: .loading, action: nil, isEnabled: false)
        self.cancelButton = nil
        self.imageLoader = PHImageLoader(phImageId: tree.phImageId)

        self.cancelButton = NavigationBarButtonModel(
            title: .system(.close),
            action: { [weak self] in
                self?.navigation?.abandonedFillingTheDetails()
            },
            isEnabled: true)

        self.topRightNavigationButton = NavigationBarButtonModel(
            title: .system(.trash),
            action: { [weak self] in
                self?.alert = AlertModel(title: "Confirm", message: "Are you sure you want to delete this tree?", buttons: [
                    .init(title: "Delete", style: .destructive, action: { [weak self] in
                        self?.delete(tree: tree)
                    }),
                    .init(title: "Cancel", style: .cancel, action: nil),
                ])
            },
            isEnabled: true)

        fetchDatabaseContent { [weak self] in
            self?.presentCurrentTreeFields(tree: tree)
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

    private func presentCurrentTreeFields(tree: LocalTree, coordinates: String? = nil, species: Species? = nil, supervisor: Supervisor? = nil, site: Site? = nil, notes: String? = nil) {
        let defaultSpecies = self.species.first(where: { $0.id == tree.species })
        let defaultSupervisor = self.supervisors.first(where: { $0.id == tree.supervisor })
        let defaultSite = self.sites.first(where: { $0.id == tree.site })

        var species = species ?? defaultSpecies
        var supervisor = supervisor ?? defaultSupervisor
        var site = site ?? defaultSite
        var notes = notes ?? tree.notes ?? ""
        var coordinates = coordinates ?? tree.coordinates ?? ""

        fields = [
            .init(placeholder: "Coordinates",
                  text: coordinates,
                  input: .keyboard(.default),
                  returnKey: .done,
                  onChange: { coordinates = $0 }),
            .init(placeholder: "Species",
                  text: species?.name,
                  input: .keyboard(.selection(
                                    self.species.map(\.name),
                                    initialIndexSelected: self.species.firstIndex { $0.id == species?.id },
                                    indexSelected: { [weak self] selectedSpecies in
                                        species = self?.species[safe: selectedSpecies]
                                        self?.presentCurrentTreeFields(tree: tree, coordinates: coordinates, species: species, supervisor: supervisor, site: site, notes: notes)
                                    }),
                                   .done()),
                  returnKey: .done,
                  onChange: { _ in }),
            .init(placeholder: "Supervisor",
                  text: supervisor?.name,
                  input: .keyboard(.selection(
                                    self.supervisors.map(\.name),
                                    initialIndexSelected: supervisors.firstIndex { $0.id == supervisor?.id },
                                    indexSelected: { [weak self] selectedSupervisor in
                                        supervisor = self?.supervisors[safe: selectedSupervisor]
                                        self?.presentCurrentTreeFields(tree: tree, coordinates: coordinates, species: species, supervisor: supervisor, site: site, notes: notes)
                                    }),
                                   .done()),
                  returnKey: .done,
                  onChange: { _ in }),
            .init(placeholder: "Site",
                  text: site?.name,
                  input: .keyboard(.selection(
                                    self.sites.map(\.name),
                                    initialIndexSelected: self.sites.firstIndex { $0.id == site?.id },
                                    indexSelected: { [weak self] selectedSite in
                                        site = self?.sites[safe: selectedSite]
                                        self?.presentCurrentTreeFields(tree: tree, coordinates: coordinates, species: species, supervisor: supervisor, site: site, notes: notes)
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
                    self?.save(tree: tree, coordinates: coordinates, species: species, site: site, supervisor: supervisor, notes: notes)
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

    private func save(tree: LocalTree, coordinates: String, species: Species, site: Site, supervisor: Supervisor, notes: String) {
        var newTree = tree
        newTree.coordinates = coordinates
        newTree.species = species.id
        newTree.supervisor = supervisor.id
        newTree.site = site.id
        newTree.notes = notes
        database.update(tree: newTree) { [weak self] in
            self?.navigation?.detailsFilledSuccessfully()
        }
    }

    private func delete(tree: LocalTree) {
        database.remove(tree: tree) { [weak self] in
            self?.navigation?.detailsFilledSuccessfully()
        }
    }
}
