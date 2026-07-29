// Image (image) — Psychedelic tube by z0rg
// https://www.shadertoy.com/view/sdcGRX

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    vec3 col = texture(iChannel0, uv).xyz;
    fragColor = vec4(col,1.0);
}