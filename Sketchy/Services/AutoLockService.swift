import UIKit

/// Service for managing screen auto-lock behavior
class AutoLockService {
    private var isDisabled = false

    /// Disable screen auto-lock (useful during drawing)
    func disableAutoLock() {
        guard !isDisabled else { return }
        UIApplication.shared.isIdleTimerDisabled = true
        isDisabled = true
    }

    /// Enable screen auto-lock
    func enableAutoLock() {
        guard isDisabled else { return }
        UIApplication.shared.isIdleTimerDisabled = false
        isDisabled = false
    }

    deinit {
        enableAutoLock()  // Cleanup
    }
}
