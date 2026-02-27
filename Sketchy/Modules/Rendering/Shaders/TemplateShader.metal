//
//  TemplateShader.metal
//  Sketchy
//
//  Fragment shader for rendering template with opacity and brightness
//

#include <metal_stdlib>
using namespace metal;

// Vertex output structure
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Vertex shader
vertex VertexOut template_vertex_shader(uint vertexID [[vertex_id]],
                                       constant float4 *positions [[buffer(0)]],
                                       constant float2 *texCoords [[buffer(1)]]) {
    VertexOut out;
    out.position = positions[vertexID];
    out.texCoord = texCoords[vertexID];
    return out;
}

// Fragment shader with opacity and brightness
fragment float4 template_fragment_shader(VertexOut in [[stage_in]],
                                        texture2d<float> texture [[texture(0)]],
                                        constant float &opacity [[buffer(0)]],
                                        constant float &brightness [[buffer(1)]]) {
    // Configure texture sampler
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear);

    // Sample texture
    float4 color = texture.sample(texSampler, in.texCoord);

    // Apply brightness (0.5 = normal, 1.0 = 1.5x bright)
    color.rgb *= (1.0 + brightness * 0.5);

    // Apply opacity
    color.a *= opacity;

    return color;
}
