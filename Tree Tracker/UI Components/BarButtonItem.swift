import UIKit

final class BarButtonItem: UIBarButtonItem {
    private var customAction: (() -> Void)?

    convenience init(model: NavigationBarButtonModel) {
        switch model.title {
        case let .text(text):
            self.init(text: text, style: .plain, action: model.action)
        case let .system(systemItem):
            self.init(systemItem: systemItem, action: model.action)
        }
    }

    convenience init(text: String, style: UIBarButtonItem.Style, action: (() -> Void)?) {
        self.init(title: text, style: style, target: nil, action: nil)
        target = self
        self.action = #selector(didTap)
        customAction = action
    }

    convenience init(systemItem: UIBarButtonItem.SystemItem, action: (() -> Void)?) {
        self.init(barButtonSystemItem: systemItem, target: nil, action: nil)
        target = self
        self.action = #selector(didTap)
        customAction = action
    }

    @objc private func didTap() {
        customAction?()
    }
}
