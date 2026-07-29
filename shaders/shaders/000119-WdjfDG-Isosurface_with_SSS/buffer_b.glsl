// Buffer B (buffer) — Isosurface with SSS by tmst
// https://www.shadertoy.com/view/WdjfDG

#define IMAGE_SAMPLER iChannel0

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / RES.xy;
    fragColor = vec4(blurV(iResolution, IMAGE_SAMPLER, uv), 1.0);
}