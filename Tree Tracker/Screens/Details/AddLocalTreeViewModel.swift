import Combine
import Photos

protocol TreeDetailsNavigating: AnyObject {
    func detailsFilledSuccessfully()
    func abandonedFillingTheDetails()
}

protocol TreeDetailsViewModel {
    var imageLoaderPublisher: Published<PHImageLoader?>.Publisher { get }
    var titlePublisher: Published<String>.Publisher { get }
    var fieldsPublisher: Published<[TextFieldModel]>.Publisher { get }
    var cancelButtonPublisher: Published<NavigationBarButtonModel?>.Publisher { get }
    var saveButtonPublisher: Published<ButtonModel?>.Publisher { get }
}

final class AddLocalTreeViewModel: TreeDetailsViewModel {
    @Published var imageLoader: PHImageLoader?
    @Published var title: String
    @Published var fields: [TextFieldModel]
    @Published var cancelButton: NavigationBarButtonModel?
    @Published var saveButton: ButtonModel?

    var imageLoaderPublisher: Published<PHImageLoader?>.Publisher { $imageLoader }
    var titlePublisher: Published<String>.Publisher { $title }
    var fieldsPublisher: Published<[TextFieldModel]>.Publisher { $fields }
    var cancelButtonPublisher: Published<NavigationBarButtonModel?>.Publisher { $cancelButton }
    var saveButtonPublisher: Published<ButtonModel?>.Publisher { $saveButton }

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
        let group = DispatchGroup()
        group.enter()
        group.enter()
        group.enter()
        group.notify(queue: .main) {
            completion()
        }

        database.fetch { [weak self] (sites: [Site]) in
            self?.sites = sites
            group.leave()
        }

        database.fetch { [weak self] (supervisors: [Supervisor]) in
            self?.supervisors = supervisors
            group.leave()
        }

        database.fetch { [weak self] (species: [Species]) in
            self?.species = species
            group.leave()
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

        var coordinates: String = asset._coordinates
        var species: String = defaults[.species] ?? ""
        var supervisor: String = defaults[.supervisor] ?? ""
        var site: String = ""
        var notes: String = ""
        
        fields = [
            .init(placeholder: "Coordinates",
                  text: coordinates,
                  input: .keyboard(.default),
                  onChange: { coordinates = $0 }),
            .init(placeholder: "Species",
                  text: species,
                  input: .keyboard(.selection(self.species.map(\.name))),
                  onChange: { species = $0 }),
            .init(placeholder: "Supervisor",
                  text: supervisor,
                  input: .keyboard(.selection(self.supervisors.map(\.name))),
                  onChange: { supervisor = $0 }),
            .init(placeholder: "Site",
                  text: supervisor,
                  input: .keyboard(.selection(self.sites.map(\.name))),
                  onChange: { site = $0 }),
            .init(placeholder: "Notes",
                  text: notes,
                  input: .keyboard(.default),
                  onChange: { notes = $0 }),
        ]
        saveButton = ButtonModel(
            title: .text("Save"),
            action: { [weak self] in
                self?.save(asset: asset, coordinates: coordinates, species: species, site: site, supervisor: supervisor, notes: notes)
            },
            isEnabled: true
        )
    }

    private func save(asset: PHAsset, coordinates: String, species: String, site: String, supervisor: String, notes: String) {
        let tree = LocalTree(phImageId: asset.localIdentifier, createDate: asset.creationDate, supervisor: supervisor, species: species, site: site, what3words: nil, notes: notes, coordinates: coordinates, imageMd5: nil)
        defaults[.species] = species
        defaults[.supervisor] = supervisor
        database.save([tree])
        assets.removeAll { $0 == asset }
        presentNextAssetToFillOrComplete()
    }
}
