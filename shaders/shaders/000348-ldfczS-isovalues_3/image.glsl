// Image (image) — isovalues 3 by FabriceNeyret2
// https://www.shadertoy.com/view/ldfczS

void mainImage( out vec4 O,  vec2 U )
{
	O = texture( iChannel0, U / iResolution.xy);
}