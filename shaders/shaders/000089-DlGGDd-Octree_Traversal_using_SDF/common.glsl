// Common (common) — Octree Traversal using SDF by gelami
// https://www.shadertoy.com/view/DlGGDd


#define FOG
//#define ROUNDED_NORMALS
//#define TOP_PLANE
//#define DYNAMIC_LOD
//#define VOXEL_NORMALS

//#define MOTION_BLUR 0.05

#define SURFACE_FACTOR 0.435

#define CAMERA_SPEED -1.35

#ifdef TOP_PLANE
#define MAX_HEIGHT 10.0
#endif

#define MAX_LOD 4.0

//#define SHOW_STEPS

#define STEPS 512
#define MAX_DIST 35.0
#define EPS 1e-4

#define PI (acos(-1.))
#define TAU (PI*2.)

float sdBox( in vec3 p, in vec3 rad )
{
    p = abs(p) - rad;
    return max(max(p.x, p.y), p.z);
}

mat3 getCameraMatrix(vec3 ro, vec3 lo)
{
    vec3 cw = normalize(lo - ro);
    vec3 cu = normalize(cross(cw, vec3(0, 1, 0)));
    vec3 cv = cross(cu, cw);

    return mat3(cu, cv, cw);
}

float safeacos(float x) { return acos(clamp(x, -1.0, 1.0)); }

float saturate(float x) { return clamp(x, 0., 1.); }
vec2 saturate(vec2 x) { return clamp(x, vec2(0), vec2(1)); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0), vec3(1)); }

float sqr(float x) { return x*x; }
vec2 sqr(vec2 x) { return x*x; }
vec3 sqr(vec3 x) { return x*x; }

float luminance(vec3 col) { return dot(col, vec3(0.2126729, 0.7151522, 0.0721750)); }

mat2 rot2D(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

// https://iquilezles.org/articles/smin/
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }
    
float smax( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }


// https://iquilezles.org/articles/palettes/
vec3 palette(float t)
{
    return .5 + .5 * cos(TAU * (vec3(1, 1, 1) * t + vec3(0, .33, .67)));
}

vec3 palette2(float t)
{
    return .45 + .55 * cos(TAU * (vec3(1, 0.8, 0.6) * t + vec3(0, 0.3, 0.5)));
}

// Hash without Sine
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

float hash14(vec4 p4)
{
	p4 = fract(p4  * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.x + p4.y) * (p4.z + p4.w));
}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec2 hash23(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

vec3 sRGBToLinear(vec3 col)
{
    return mix(pow((col + 0.055) / 1.055, vec3(2.4)), col / 12.92, lessThan(col, vec3(0.04045)));
}

vec3 linearTosRGB(vec3 col)
{
    return mix(1.055 * pow(col, vec3(1.0 / 2.4)) - 0.055, col * 12.92, lessThan(col, vec3(0.0031308)));
}

// ACES tone mapping curve fit to go from HDR to LDR
//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x + b)) / (x*(c*x + d) + e), 0.0f, 1.0f);
}

vec3 ReinhardExtLuma(vec3 col, const float w)
{
    float l = luminance(col);
    float n = l * (1.0 + l / (w * w));
    float ln = n / (1.0 + l);
    return col * ln / l;
}
