// Common (common) — Flying into digital tunnel by jaszunio15
// https://www.shadertoy.com/view/wsGSRz

#define RAYMARCH_ITERATIONS 60.0
#define TIME (iTime * 0.4)
#define LINE_LENGTH 1.0
#define LINE_SPACE 1.0
#define LINE_WIDTH 0.007
#define BOUNDING_CYLINDER 1.8
#define INSIDE_CYLINDER 0.32
#define EPS 0.0001
#define FOG_DISTANCE 30.0

#define FIRST_COLOR vec3(1.2, 0.5, 0.2) * 1.2
#define SECOND_COLOR vec3(0.2, 0.8, 1.1)

float hash12(vec2 x)
{
 	return fract(sin(dot(x, vec2(42.2347, 43.4271))) * 342.324234);   
}

vec2 hash22(vec2 x)
{
 	return fract(sin(x * mat2x2(23.421, 24.4217, 25.3271, 27.2412)) * 342.324234);   
}

vec3 hash33(vec3 x)
{
 	return fract(sin(x * mat3x3(23.421, 24.4217, 25.3271, 27.2412, 32.21731, 21.27641, 20.421, 27.4217, 22.3271)) * 342.324234);   
}


mat3x3 rotationMatrix(vec3 angle)
{
 	return 	mat3x3(cos(angle.z), sin(angle.z), 0.0,
                 -sin(angle.z), cos(angle.z), 0.0,
                 0.0, 0.0, 1.0)
        	* mat3x3(1.0, 0.0, 0.0,
                    0.0, cos(angle.x), sin(angle.x),
                    0.0, -sin(angle.x), cos(angle.x))
        	* mat3x3(cos(angle.y), 0.0, sin(angle.y),
                    0.0, 1.0, 0.0,
                    -sin(angle.y), 0.0, cos(angle.y));
}