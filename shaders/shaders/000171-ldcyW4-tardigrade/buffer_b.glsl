// Buf B (buffer) — tardigrade by zguerrero
// https://www.shadertoy.com/view/ldcyW4

//BlurPass 1

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = BlurPass(fragCoord.xy, iResolution.xy, 1.5, iChannel0);
}