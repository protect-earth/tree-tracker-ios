//

import UIKit

class GpsInaccuracyWarning: UIView {
    @IBOutlet var view: UIView!
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        self.initSubViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initSubViews()
    }

    private func initSubViews() {
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
        nib.instantiate(withOwner: self, options: nil)
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = true
        self.addSubview(view)
    }
    
    private func addConstraints() {
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
