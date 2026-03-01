import Foundation
import UIKit

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

    enum ControlTab {
        case opacity
        case scaling
        case camera
        case flashlight
        case brightness
    }

    enum CaptureMode {
        case photo
        case video
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
    let selectedTab: ControlTab
    let captureMode: CaptureMode
    let isRecording: Bool
    let isFlashlightAvailable: Bool

    // MARK: - Initial State

    static let initial = DrawingState(
        mode: DrawingState.DrawingMode.abovePaper,
        templateTransform: Transform.identity,
        cameraTransform: Transform.identity,
        opacity: 0.5,
        brightness: Double(UIScreen.main.brightness),  // Use current device brightness
        isFlashlightOn: false,
        transformTarget: DrawingState.TransformTarget.template,
        isTransformLocked: false,
        selectedTab: DrawingState.ControlTab.opacity,
        captureMode: DrawingState.CaptureMode.photo,
        isRecording: false,
        isFlashlightAvailable: true
    )

    // MARK: - Builder Pattern

    func with(mode: DrawingMode? = nil,
              templateTransform: Transform? = nil,
              cameraTransform: Transform? = nil,
              opacity: Double? = nil,
              brightness: Double? = nil,
              isFlashlightOn: Bool? = nil,
              transformTarget: TransformTarget? = nil,
              isTransformLocked: Bool? = nil,
              selectedTab: ControlTab? = nil,
              captureMode: CaptureMode? = nil,
              isRecording: Bool? = nil,
              isFlashlightAvailable: Bool? = nil) -> DrawingState {
        DrawingState(
            mode: mode ?? self.mode,
            templateTransform: templateTransform ?? self.templateTransform,
            cameraTransform: cameraTransform ?? self.cameraTransform,
            opacity: opacity ?? self.opacity,
            brightness: brightness ?? self.brightness,
            isFlashlightOn: isFlashlightOn ?? self.isFlashlightOn,
            transformTarget: transformTarget ?? self.transformTarget,
            isTransformLocked: isTransformLocked ?? self.isTransformLocked,
            selectedTab: selectedTab ?? self.selectedTab,
            captureMode: captureMode ?? self.captureMode,
            isRecording: isRecording ?? self.isRecording,
            isFlashlightAvailable: isFlashlightAvailable ?? self.isFlashlightAvailable
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
               lhs.isTransformLocked == rhs.isTransformLocked &&
               lhs.selectedTab == rhs.selectedTab &&
               lhs.captureMode == rhs.captureMode &&
               lhs.isRecording == rhs.isRecording &&
               lhs.isFlashlightAvailable == rhs.isFlashlightAvailable
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
