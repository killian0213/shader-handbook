// Image (image) — Fractal portrait by loicvdb
// https://www.shadertoy.com/view/cdlGRl

void mainImage(out vec4 o, vec2 u)
{
    o = texelFetch(iChannel0, ivec2(u), 0);
    vec2 cuv = (u - iResolution.xy * 0.5) / iResolution.y;
    o *= 1.0 - 0.5 * dot(cuv, cuv);
    o = (o * (2.51 * o + 0.03)) / (o * (2.43 * o + 0.59) + 0.14);
}