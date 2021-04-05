enum TableListItem: Identifiable, Hashable {
    case text(id: String, text: String, tapAction: Action?)

    var id: String {
        switch self {
        case let .text(id, _, _): return id
        }
    }
}
