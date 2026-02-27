import SwiftUI
import Combine

/// Handles gesture recognition for transform operations
class TransformGestureHandler: ObservableObject {
    @Published var currentTransform: Transform = .identity

    private var lastTranslation: CGSize = .zero
    private var lastScale: CGFloat = 1.0
    private var lastRotation: CGFloat = 0.0

    // MARK: - Drag Gestures

    /// Handle drag gesture changes
    func handleDrag(_ value: DragGesture.Value, current: Transform) -> Transform {
        let translation = value.translation
        let delta = CGSize(
            width: translation.width - lastTranslation.width,
            height: translation.height - lastTranslation.height
        )

        lastTranslation = translation

        return Transform(
            translation: CGPoint(
                x: current.translation.x + delta.width,
                y: current.translation.y + delta.height
            ),
            scale: current.scale,
            rotation: current.rotation
        )
    }

    /// Handle drag gesture end
    func handleDragEnded() {
        lastTranslation = .zero
    }

    // MARK: - Pinch Gestures

    /// Handle pinch/magnification gesture
    func handlePinch(_ value: MagnificationGesture.Value, current: Transform) -> Transform {
        let scale = value / lastScale
        lastScale = value

        // Clamp scale to reasonable limits
        let newScale = max(0.1, min(5.0, current.scale * scale))

        return Transform(
            translation: current.translation,
            scale: newScale,
            rotation: current.rotation
        )
    }

    /// Handle pinch gesture end
    func handlePinchEnded() {
        lastScale = 1.0
    }

    // MARK: - Rotation Gestures

    /// Handle rotation gesture
    func handleRotation(_ value: CGFloat, current: Transform) -> Transform {
        let rotationDelta = value - lastRotation
        lastRotation = value

        let newRotation = current.rotation + rotationDelta

        return Transform(
            translation: current.translation,
            scale: current.scale,
            rotation: newRotation
        )
    }

    /// Handle rotation gesture end
    func handleRotationEnded() {
        lastRotation = 0.0
    }

    // MARK: - Reset

    /// Reset transform to identity
    func reset() {
        currentTransform = .identity
        lastTranslation = .zero
        lastScale = 1.0
        lastRotation = 0.0
    }
}
