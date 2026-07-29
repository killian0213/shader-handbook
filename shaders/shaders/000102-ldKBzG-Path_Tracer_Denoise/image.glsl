// Image (image) — Path Tracer Denoise by yuletian
// https://www.shadertoy.com/view/ldKBzG

// Path tracer denoise.
//
// https://www.shadertoy.com/view/ldKBzG
//

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
}