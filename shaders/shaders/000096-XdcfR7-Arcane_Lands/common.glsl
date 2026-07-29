// Common (common) — Arcane Lands by Dave_Hoskins
// https://www.shadertoy.com/view/XdcfR7

// Common functions and defines...

// Make a high def version for Youtube
//#define MOVIE

// These are indices into the variable data in Buf A...

#define CAMERA_POS		0
#define CAMERA_TAR		1
#define CAMERA_MAT0		2
#define CAMERA_MAT1		3
#define CAMERA_MAT2		4

#define SUN_DIRECTION 	5
#define LAST 			6


#define FAR 1100.

#define TAU 6.28318530718
#define SUN_COLOUR vec3(1., .8, .7)
#define FOG_COLOUR vec3(.4, .4, .4)

vec3 sunLight, camPos;
vec3 camera;
float specular;
mat3 camMat;
float zProj;

//----------------------------------------------------------------------------------------
vec3 cameraPath( float z )
{
	return vec3(200.*sin(z * .0045)+190.*cos(z *.001),
                43.*(cos(z * .0047)+sin(z*.0013)) + 53.*(sin(z*0.003)),
                z);
}
// Set up a camera matrix

//--------------------------------------------------------------------------
mat3 setCamMat( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}
//--------------------------------------------------------------------------
#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

//---------------------------------------------------------------------------------------------------------------
float hash11(float p)
{
	uvec2 n = uint(int(p)) * UI2;
	uint q = (n.x ^ n.y) * UI0;
	return float(q) * UIF;
}
//---------------------------------------------------------------------------------------------------------------
float hash12(vec2 p)
{
	uvec2 q = uvec2(ivec2(p)) * UI2;
	uint n = (q.x ^ q.y) * UI0;
	return float(n) * UIF;
}
//---------------------------------------------------------------------------------------------------------------
vec2 hash22(vec2 p)
{
	uvec2 q = uvec2(ivec2(p))*UI2;
	q = (q.x ^ q.y) * UI2;
	return vec2(q) * UIF;
}
//---------------------------------------------------------------------------------------------------------------
float sMax(float a, float b, float s)
{
    
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1.0-h)*s;
}

//--------------------------------------------------------------------------
float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    float res = mix(mix( hash12(p), hash12(p+ vec2(1.0, 0.0)),f.x),
                    mix( hash12(p+ vec2(.0, 1.0)), hash12(p+ vec2(1.0, 1.0)),f.x),f.y);
    return res;
}

float projectZ(vec2 uv)
{
	return .6;
//   return cos(length(uv*.75));
}


#define HASHSCALE1 .1031


