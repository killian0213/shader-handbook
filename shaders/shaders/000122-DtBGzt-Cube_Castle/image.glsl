// Image (image) — Cube Castle by mhnewman
// https://www.shadertoy.com/view/DtBGzt

// Monte carlo ambient occlusion, depth of field, spherical aberration,
// and anti aliasing using accumulation buffer.
//
// Based on www.shadertoy.com/view/llccD2 Monte Carlo Accumulation.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = pow(texture(iChannel0, fragCoord / iResolution.xy), vec4(0.75));
}