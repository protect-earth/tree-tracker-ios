import Foundation

enum Keyboard: Hashable {
    case `default`
    case selection([String], initialIndexSelected: Int? = nil, indexSelected: ((Int) -> Void)?)

    static func == (lhs: Keyboard, rhs: Keyboard) -> Bool {
        switch (lhs, rhs) {
        case (.default, .default): return true
        case let (.selection(model1, initialIndexSelected1, _), .selection(model2, initialIndexSelected2, _)): return model1 == model2 && initialIndexSelected1 == initialIndexSelected2
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .default:
            hasher.combine("default")
        case let .selection(model, initialIndexSelected, _):
            hasher.combine(model)
            hasher.combine(initialIndexSelected)
        }
    }
}
