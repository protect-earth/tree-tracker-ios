import UIKit

extension UIAlertController {
    static func error(_ message: String, okAction: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in okAction?() }))

        return alert
    }
}
