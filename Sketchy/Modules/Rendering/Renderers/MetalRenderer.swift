import Metal
import MetalKit
import UIKit

/// Main Metal renderer that coordinates template and camera rendering
class MetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let templateRenderer: TemplateTextureRenderer
    private let cameraRenderer: CameraTextureRenderer

    var renderState: RenderState {
        didSet {
            needsRedraw = true
        }
    }

    private var needsRedraw = true
    private var currentTemplateTexture: MTLTexture?

    init?(view: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }

        self.device = device
        self.commandQueue = device.makeCommandQueue()!

        guard let templateRenderer = TemplateTextureRenderer(device: device),
              let cameraRenderer = CameraTextureRenderer(device: device) else {
            return nil
        }

        self.templateRenderer = templateRenderer
        self.cameraRenderer = cameraRenderer
        self.renderState = .initial

        super.init()

        view.device = device
        view.delegate = self
        view.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        view.framebufferOnly = false
        view.isPaused = false
        view.enableSetNeedsDisplay = false
    }

    // MARK: - Texture Management

    func updateTemplateImage(_ image: UIImage) {
        currentTemplateTexture = nil
        templateRenderer.loadTexture(from: image)
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle viewport resize if needed
    }

    func draw(in view: MTKView) {
        guard !needsRedraw,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        // Configure background based on mode
        if renderState.mode == .underPaper {
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
                red: 1, green: 1, blue: 1, alpha: 1
            )
        } else {
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
                red: 0, green: 0, blue: 0, alpha: 1
            )
        }

        // Render camera feed (Above mode only)
        if renderState.mode == .abovePaper,
           let cameraTexture = renderState.cameraTexture {
            cameraRenderer.render(
                pixelBuffer: cameraTexture,
                transform: renderState.cameraTransform,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        }

        // Render template
        if let templateTexture = currentTemplateTexture {
            templateRenderer.render(
                texture: templateTexture,
                transform: renderState.templateTransform,
                opacity: renderState.opacity,
                brightness: renderState.brightness,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()

        needsRedraw = false
    }
}
