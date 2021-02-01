import UIKit

final class TextField: UITextField, UITextFieldDelegate {
    var onChange: ((String) -> Void)?
    var placeholderColor: UIColor = .gray
    var isCaretHidden = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        delegate = self

        addTarget(self, action: #selector(didChangeText), for: .editingChanged)
        backgroundColor = .white
    }

    @objc private func didChangeText() {
        onChange?(text ?? "")
    }

    func set(model: TextFieldModel) {
        onChange = model.onChange
        isEnabled = model.input.usesKeyboard
        text = model.text
        attributedPlaceholder = NSAttributedString(string: model.placeholder ?? "", attributes: [.foregroundColor: placeholderColor])
        placeholder = model.placeholder
        returnKeyType = model.returnKey ?? .default
        isCaretHidden = false

        switch model.input {
        case let .keyboard(keyboard, accessory, autocorrectionType, capitalize):
            autocapitalizationType = capitalize
            self.autocorrectionType = autocorrectionType ?? .default

            switch keyboard {
            case .default:
                keyboardType = .default
            case let .selection(values, initialIndexSelected, indexSelected):
                inputView = SelectionsKeyboardView(selections: values, initialIndexSelected: initialIndexSelected, indexSelected: indexSelected)
                isCaretHidden = true
                break
            }

            if let keyboardAccessory = accessory {
                inputAccessoryView = KeyboardAccessoryView(model: keyboardAccessory, textField: self)
            }
        case .map:
            #warning("TODO: TextField with map input")
            break
        }
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        if isCaretHidden {
            return .zero
        } else {
            return super.caretRect(for: position)
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if isCaretHidden {
            return false
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        return true
    }
}

