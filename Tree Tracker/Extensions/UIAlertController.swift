import UIKit

extension UIAlertController {
    static func error(_ message: String, okAction: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in okAction?() }))

        return alert
    }

    static func from(model: AlertModel) -> UIAlertController {
        let alert = UIAlertController(title: model.title, message: model.message, preferredStyle: .alert)

        for button in model.buttons {
            alert.addAction(.from(model: button))
        }

        return alert
    }
}

extension UIAlertAction {
    static func from(model: AlertButtonModel) -> UIAlertAction {
        return UIAlertAction(title: model.title, style: .from(model: model.style)) { _ in
            model.action?()
        }
    }
}

extension UIAlertAction.Style {
    static func from(model: AlertButtonModel.Style) -> UIAlertAction.Style {
        switch model {
        case .cancel: return .cancel
        case .default: return .default
        case .destructive: return .destructive
        }
    }
}
