// Image (image) — Alien Cavity by lsdlive
// https://www.shadertoy.com/view/MdccWr

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord / iResolution.xy;

    // standard cheap "glitch" post process
	float s = sin(iTime*10.)*.008;
	float t = tan(iTime)*.002;
	fragColor.r = texture(iChannel0, uv + vec2(-s, s)).r;
	fragColor.g = texture(iChannel0, uv + vec2(-t, t)).g;
	fragColor.b = texture(iChannel0, uv + vec2(s, -s)).b;

}