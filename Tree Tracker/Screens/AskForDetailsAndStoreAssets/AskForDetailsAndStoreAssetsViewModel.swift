import Combine
import Photos

protocol AskForDetailsAndStoreAssetsNavigating: AnyObject {
    func detailsFilledSuccessfully()
    func abandonedFillingTheDetails()
}

final class AskForDetailsAndStoreAssetsViewModel {
    @Published var imageLoader: PHImageLoader?
    @Published var title: String
    @Published var fields: [TextFieldModel]
    @Published var cancelButton: NavigationBarButtonModel?
    @Published var saveButton: ButtonModel?

    private let api: Api
    private let database: Database
    private let defaults: Defaults
    private let initialAssetCount: Int
    private var currentAsset: Int
    private var assets: [PHAsset]
    private var assetLocator: PHAssetLocator?
    private weak var navigation: AskForDetailsAndStoreAssetsNavigating?

    init(api: Api = CurrentEnvironment.api, database: Database = CurrentEnvironment.database, defaults: Defaults = CurrentEnvironment.defaults, assets: [PHAsset], navigation: AskForDetailsAndStoreAssetsNavigating) {
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

        presentNextAssetToFillOrComplete()
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
        self.assetLocator = PHAssetLocator(phImageId: asset.localIdentifier)

        var coordinates: String = assetLocator?.asset?._coordinates ?? ""
        var species: String = defaults[.species] ?? ""
        var supervisor: String = defaults[.supervisor] ?? ""
        var notes: String = defaults[.notes] ?? ""
        fields = [
            .init(placeholder: "Coordinates",
                  text: coordinates,
                  input: .keyboard(.default),
                  onChange: { coordinates = $0 }),
            .init(placeholder: "Species",
                  text: species,
                  input: .keyboard(.default),
                  onChange: { species = $0 }),
            .init(placeholder: "Supervisor",
                  text: defaults[.supervisor],
                  input: .keyboard(.default),
                  onChange: { supervisor = $0 }),
            .init(placeholder: "Notes",
                  text: defaults[.notes],
                  input: .keyboard(.default),
                  onChange: { notes = $0 }),
        ]
        saveButton = ButtonModel(
            title: .text("Save"),
            action: { [weak self] in
                self?.save(asset: asset, coordinates: coordinates, species: species, supervisor: supervisor, notes: notes)
            },
            isEnabled: true
        )
    }

    private func save(asset: PHAsset, coordinates: String, species: String, supervisor: String, notes: String) {
        let tree = Tree(supervisor: supervisor, species: species, notes: notes, coordinates: coordinates, imageUrl: nil, imageMd5: nil, phImageId: asset.localIdentifier, remoteId: nil, uploadDate: nil)

        database.save([tree])
        assets.removeAll { $0 == asset }
        presentNextAssetToFillOrComplete()
    }
}

