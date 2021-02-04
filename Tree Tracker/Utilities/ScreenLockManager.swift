import UIKit

protocol ScreenLockManaging {
    func disableLocking()
    func allowLocking()
}

struct UIScreenLockManager: ScreenLockManaging {
    func disableLocking() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func allowLocking() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
