// Image (image) — Isosurface with SSS by tmst
// https://www.shadertoy.com/view/WdjfDG

#define CUBE_SAMPLER iChannel0
#define SKY_SAMPLER iChannel1
#define IMAGE_SAMPLER iChannel2
#define BLUR_V_SAMPLER iChannel3

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord/iResolution.xy;
    float dCorner = length(vec2(0.5) - uv) * SQRT2;
    float vignetteFactor = mix(1.0, 0.6, smoothstep(0.3, 0.9, dCorner));
    
    vec3 finalRGB;
    if (INITIALIZING) {
        finalRGB = mainRender(CUBE_SAMPLER, SKY_SAMPLER, iResolution, iMouse, fragCoord, ITIME).rgb;
    } else {
        vec4 data = textureLod(IMAGE_SAMPLER, uv, 0.0);
        vec3 rgbBlur = blurH(BLUR_V_SAMPLER, uv);
        finalRGB = mix(data.rgb, rgbBlur, clamp(data.a, 0.05, 1.0));
    }

    fragColor = vec4(vignetteFactor*finalRGB, 1.0);
}
