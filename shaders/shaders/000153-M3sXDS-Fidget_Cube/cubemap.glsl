// Cube A (cubemap) — Fidget Cube by TheBen27
// https://www.shadertoy.com/view/M3sXDS

// Precompute environment map
void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    // Try to avoid black screen on previews
    if (iFrame > 4) {
        fragColor = texture(iChannel0, rayDir);
        return;
    }
    
    // Diffuse
    vec3 diff = vec3(0.0);
    const int diff_samples = 512;
    for (int i = 0; i < diff_samples; i++) {
        vec3 dir = randomHemisphereDir(rayDir, float(i));
        diff += dot(rayDir, dir) * sky(dir);
    }
    diff /= float(diff_samples);
    // not physical
    diff *= 2.0;
    
    // Specular
    vec3 specColor = sky(rayDir);
    float spec = specColor.r + specColor.g + specColor.b;
    spec /= 3.0;
    
    // Output to cubemap
    fragColor = vec4(diff, spec);
}