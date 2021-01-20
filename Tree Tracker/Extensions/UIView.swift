import Foundation
import UIKit

extension UIView {
    func center(in view: UIView) {
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func pin(to view: UIView) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
