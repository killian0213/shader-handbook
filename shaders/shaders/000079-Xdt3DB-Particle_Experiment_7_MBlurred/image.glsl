// Image (image) — Particle Experiment 7 : MBlurred by aiekick
// https://www.shadertoy.com/view/Xdt3DB

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = texture(iChannel0, uv);
}