// Image (image) — Image Diffusion Warp by cornusammonis
// https://www.shadertoy.com/view/Msd3W2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 im = texture(iChannel0, uv).xyz;
    fragColor = vec4(im, 0.0);
    //fragColor = 0.5 + 0.5 * texture(iChannel1, uv);
}