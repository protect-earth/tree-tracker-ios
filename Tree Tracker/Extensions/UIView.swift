import Foundation
import UIKit

extension UIView {
    func center(in view: UIView) {
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func pin(to view: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
        ])
    }
    
    func add(subviews: UIView...) {
        subviews.forEach { addSubview($0) }
    }

    static func spacer() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.setContentCompressionResistancePriority(.required, for: .horizontal)

        return view
    }
}
