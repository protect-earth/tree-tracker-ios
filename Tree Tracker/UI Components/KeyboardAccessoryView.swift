import UIKit

final class KeyboardAccessoryView: UIInputView {
    private lazy var leftButton: TappableButton = {
        let button = TappableButton()
        style(button: button, with: model.leftButton, isPrimary: false)

        return button
    }()

    private lazy var rightButton: TappableButton = {
        let button = TappableButton()
        style(button: button, with: model.rightButton, isPrimary: true)

        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [leftButton, .spacer(), rightButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)

        return stackView
    }()

    private let model: KeyboardAccessory
    private weak var textField: UITextField?

    init(model: KeyboardAccessory, textField: UITextField) {
        self.model = model
        self.textField = textField
        super.init(frame: .zero, inputViewStyle: .keyboard)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        allowsSelfSizing = true
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]

        addSubview(stackView)
        stackView.pin(to: self)
    }

    private func style(button: TappableButton, with model: ButtonModel?, isPrimary: Bool) {
        button.contentEdgeInsets = UIEdgeInsets(top: 14.0, left: 16.0, bottom: 8.0, right: 16.0)
        button.isEnabled = model?.isEnabled ?? true
        button.tapAction = { [weak self] in
            self?.textField?.resignFirstResponder()
            model?.action?()
        }
        button.set(title: model?.title ?? .text(""))
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14.0, weight: isPrimary ? .bold : .regular)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}
