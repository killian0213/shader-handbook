// Image (image) — Liquid in glass by tmst
// https://www.shadertoy.com/view/3tfcRS

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = textureLod(iChannel0, uv, 0.0);
}
