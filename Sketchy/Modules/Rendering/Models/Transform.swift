import Foundation
import CoreGraphics
import simd

/// Represents a 2D transform with translation, scale, and rotation
struct Transform: Equatable, Codable {
    let translation: CGPoint
    let scale: CGFloat
    let rotation: CGFloat  // Reserved for future use

    /// Identity transform (no transformation)
    static let identity = Transform(translation: .zero, scale: 1.0, rotation: 0)

    /// Creates a new transform with updated properties
    func with(translation: CGPoint? = nil,
              scale: CGFloat? = nil,
              rotation: CGFloat? = nil) -> Transform {
        Transform(
            translation: translation ?? self.translation,
            scale: scale ?? self.scale,
            rotation: rotation ?? self.rotation
        )
    }

    /// Converts the transform to a Metal matrix for rendering
    var matrix: simd_float4x4 {
        var matrix = matrix_identity_float4x4

        // Apply scale
        let scaleFactor = Float(scale)
        matrix = matrix_scaled(by: float3(scaleFactor, scaleFactor, 1.0))

        // Apply rotation
        let rotationRadians = Float(rotation)
        matrix = matrix_rotated(by: rotationRadians)

        // Apply translation
        matrix = matrix_translated(by: float3(
            Float(translation.x),
            Float(translation.y),
            0
        ))

        return matrix
    }
}

// MARK: - Metal Matrix Helpers

private func matrix_scaled(by scale: float3) -> simd_float4x4 {
    var matrix = matrix_identity_float4x4
    matrix[0, 0] = scale.x
    matrix[1, 1] = scale.y
    matrix[2, 2] = scale.z
    return matrix
}

private func matrix_translated(by translation: float3) -> simd_float4x4 {
    var matrix = matrix_identity_float4x4
    matrix[3, 0] = translation.x
    matrix[3, 1] = translation.y
    matrix[3, 2] = translation.z
    return matrix
}

private func matrix_rotated(by angle: Float) -> simd_float4x4 {
    let cos = cosf(angle)
    let sin = sinf(angle)
    var matrix = matrix_identity_float4x4
    matrix[0, 0] = cos
    matrix[0, 1] = -sin
    matrix[1, 0] = sin
    matrix[1, 1] = cos
    return matrix
}
