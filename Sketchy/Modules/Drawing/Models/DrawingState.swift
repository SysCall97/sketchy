import Foundation

/// Represents the complete state of a drawing session
struct DrawingState {
    enum DrawingMode {
        case abovePaper   // Camera overlay mode
        case underPaper   // Lightbox mode
    }

    enum TransformTarget {
        case template
        case camera
    }

    // MARK: - Properties

    let mode: DrawingMode
    let templateTransform: Transform
    let cameraTransform: Transform
    let opacity: Double                    // 0.0 - 1.0
    let brightness: Double                 // 0.0 - 1.0
    let isFlashlightOn: Bool
    let transformTarget: TransformTarget
    let isTransformLocked: Bool

    // MARK: - Initial State

    static let initial = DrawingState(
        mode: DrawingState.DrawingMode.abovePaper,
        templateTransform: Transform.identity,
        cameraTransform: Transform.identity,
        opacity: 0.5,
        brightness: 0.5,
        isFlashlightOn: false,
        transformTarget: DrawingState.TransformTarget.template,
        isTransformLocked: false
    )

    // MARK: - Builder Pattern

    func with(mode: DrawingMode? = nil,
              templateTransform: Transform? = nil,
              cameraTransform: Transform? = nil,
              opacity: Double? = nil,
              brightness: Double? = nil,
              isFlashlightOn: Bool? = nil,
              transformTarget: TransformTarget? = nil,
              isTransformLocked: Bool? = nil) -> DrawingState {
        DrawingState(
            mode: mode ?? self.mode,
            templateTransform: templateTransform ?? self.templateTransform,
            cameraTransform: cameraTransform ?? self.cameraTransform,
            opacity: opacity ?? self.opacity,
            brightness: brightness ?? self.brightness,
            isFlashlightOn: isFlashlightOn ?? self.isFlashlightOn,
            transformTarget: transformTarget ?? self.transformTarget,
            isTransformLocked: isTransformLocked ?? self.isTransformLocked
        )
    }
}

// MARK: - Equatable

extension DrawingState: Equatable {
    static func == (lhs: DrawingState, rhs: DrawingState) -> Bool {
        return lhs.mode == rhs.mode &&
               lhs.templateTransform == rhs.templateTransform &&
               lhs.cameraTransform == rhs.cameraTransform &&
               lhs.opacity == rhs.opacity &&
               lhs.brightness == rhs.brightness &&
               lhs.isFlashlightOn == rhs.isFlashlightOn &&
               lhs.transformTarget == rhs.transformTarget &&
               lhs.isTransformLocked == rhs.isTransformLocked
    }
}

// MARK: - CustomStringConvertible

extension DrawingState: CustomStringConvertible {
    var description: String {
        return """
        DrawingState(
            mode: \(mode),
            opacity: \(opacity),
            brightness: \(brightness),
            flashlight: \(isFlashlightOn),
            transformTarget: \(transformTarget),
            locked: \(isTransformLocked)
        )
        """
    }
}
