import Foundation
import Metal
import CoreVideo

/// Rendering configuration passed to Metal renderer
struct RenderState {
    let mode: DrawingState.DrawingMode
    let templateTransform: Transform
    let cameraTransform: Transform
    let opacity: Float
    let brightness: Float

    /// Textures (set during rendering)
    var templateTexture: MTLTexture?
    var cameraTexture: CVPixelBuffer?

    static let initial = RenderState(
        mode: DrawingState.DrawingMode.abovePaper,
        templateTransform: Transform.identity,
        cameraTransform: Transform.identity,
        opacity: 0.5,
        brightness: 0.5,
        templateTexture: nil,
        cameraTexture: nil
    )

    /// Create RenderState from DrawingState
    init(from state: DrawingState) {
        self.mode = state.mode
        self.templateTransform = state.templateTransform
        self.cameraTransform = state.cameraTransform
        self.opacity = Float(state.opacity)
        self.brightness = Float(state.brightness)
        self.templateTexture = nil
        self.cameraTexture = nil
    }

    init(mode: DrawingState.DrawingMode,
         templateTransform: Transform,
         cameraTransform: Transform,
         opacity: Float,
         brightness: Float,
         templateTexture: MTLTexture? = nil,
         cameraTexture: CVPixelBuffer? = nil) {
        self.mode = mode
        self.templateTransform = templateTransform
        self.cameraTransform = cameraTransform
        self.opacity = opacity
        self.brightness = brightness
        self.templateTexture = templateTexture
        self.cameraTexture = cameraTexture
    }
}
