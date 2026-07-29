// Buffer B (buffer) — Data Moshing Effect by slerpy
// https://www.shadertoy.com/view/tlsSRs

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // fetch buffer a
    ivec2 u = ivec2(fragCoord);
    vec4 tex = texelFetch(iChannel0, u, 0);
    
    // manual color override
    if(tex.w < .0)
    {
        fragColor = tex;
        return;
    }
    
    // fetch buffer b
    if(iFrame % 8 == 0)u = ivec2(tex.xy);
    fragColor = texelFetch(iChannel1, u, 0);
}