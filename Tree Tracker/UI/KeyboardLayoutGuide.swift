// MIT License
//
// Copyright (c) 2017 S4cha
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Courtesy of: https://github.com/freshOS/KeyboardLayoutGuide

import UIKit

@dynamicCallable
final class ActionObject: Equatable {
    let id: String
    let action: (() -> Void)?

    init(id: String = UUID().uuidString, action: (() -> Void)?) {
        self.id = id
        self.action = action
    }

    func dynamicallyCall(withArguments: [String]) {
        action?()
    }

    static func == (lhs: ActionObject, rhs: ActionObject) -> Bool {
        return lhs.id == rhs.id
    }
}

internal class SharedKeyboard {
    static let shared = SharedKeyboard()
    var currentHeight: CGFloat = 0
}

extension UIView {
    private enum Identifiers {
        static var usingSafeArea = "KeyboardLayoutGuideUsingSafeArea"
        static var notUsingSafeArea = "KeyboardLayoutGuide"
    }

    /// A layout guide representing the inset for the keyboard.
    /// Use this layout guide’s top anchor to create constraints pinning to the top of the keyboard or the bottom of safe area.
    public var keyboardLayoutGuide: UILayoutGuide {
        getOrCreateKeyboardLayoutGuide(identifier: Identifiers.usingSafeArea, usesSafeArea: true)
    }

    /// A layout guide representing the inset for the keyboard.
    /// Use this layout guide’s top anchor to create constraints pinning to the top of the keyboard or the bottom of the view.
    public var keyboardLayoutGuideNoSafeArea: UILayoutGuide {
        getOrCreateKeyboardLayoutGuide(identifier: Identifiers.notUsingSafeArea, usesSafeArea: false)
    }

    private func getOrCreateKeyboardLayoutGuide(identifier: String, usesSafeArea: Bool) -> UILayoutGuide {
        if let existing = layoutGuides.first(where: { $0.identifier == identifier }) {
            return existing
        }
        let new = KeyboardLayoutGuide()
        new.usesSafeArea = usesSafeArea
        new.identifier = identifier
        addLayoutGuide(new)
        new.setUp()
        return new
    }
}

open class KeyboardLayoutGuide: UILayoutGuide {
    public var usesSafeArea = true {
        didSet {
            updateButtomAnchor()
        }
    }

    private var bottomConstraint: NSLayoutConstraint?

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        super.init()
        // Observe keyboardWillChangeFrame notifications
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    internal func setUp() {
        guard let view = owningView else { return }

        let keyboard = SharedKeyboard.shared
        NSLayoutConstraint.activate(
            [
                heightAnchor.constraint(equalToConstant: keyboard.currentHeight),
                leftAnchor.constraint(equalTo: view.leftAnchor),
                rightAnchor.constraint(equalTo: view.rightAnchor),
            ]
        )
        updateButtomAnchor()
    }

    func updateButtomAnchor() {
        if let bottomConstraint = bottomConstraint {
            bottomConstraint.isActive = false
        }

        guard let view = owningView else { return }

        let viewBottomAnchor: NSLayoutYAxisAnchor
        if #available(iOS 11.0, *), usesSafeArea {
            viewBottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        } else {
            viewBottomAnchor = view.bottomAnchor
        }

        bottomConstraint = bottomAnchor.constraint(equalTo: viewBottomAnchor)
        bottomConstraint?.isActive = true
    }

    @objc
    private func keyboardWillChangeFrame(_ note: UIKit.Notification) {
        guard var height = note.keyboardHeight, let duration = note.animationDuration, owningView?.window != nil else { return }

        if #available(iOS 11.0, *), usesSafeArea, height > 0, let bottom = owningView?.safeAreaInsets.bottom {
            height -= bottom
        }
        heightConstraint?.constant = height
        SharedKeyboard.shared.currentHeight = height

        UIView.animate(withDuration: TimeInterval(duration)) {
            self.owningView?.layoutIfNeeded()
        }
    }
}

// MARK: - Helpers

extension UILayoutGuide {
    internal var heightConstraint: NSLayoutConstraint? {
        return owningView?.constraints.first {
            $0.firstItem as? UILayoutGuide == self && $0.firstAttribute == .height
        }
    }
}

extension UIKit.Notification {
    var keyboardHeight: CGFloat? {
        guard let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return nil
        }
        let screenHeight = UIApplication.shared.keyWindow?.bounds.height ?? UIScreen.main.bounds.height
        let keyboardHeight = screenHeight - keyboardFrame.cgRectValue.minY
        return keyboardHeight >= 0.0 ? keyboardHeight : 0.0
    }

    var animationDuration: CGFloat? {
        return userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? CGFloat
    }
}

// Credits to John Gibb for this nice helper :)
// https://stackoverflow.com/questions/1536923/determine-if-uiview-is-visible-to-the-user
func isVisible(view: UIView) -> Bool {
    func isVisible(view: UIView, inView: UIView?) -> Bool {
        guard let inView = inView else { return true }
        let viewFrame = inView.convert(view.bounds, from: view)
        if viewFrame.intersects(inView.bounds) {
            return isVisible(view: view, inView: inView.superview)
        }
        return false
    }
    return isVisible(view: view, inView: view.superview)
}
