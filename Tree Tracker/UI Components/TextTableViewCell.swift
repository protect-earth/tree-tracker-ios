import UIKit

final class TextTableViewCell: UITableViewCell, Reusable {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 14.0)

        return label
    }()


    private var imageLoader: AnyImageLoader?
    private var tapAction: Action?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        contentView.addSubview(titleLabel)
        backgroundColor = .clear

        titleLabel.pin(to: contentView, insets: .init(top: 8.0, left: 16.0, bottom: 8.0, right: 16.0))
    }

    func set(text: String,  tapAction: Action?) {
        self.titleLabel.text = text
        self.tapAction = tapAction
    }
    
    func set(imageLoader: AnyImageLoader?, progress: Double, info: String, detail: String?, tapAction: Action?) {
        self.imageLoader = imageLoader
        self.tapAction = tapAction
        
        accessoryType = tapAction != nil ? .disclosureIndicator : .none
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if let location = touches.first?.location(in: self), self.bounds.contains(location) {
            tapAction?()
        }
    }
}
