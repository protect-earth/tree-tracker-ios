import UIKit

final class TreeCollectionViewCell: UICollectionViewCell, Reusable {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4.0
        imageView.clipsToBounds = true

        return imageView
    }()

    private let wrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 4.0

        return view
    }()

    private let infoOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.layer.cornerRadius = 4.0
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        return view
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12.0)

        return label
    }()

    private var imageLoader: AnyImageLoader?
    private var tapAction: Action?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        contentView.addSubview(wrapper)
        wrapper.add(subviews: imageView, infoOverlay)
        infoOverlay.addSubview(infoLabel)

        wrapper.pin(to: contentView)
        imageView.pin(to: wrapper)

        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(equalTo: infoOverlay.leadingAnchor, constant: 8.0),
            infoLabel.trailingAnchor.constraint(equalTo: infoOverlay.trailingAnchor, constant: -8.0),
            infoLabel.topAnchor.constraint(equalTo: infoOverlay.topAnchor, constant: 8.0),
            infoLabel.bottomAnchor.constraint(equalTo: infoOverlay.bottomAnchor, constant: -8.0),

            infoOverlay.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            infoOverlay.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            infoOverlay.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
        ])
    }

    func set(imageLoader: AnyImageLoader?, info: String, detail: String?, tapAction: Action?) {
        self.imageLoader = imageLoader
        self.tapAction = tapAction

        infoLabel.text = info.isEmpty ? " " : info

        imageLoader?.loadThumbnail { [weak self] image in
            guard let self = self, self.imageLoader == imageLoader else {
                return
            }

            self.imageView.image = image
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if let location = touches.first?.location(in: self), self.bounds.contains(location) {
            tapAction?()
        }
    }
}
