// Image (image) — Submerge by Xor
// https://www.shadertoy.com/view/NdBBzm

//Final blur + bloom
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 texel = 1.0 / iResolution.xy;
    vec2 uv = fragCoord * texel;
    vec4 blur = fibonacci_blur(iChannel2, uv, texel, 216.0);
    vec4 tex0 = texture(iChannel0,uv)*0.5;
    vec4 tex1 = texture(iChannel1,uv)*0.8;
    vec4 tex2 = texture(iChannel2,uv);
    
	fragColor = blur * TINT + tex0 + tex1 + tex2;
}