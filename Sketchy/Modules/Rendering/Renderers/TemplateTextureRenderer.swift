import Metal
import MetalKit
import UIKit

/// Renders template texture as a textured quad with opacity and brightness
class TemplateTextureRenderer {
    private let device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer
    private var texture: MTLTexture?

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

        // Create pipeline state
        self.pipelineState = createPipelineState(device: device)
    }

    private func createPipelineState(device: MTLDevice) -> MTLRenderPipelineState? {
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "template_vertex_shader"),
              let fragmentFunction = library.makeFunction(name: "template_fragment_shader") else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Enable blending for opacity
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    // MARK: - Texture Loading

    func loadTexture(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let textureLoader = MTKTextureLoader(device: device)
        texture = try? textureLoader.newTexture(cgImage: cgImage, options: [
            .SRGB: false,
            .textureUsage: MTLTextureUsage.shaderRead.rawValue
        ])
    }

    // MARK: - Rendering

    func render(texture: MTLTexture,
                transform: Transform,
                opacity: Float,
                brightness: Float,
                commandBuffer: MTLCommandBuffer,
                renderPassDescriptor: MTLRenderPassDescriptor) {
        guard let pipelineState = pipelineState,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        // Set vertex buffer
        let vertexBufferOffset = 0
        renderEncoder.setVertexBuffer(vertexBuffer, offset: vertexBufferOffset, index: 0)

        // Create transform matrix
        var transformMatrix = transform.matrix

        // Set uniforms
        var opacityValue = opacity
        var brightnessValue = brightness

        renderEncoder.setVertexBytes(&transformMatrix,
                                    length: MemoryLayout<simd_float4x4>.size,
                                    index: 1)
        renderEncoder.setFragmentBytes(&opacityValue,
                                      length: MemoryLayout<Float>.size,
                                      index: 0)
        renderEncoder.setFragmentBytes(&brightnessValue,
                                      length: MemoryLayout<Float>.size,
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
