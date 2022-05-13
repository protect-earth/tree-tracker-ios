import Foundation
import UIKit

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

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(textField)
        textField.placeholder = "Enter site name"
        
        // save button
        let buttonModel = ButtonModel(title: ButtonModel.Title.text("Save"), action: {self.doSave()}, isEnabled: true)
        actionButton.set(model: buttonModel)
        view.addSubview(actionButton)
        
        // layout
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16.0),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -100.0),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            actionButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10.0),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
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
