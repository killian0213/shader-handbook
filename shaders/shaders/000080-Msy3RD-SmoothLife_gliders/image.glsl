// Image (image) — SmoothLife gliders by davidar
// https://www.shadertoy.com/view/Msy3RD

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = texture(iChannel0, uv);
}