// Image (image) — Turbo Rainbow Dissolver by leon
// https://www.shadertoy.com/view/NdVfRh


// popping shapes in a turbo rainbow dissolver

// main code is in Buffer A
// Buffer B is a minimal temporal anti aliasing
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    fragColor = texture(iChannel0, uv);
}