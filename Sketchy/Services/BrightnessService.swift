import UIKit

/// Service for managing screen brightness
class BrightnessService {
    private var originalBrightness: CGFloat = 0.5

    init() {
        saveOriginalBrightness()
    }

    // MARK: - Brightness Management

    private func saveOriginalBrightness() {
        originalBrightness = UIScreen.main.brightness
    }

    /// Set screen brightness
    /// - Parameter value: Brightness value between 0.0 and 1.0
    func setBrightness(_ value: Double) {
        let systemBrightness = max(0.5, min(1.0, value))

        DispatchQueue.main.async {
            UIScreen.main.brightness = systemBrightness
        }
    }

    /// Restore brightness to original value
    func restoreBrightness() {
        DispatchQueue.main.async { [weak self] in
            UIScreen.main.brightness = self?.originalBrightness ?? 0.5
        }
    }

    /// Get maximum brightness level supported by system
    func getMaxBrightness() -> CGFloat {
        return 1.0  // iOS system limitation
    }
}
