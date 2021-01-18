import UIKit

final class TreeTableViewCell: UITableViewCell, Reusable {
    func set(image: UIImage?, name: String, species: String?, supervisor: String?, tapAction: Action?) {
        textLabel?.text = name
        imageView?.image = image
        detailTextLabel?.text = "Species: \(species ?? "-")" + "Supervisor: \(supervisor ?? "-")"
    }
}
