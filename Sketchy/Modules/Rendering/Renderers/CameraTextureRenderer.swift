import Metal
import MetalKit
import CoreVideo

/// Renders camera feed as a full-screen textured quad
class CameraTextureRenderer {
    private let device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer
    private var textureCache: CVMetalTextureCache?

    // Quad vertices (X, Y, U, V)
    private let quadVertices: [Float] = [
        -1.0, -1.0, 0.0, 1.0,  // Bottom-left
         1.0, -1.0, 1.0, 1.0,  // Bottom-right
        -1.0,  1.0, 0.0, 0.0,  // Top-left
         1.0,  1.0, 1.0, 0.0   // Top-right
    ]

    init?(device: MTLDevice) {
        self.device = device

        // Create vertex buffer
        guard let buffer = device.makeBuffer(bytes: quadVertices,
                                           length: quadVertices.count * MemoryLayout<Float>.size,
                                           options: []) else {
            return nil
        }
        self.vertexBuffer = buffer

        // Create texture cache
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)

        // Create pipeline state
        self.pipelineState = createPipelineState(device: device)
    }

    private func createPipelineState(device: MTLDevice) -> MTLRenderPipelineState? {
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "camera_vertex_shader"),
              let fragmentFunction = library.makeFunction(name: "camera_fragment_shader") else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    // MARK: - Texture Loading

    func loadTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let textureCache = textureCache else { return nil }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)

        var metalTexture: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &metalTexture
        )

        guard result == kCVReturnSuccess,
              let texture = metalTexture else {
            return nil
        }

        return CVMetalTextureGetTexture(texture)
    }

    // MARK: - Rendering

    func render(pixelBuffer: CVPixelBuffer,
                transform: Transform,
                commandBuffer: MTLCommandBuffer,
                renderPassDescriptor: MTLRenderPassDescriptor) {
        guard let pipelineState = pipelineState,
              let texture = loadTexture(from: pixelBuffer),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        // Set vertex buffer
        let vertexBufferOffset = 0
        renderEncoder.setVertexBuffer(vertexBuffer, offset: vertexBufferOffset, index: 0)

        // Create transform matrix
        var transformMatrix = transform.matrix
        renderEncoder.setVertexBytes(&transformMatrix,
                                    length: MemoryLayout<simd_float4x4>.size,
                                    index: 1)

        // Set texture
        renderEncoder.setFragmentTexture(texture, index: 0)

        // Draw quad
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                    vertexStart: 0,
                                    vertexCount: 4)

        renderEncoder.endEncoding()
    }
}
