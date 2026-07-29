// Buf C (buffer) — tardigrade by zguerrero
// https://www.shadertoy.com/view/ldcyW4

//BlurPass 2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = BlurPass(fragCoord.xy, iResolution.xy, 3.0, iChannel0);
}