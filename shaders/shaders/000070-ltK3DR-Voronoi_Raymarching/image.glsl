// Image (image) — Voronoi Raymarching by rory618
// https://www.shadertoy.com/view/ltK3DR


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	
	fragColor = texture(iChannel0,fragCoord/iResolution.xy);
}