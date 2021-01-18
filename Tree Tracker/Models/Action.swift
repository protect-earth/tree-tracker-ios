import Foundation

struct Action: Hashable {
    let id: String
    let action: (() -> Void)?

    func callAsFunction() {
        action?()
    }

    static func == (lhs: Action, rhs: Action) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
