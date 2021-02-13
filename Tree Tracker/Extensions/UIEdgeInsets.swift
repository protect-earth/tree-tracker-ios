import UIKit

extension UIEdgeInsets {
    static func some(top: CGFloat = 0.0, left: CGFloat = 0.0, bottom: CGFloat = 0.0, right: CGFloat = 0.0) -> UIEdgeInsets {
        return .init(top: top, left: left, bottom: bottom, right: right)
    }
}
