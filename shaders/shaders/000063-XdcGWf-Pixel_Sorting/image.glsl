// Image (image) — Pixel Sorting by cornusammonis
// https://www.shadertoy.com/view/XdcGWf

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = texture(iChannel0, uv);
}