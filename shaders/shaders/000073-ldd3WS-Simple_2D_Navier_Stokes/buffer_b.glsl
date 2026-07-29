// Buf B (buffer) — Simple 2D Navier Stokes by Wumpf
// https://www.shadertoy.com/view/ldd3WS

// Compute divergence.

#define VelocityTexture iChannel0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 inverseResolution = vec2(1.0) / iResolution.xy;
    vec2 uv = fragCoord.xy * inverseResolution;
    
    // Obstacle?
    if(texture(VelocityTexture, uv).z > 0.0)
    {
        fragColor = vec4(0.0);
        return;
    }

    float x0 = texture(VelocityTexture, uv - vec2(inverseResolution.x, 0)).x;
    float x1 = texture(VelocityTexture, uv + vec2(inverseResolution.x, 0)).x;
    float y0 = texture(VelocityTexture, uv - vec2(0, inverseResolution.y)).y;
    float y1 = texture(VelocityTexture, uv + vec2(0, inverseResolution.y)).y;
    float divergence = ((x1-x0) + (y1-y0)) * 0.5;
    fragColor = vec4(divergence);
}