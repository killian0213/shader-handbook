// Image (image) — Magic Particles Multi-Pass by TambakoJaguar
// https://www.shadertoy.com/view/ld3GWS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = texture(iChannel0,uv);
}