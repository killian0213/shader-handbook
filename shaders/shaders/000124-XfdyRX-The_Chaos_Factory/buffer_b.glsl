// Buffer B (buffer) — The Chaos Factory by cmgz
// https://www.shadertoy.com/view/XfdyRX

// Physics Iteration

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    physicsIteration(fragColor, fragCoord, iResolution.xy, iChannel0);
}