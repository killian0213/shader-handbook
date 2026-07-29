// Image (image) — Cube Falls by mhnewman
// https://www.shadertoy.com/view/dtSGWd

// Monte carlo ambient occlusion, depth of field, spherical aberration,
// and anti aliasing using accumulation buffer.
//
// Based on www.shadertoy.com/view/llccD2 Monte Carlo Accumulation.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = pow(texture(iChannel0, fragCoord / iResolution.xy), vec4(0.7)) * 1.3;
#if SCENE_TIME > 0
    float t = fract(iTime / float(SCENE_TIME));
    fragColor *= (1.0 - exp(-50.0 * t)) * (1.0 - exp(-50.0 * (1.0 - t)));
#endif
}