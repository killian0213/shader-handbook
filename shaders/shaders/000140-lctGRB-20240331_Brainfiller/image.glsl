// Image (image) — 20240331_Brainfiller by 0b5vr
// https://www.shadertoy.com/view/lctGRB

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texture( iChannel0, fragCoord / iResolution.xy );
}