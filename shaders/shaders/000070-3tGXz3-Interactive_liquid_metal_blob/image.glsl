// Image (image) — Interactive liquid metal blob by tmst
// https://www.shadertoy.com/view/3tGXz3

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = textureLod(iChannel0, uv, 0.0);
}
