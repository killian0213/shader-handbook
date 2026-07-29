// Common (common) — Mandelcloud explorer by michael0884
// https://www.shadertoy.com/view/wttyDX

#define LOW_QUALITY

//short or long light paths
#ifdef LOW_QUALITY
    #define MAX_STEPS 20
    #define SCALING 0.1
    #define DITHER 0.5
    #define TRACE_STEPS 8
    //potato mode
    //#define TRACE_STEPS 3
    #define ERROR_THRESHOLD 0.8
    //the probability of scattering into a shadow direction, i.e. inverse scattering strength 
    #define SHADOW_SCATTER_P 0.75
    //temporal denoiser
    #define TAA 0.98
#else
    #define MAX_STEPS 32
    #define SCALING 0.1
    #define DITHER 0.5
    #define TRACE_STEPS 32
    #define ERROR_THRESHOLD 0.3
    #define SHADOW_SCATTER_P 0.99
    #define TAA 0.999
#endif

#define MAX_DIST 10.0
#define ABSORPSION 0.78
#define SCATTERING 1.0

#define ANISOTROPY 0.3

#define AMBIENT_FOG 0.16
#define LIGHT_RAD 0.02
#define LIGHT_BRIGHTNESS 250.0


#define SCATTER_K 100.

//cloud sharpness
#define sharpness 0.00001
#define DENSITY 16.0

//standard constants
#define TWO_PI 6.28318530718
#define PI 3.14159265359

#define N 10

#define MOUSE_ 0
#define CAM_ANGLE_ 1
#define CAM_POS_ 2
#define CAM_VEL_ 3
#define CAM_MAX_VEL_ 4
#define LIGHT_POS1_ 5
#define LIGHT_POS2_ 6
#define PCAM_ANGLE_ 7
#define PCAM_POS_ 8
#define PRESOLUTION_ 9

#define GET_DATA(i) texelFetch(iChannel2, ivec2(i, 0), 0)

//CAMERA stuff
#define FOV 1.0

mat3 get_cam(float phi, float theta)
{
    vec3 x_dir = vec3(cos(phi)*sin(theta), sin(phi)*sin(theta), cos(theta));
    vec3 y_dir = normalize(cross(x_dir, vec3(0,0,1)));
    vec3 z_dir = normalize(cross(x_dir, y_dir));
    return mat3(x_dir, y_dir, z_dir);
}

//internal RNG state 
uvec4 s0, s1; 
ivec2 pixel;

void rng_initialize(vec2 p, int frame)
{
    pixel = ivec2(p);

    //white noise seed
    s0 = uvec4(p, uint(frame), uint(p.x) + uint(p.y));
    
    //blue noise seed
    s1 = uvec4(frame, frame*15843, frame*31 + 4566, frame*2345 + 58585);
}

// https://www.pcg-random.org/
void pcg4d(inout uvec4 v)
{
	v = v * 1664525u + 1013904223u;
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    v = v ^ (v>>16u);
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
}

float rand()
{
    pcg4d(s0); return float(s0.x)/float(0xffffffffu);
}

vec2 rand2()
{
    pcg4d(s0); return vec2(s0.xy)/float(0xffffffffu);
}

vec3 rand3()
{
    pcg4d(s0); return vec3(s0.xyz)/float(0xffffffffu);
}

vec4 rand4()
{
    pcg4d(s0); return vec4(s0)/float(0xffffffffu);
}

//random blue noise sampling pos
ivec2 shift2()
{
    pcg4d(s1); 
    return (pixel + ivec2(s1.xy%0x0fffffffu))%1024;
}

//uniformly spherically distributed
vec3 udir(vec2 rng)
{
    vec2 r = vec2(2.*PI*rng.x, acos(2.*rng.y-1.));
    vec2 c = cos(r), s = sin(r);
    return vec3(c.x*s.y, s.x*s.y, c.y);
}

float HenyeyGreenstein(float g, float costh)
{
    return (1.0 - g * g) / (4.0 * PI * pow(1.0 + g * g - 2.0 * g * costh, 3.0/2.0));
}

 
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

mat2 rot(float ang)
{
    return mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
}

//Keyboard constants
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;
const int KEY_A     = 65;
const int KEY_B     = 66;
const int KEY_C     = 67;
const int KEY_D     = 68;
const int KEY_E     = 69;
const int KEY_F     = 70;
const int KEY_G     = 71;
const int KEY_H     = 72;
const int KEY_I     = 73;
const int KEY_J     = 74;
const int KEY_K     = 75;
const int KEY_L     = 76;
const int KEY_M     = 77;
const int KEY_N     = 78;
const int KEY_O     = 79;
const int KEY_P     = 80;
const int KEY_Q     = 81;
const int KEY_R     = 82;
const int KEY_S     = 83;
const int KEY_T     = 84;
const int KEY_U     = 85;
const int KEY_V     = 86;
const int KEY_W     = 87;
const int KEY_X     = 88;
const int KEY_Y     = 89;
const int KEY_Z     = 90;

//from https://www.shadertoy.com/view/XsSXDy
vec4 powers( float x ) { return vec4(x*x*x, x*x, x, 1.0); }

const vec4 ca = vec4(   3.0,  -5.0,   0.0,  2.0 ) /  2.0;
const vec4 cb = vec4(  -1.0,   5.0,  -8.0,  4.0 ) /  2.0;

vec4 spline( float x, vec4 c0, vec4 c1, vec4 c2, vec4 c3 )
{
    // We could expand the powers and build a matrix instead (twice as many coefficients
    // would need to be stored, but it could be faster.
    return c0 * dot( cb, powers(x + 1.0)) + 
           c1 * dot( ca, powers(x      )) +
           c2 * dot( ca, powers(1.0 - x)) +
           c3 * dot( cb, powers(2.0 - x));
}


#define SAM(a,b)  texture(tex, (i+vec2(float(a),float(b))+0.5)/res, -99.0)

vec4 texture_Bicubic( sampler2D tex, vec2 t )
{
    vec2 res = vec2(textureSize(tex,0));
    vec2 p = res*t - 0.5;
    vec2 f = fract(p);
    vec2 i = floor(p);

    return spline( f.y, spline( f.x, SAM(-1,-1), SAM( 0,-1), SAM( 1,-1), SAM( 2,-1)),
                        spline( f.x, SAM(-1, 0), SAM( 0, 0), SAM( 1, 0), SAM( 2, 0)),
                        spline( f.x, SAM(-1, 1), SAM( 0, 1), SAM( 1, 1), SAM( 2, 1)),
                        spline( f.x, SAM(-1, 2), SAM( 0, 2), SAM( 1, 2), SAM( 2, 2)));
}