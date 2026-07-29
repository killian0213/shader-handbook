// Buffer D (buffer) — Volume Path Tracing on Bunny by SebH
// https://www.shadertoy.com/view/7dVGWR

// Combine the just traced BufferC with history BufferD
// Reset accumulation if needed according to input

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float2 uv = fragCoord.xy / iResolution.xy;
    float time = iTime;
    
    bool bFullReset = FullReset;  
    bFullReset = bFullReset || texelFetch(iChannel2, ivec2(PIX_RESETACCUM), 0).x > 0.0f;
    
    fragColor = texture(iChannel0, uv) + (bFullReset ? float4(0.0f) : texture(iChannel1, uv));
}