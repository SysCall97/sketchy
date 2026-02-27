import Foundation
import CoreGraphics

// MARK: - CGFloat Extensions

extension CGFloat {
    /// Clamp value between min and max
    func clamped(min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(Swift.max(self, min), max)
    }

    /// Convert to degrees
    var degrees: CGFloat {
        return self * 180.0 / .pi
    }

    /// Convert from degrees
    static func degrees(_ value: CGFloat) -> CGFloat {
        return value * .pi / 180.0
    }
}
