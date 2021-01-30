import Foundation

struct KeyboardAccessory: Hashable {
    let leftButton: ButtonModel?
    let rightButton: ButtonModel?

    static func `default`(cancel: (() -> Void)? = nil, done: (() -> Void)? = nil) -> KeyboardAccessory {
        let cancelButton = ButtonModel(
            title: .text("Cancel"),
            action: { cancel?() },
            isEnabled: true
        )

        let doneButton = ButtonModel(
            title: .text("Done"),
            action: { done?() },
            isEnabled: true
        )
        return KeyboardAccessory(leftButton: cancelButton, rightButton: doneButton)
    }

    static func done(action: (() -> Void)? = nil) -> KeyboardAccessory {
        let doneButton = ButtonModel(
            title: .text("Done"),
            action: { action?() },
            isEnabled: true
        )
        return KeyboardAccessory(leftButton: nil, rightButton: doneButton)
    }
}
