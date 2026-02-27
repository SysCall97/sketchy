//
//  CameraShader.metal
//  Sketchy
//
//  Fragment shader for rendering camera feed
//

#include <metal_stdlib>
using namespace metal;

// Vertex output structure
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Vertex shader
vertex VertexOut camera_vertex_shader(uint vertexID [[vertex_id]],
                                     constant float4 *positions [[buffer(0)]],
                                     constant float2 *texCoords [[buffer(1)]]) {
    VertexOut out;
    out.position = positions[vertexID];
    out.texCoord = texCoords[vertexID];
    return out;
}

// Fragment shader for camera texture (basic rendering)
fragment float4 camera_fragment_shader(VertexOut in [[stage_in]],
                                       texture2d<float> texture [[texture(0)]]) {
    // Configure texture sampler
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear);

    // Sample and return texture color
    return texture.sample(texSampler, in.texCoord);
}
