// Image (image) — Single Pass Field Flow by myth0genesis
// https://www.shadertoy.com/view/clVSW3

// 2023 myth0genesis

// It turns out that davidar's wind flow map effect https://www.shadertoy.com/view/4sKBz3
// only needs a single buffer for every stage of the simulation
// without any additional overhead, provided you're okay with sacrificing
// the ability to choose any color you want for the particles and tracers.
// I used a modified version of nimitz's FBM https://www.shadertoy.com/view/3l23Rh for the field,
// normalized from -1.0 to 1.0 and sans some of the frequency-wise scaling, to drive the particles' velocities,
// as it can give you a lot of variation with very few iterations, which enabled the ability
// to sample a larger area without a performance hit.
// I tried my best to regulate the speed (via frmAdj) in order to prevent pixels from traveling
// outside of the sample area or from moving too fast if the frame rate is either
// too low or too high.

// Click to push pixels outward.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
}