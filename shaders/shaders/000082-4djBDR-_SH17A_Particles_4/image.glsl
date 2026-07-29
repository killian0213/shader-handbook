// Image (image) — [SH17A] Particles 4 by aiekick
// https://www.shadertoy.com/view/4djBDR

void mainImage( out vec4 f, vec2 g )
{
	f = texelFetch(iChannel0, ivec2(g),0); // thanks to dave hoskins
}