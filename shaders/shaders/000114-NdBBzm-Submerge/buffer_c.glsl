// Buffer C (buffer) — Submerge by Xor
// https://www.shadertoy.com/view/NdBBzm

//Blur pass 2
void mainImage( out vec4 fragColor, vec2 fragCoord)
{
    vec2 texel = 1.0 / iResolution.xy;
    vec2 uv = fragCoord * texel;
    vec4 blur = fibonacci_blur(iChannel1, uv, texel, -36.0);
    fragColor = blur * TINT;
}