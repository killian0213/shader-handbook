// Image (image) — Neural Detonation by leon
// https://www.shadertoy.com/view/7lGBWw


// Neural Detonation

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    fragColor = texture(iChannel0, uv);
}