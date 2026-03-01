import UIKit

/// Service for managing screen brightness
class BrightnessService {
    private var originalBrightness: CGFloat

    init() {
        // Capture the current device brightness
        self.originalBrightness = UIScreen.main.brightness
    }

    // MARK: - Brightness Management

    /// Set screen brightness
    /// - Parameter value: Brightness value between 0.0 and 1.0
    func setBrightness(_ value: Double) {
        // Clamp to valid range 0.0 - 1.0 (allowing full 0-100%)
        let systemBrightness = max(0.0, min(1.0, value))

        DispatchQueue.main.async {
            UIScreen.main.brightness = systemBrightness
        }
    }

    /// Restore brightness to original device value
    func restoreBrightness() {
        DispatchQueue.main.async { [weak self] in
            UIScreen.main.brightness = self?.originalBrightness ?? UIScreen.main.brightness
        }
    }

    /// Get maximum brightness level supported by system
    func getMaxBrightness() -> CGFloat {
        return 1.0  // iOS system limitation
    }
}
