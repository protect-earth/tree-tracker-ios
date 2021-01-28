import UIKit

class TappableButton: UIButton {
    var tapAction: (() -> Void)?
    var tapAreaOffset: CGPoint = .zero

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        addSubview(spinner)
        spinner.stopAnimating()
        spinner.center(in: self)
    }

    @objc private func didTap() {
        guard isEnabled else { return }

        tapAction?()
    }

    func scaleSpinner(to factor: CGFloat) {
        spinner.transform = CGAffineTransform(scaleX: factor, y: factor)
    }

    func startLoading() {
        spinner.color = titleColor(for: .normal)
        titleLabel?.alpha = 0.0
        setImage(nil, for: .normal)
        isUserInteractionEnabled = false
        spinner.startAnimating()
    }

    func stopLoading() {
        spinner.stopAnimating()
        isUserInteractionEnabled = true
    }

    func set(model: ButtonModel) {
        isEnabled = model.isEnabled
        isUserInteractionEnabled = model.isEnabled
        tapAction = model.action
        set(title: model.title)
    }

    func set(title: ButtonModel.Title) {
        switch title {
        case let .text(text):
            stopLoading()
            setTitle(text, for: .normal)
        case .loading:
            startLoading()
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -tapAreaOffset.x, dy: -tapAreaOffset.y).contains(point)
    }
}
