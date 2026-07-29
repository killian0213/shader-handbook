// Image (image) — Moana Water Shader by suyoku
// https://www.shadertoy.com/view/wlsyzH

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = vec4(texture(iChannel0, uv).rgb, 1.0);
}