import Combine
import Photos

final class EditLocalTreeViewModel: TreeDetailsViewModel {
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
    private var tree: LocalTree
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
        self.imageLoader = nil

        self.cancelButton = NavigationBarButtonModel(
            title: .system(.close),
            action: { [weak self] in
                self?.navigation?.abandonedFillingTheDetails()
            },
            isEnabled: true)

        presentData()
    }

    private func presentData() {
        let tree = self.tree
        self.imageLoader = PHImageLoader(phImageId: tree.phImageId)
        var coordinates: String = tree.coordinates ?? ""
        var species: String = tree.species
        var supervisor: String = tree.supervisor
        var notes: String = tree.notes ?? ""

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
                  text: supervisor,
                  input: .keyboard(.default),
                  onChange: { supervisor = $0 }),
            .init(placeholder: "Notes",
                  text: notes,
                  input: .keyboard(.default),
                  onChange: { notes = $0 }),
        ]
        saveButton = ButtonModel(
            title: .text("Save"),
            action: { [weak self] in
                self?.save(tree: tree, coordinates: coordinates, species: species, supervisor: supervisor, notes: notes)
            },
            isEnabled: true
        )
    }

    private func save(tree: LocalTree, coordinates: String, species: String, supervisor: String, notes: String) {
        var newTree = tree
        newTree.coordinates = coordinates
        newTree.species = species
        newTree.supervisor = supervisor
        newTree.notes = notes
        database.update(tree: newTree) { [weak self] in
            self?.navigation?.detailsFilledSuccessfully()
        }
    }
}


