// Image (image) — Sinking by zguerrero
// https://www.shadertoy.com/view/MsVfWy

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float r = iResolution.x / iResolution.y;
    vec2 uv = fragCoord/iResolution.xy;
    
    float v = max(0.0, length(uv - 0.5) * 7.0 - 2.0);
    vec4 col = textureLod(iChannel0, uv, v);

    fragColor = pow(col, vec4(2.0));
}