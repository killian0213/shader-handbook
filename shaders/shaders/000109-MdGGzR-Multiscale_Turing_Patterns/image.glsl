// Image (image) — Multiscale Turing Patterns by cornusammonis
// https://www.shadertoy.com/view/MdGGzR

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = 0.5 + 0.5 * texture(iChannel0, uv);
}