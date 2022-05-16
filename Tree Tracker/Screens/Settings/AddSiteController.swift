import Foundation
import UIKit

/*
 Controller for sheet view used to supply and save a new site
 */
class AddSiteController: UIViewController, UITextFieldDelegate {
    
    private let api = CurrentEnvironment.api
    private var model: EntitiesViewModel
    
    init(entitiesViewModel: EntitiesViewModel) {
        self.model = entitiesViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        // text field
        view.addSubview(stackView)
        stackView.addArrangedSubview(textField)
        textField.placeholder = "Enter site name"
        
        // save button
        let buttonModel = ButtonModel(title: ButtonModel.Title.text("Save"), action: {self.doSave()}, isEnabled: true)
        actionButton.set(model: buttonModel)
        stackView.addArrangedSubview(actionButton)
        
        // layout
        NSLayoutConstraint.activate([
            textField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),

            actionButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10.0),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        ])
    }
    
    // MARK: - UI controls
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16.0
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)

        return stackView
    }()
    
    private let actionButton: TappableButton = {
        let button = RoundedTappableButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 18.0)
        return button
    }()
    
    private let textField: TextField = {
        let textField = TextField()
        textField.textColor = .label
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
        return textField
    }()
    
    // MARK: - Delegate
    private func doSave() -> Void? {
        if(textField.hasText) {
            // set action button to spinner / working
            actionButton.set(title: .loading)
            
            // save new site via API
            api.addSite(name: textField.text!, completion: { result in
                // trigger refresh of EntitiesViewModel which will also resync local database to cloud table
                self.model.sync()
                
                // dismiss the view
                self.dismiss(animated: true)
            })
        }
        // just ignore the tap if there is no text in the text box - tap outside sheet to dismiss
        return ()
    }
    
}
