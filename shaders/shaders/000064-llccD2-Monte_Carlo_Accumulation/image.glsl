// Image (image) — Monte Carlo Accumulation by mhnewman
// https://www.shadertoy.com/view/llccD2

// Monte carlo ambient occlusion, depth of field, spherical aberration,
// and anti aliasing using accumulation buffer.
//
// Based on www.shadertoy.com/view/4tlfDn Reusable Voxel Engine.
// Create your scene by filling in setCamera(), voxelHit(), and voxelColor().

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = pow(1.0 - pow(1.0 - texture(iChannel0, fragCoord.xy / iResolution.xy), vec4(5.0)), vec4(1.6));
}