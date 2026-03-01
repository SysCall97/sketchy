import Foundation

/// Project model - Saved drawing state with template
struct ProjectModel: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    let templateID: UUID
    let mode: DrawingState.DrawingMode
    let templateTransform: Transform
    let cameraTransform: Transform
    let opacity: Double
    let brightness: Double
    let isTransformLocked: Bool
    let isFlashlightOn: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        templateID: UUID,
        mode: DrawingState.DrawingMode,
        templateTransform: Transform,
        cameraTransform: Transform,
        opacity: Double,
        brightness: Double,
        isTransformLocked: Bool,
        isFlashlightOn: Bool,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.templateID = templateID
        self.mode = mode
        self.templateTransform = templateTransform
        self.cameraTransform = cameraTransform
        self.opacity = opacity
        self.brightness = brightness
        self.isTransformLocked = isTransformLocked
        self.isFlashlightOn = isFlashlightOn
        self.createdAt = createdAt
    }

    /// Create project from DrawingState
    static func from(
        name: String,
        templateID: UUID,
        state: DrawingState
    ) -> ProjectModel {
        return ProjectModel(
            name: name,
            templateID: templateID,
            mode: state.mode,
            templateTransform: state.templateTransform,
            cameraTransform: state.cameraTransform,
            opacity: state.opacity,
            brightness: state.brightness,
            isTransformLocked: state.isTransformLocked,
            isFlashlightOn: state.isFlashlightOn
        )
    }

    /// Convert to DrawingState for loading
    func toDrawingState() -> DrawingState {
        return DrawingState(
            mode: mode,
            templateTransform: templateTransform,
            cameraTransform: cameraTransform,
            opacity: opacity,
            brightness: brightness,
            isFlashlightOn: isFlashlightOn,
            transformTarget: .template,
            isTransformLocked: isTransformLocked,
            selectedTab: mode == .underPaper ? .brightness : .opacity,
            captureMode: .photo,
            isRecording: false,
            isFlashlightAvailable: true
        )
    }
}
