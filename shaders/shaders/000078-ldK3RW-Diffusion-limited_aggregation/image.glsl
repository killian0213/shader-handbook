// Image (image) — Diffusion-limited aggregation by davidar
// https://www.shadertoy.com/view/ldK3RW

// 2016 David A Roberts <https://davidar.io>

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = (texture(iChannel0,uv) + texture(iChannel1,uv) + texture(iChannel2,uv) + texture(iChannel3,uv)) / 5.;
}