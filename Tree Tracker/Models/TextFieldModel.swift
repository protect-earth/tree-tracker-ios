import Foundation
import UIKit

struct TextFieldModel: Hashable {
    enum Input: Hashable {
        case keyboard(Keyboard, KeyboardAccessory? = nil, autocorrectionType: UITextAutocorrectionType? = nil, capitalize: UITextAutocapitalizationType = .none)
        case map

        var usesKeyboard: Bool {
            switch self {
            case .keyboard: return true
            case .map: return false
            }
        }
    }

    let placeholder: String?
    let text: String?
    let input: Input
    let onChange: ((String) -> Void)?

    static func == (lhs: TextFieldModel, rhs: TextFieldModel) -> Bool {
        return lhs.placeholder == rhs.placeholder && lhs.text == rhs.text
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(placeholder)
        hasher.combine(text)
    }
}
