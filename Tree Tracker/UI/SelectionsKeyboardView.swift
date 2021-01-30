import UIKit

final class SelectionsKeyboardView: UIInputView, UIPickerViewDataSource, UIPickerViewDelegate {
    private lazy var picker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.dataSource = self
        picker.delegate = self

        return picker
    }()

    private lazy var heightConstraint = picker.heightAnchor.constraint(equalToConstant: 160.0)

    private let selections: [String]
    private let indexSelected: ((Int) -> Void)?

    init(selections: [String], initialIndexSelected: Int? = nil, indexSelected: ((Int) -> Void)?) {
        self.selections = selections
        self.indexSelected = indexSelected
        super.init(frame: .zero, inputViewStyle: .keyboard)

        if let initialIndexSelected = initialIndexSelected {
            picker.selectRow(initialIndexSelected, inComponent: 0, animated: false)
        }

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = true
        allowsSelfSizing = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]

        addSubview(picker)

        NSLayoutConstraint.activate([
            picker.safeAreaLayoutGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8.0),
            picker.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18.0),
            picker.centerXAnchor.constraint(equalTo: centerXAnchor),
            heightConstraint,
        ])
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return selections[safe: row]
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selections.count
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        indexSelected?(row)
    }
}
