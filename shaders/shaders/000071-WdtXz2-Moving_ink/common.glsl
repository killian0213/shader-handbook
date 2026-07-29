// Common (common) — Moving ink by jaszunio15
// https://www.shadertoy.com/view/WdtXz2

#define NEGATIVE_COLOR vec3(0.4, 0.4, 1.0)
#define POSITIVE_COLOR vec3(0.4, 1.0, 0.4)
#define BORDER_COLOR vec3(1.0, 1.0, 1.0)
#define BORDER_WIDTH 0.004

#define TIME (iTime * 1.0)

float hash12(vec2 x)
{
 	return fract(sin(dot(x, vec2(533.59731, 821.49221))) * 4315.212331);   
}