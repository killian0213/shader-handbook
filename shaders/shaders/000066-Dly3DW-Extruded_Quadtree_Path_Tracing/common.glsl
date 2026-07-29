// Common (common) — Extruded Quadtree Path Tracing by gelami
// https://www.shadertoy.com/view/Dly3DW


#define BOUNCES 3
    
#define CAMERA_DIST 6.0
//#define STATIC_CAMERA
#define CAMERA_POSITION vec3(0, MAX_HEIGHT*0.9, 0)
#define CAMERA_ANGLE vec2(0.09, 0.8)

//#define REPROJECT

#define DOF_STRENGTH 0.12
#define DOF_FOCUS_DISTANCE CAMERA_DIST
#define DOF_SIDES 6

#define MAX_HEIGHT 5.0
#define MAX_LOD 3.0    

#define STEPS 256
#define MAX_DIST 100.
#define EPS 1e-4

#define PI (acos(-1.))
#define TAU (PI*2.)

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
    return .5 + .5 * cos(TAU * (vec3(1, 1, 0.8) * t + vec3(0, 0.25, 0.5)));
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


// RNG
uint state;
void initState(vec2 coord, int frame)
{
    state = uint(coord.x) * 1321u + uint(coord.y) * 4123u + uint(frame) * 4123u*4123u;
}

// From Chris Wellons Hash Prospector
// https://nullprogram.com/blog/2018/07/31/
// https://www.shadertoy.com/view/WttXWX
uint hashi(inout uint x)
{
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

float hash(inout uint x)
{
    return float( hashi(x) ) / float( 0xffffffffU );
}

vec2 hash2(inout uint x)
{
    return vec2(hash(x), hash(x));
}

vec3 hash3(inout uint x)
{
    return vec3(hash(x), hash(x), hash(x));
}

vec4 hash4(inout uint x)
{
    return vec4(hash(x), hash(x), hash(x), hash(x));
}

#define coprimes vec2(2,3)
vec2 halton (vec2 s)
{
  vec4 a = vec4(1,1,0,0);
  while (s.x > 0. && s.y > 0.)
  {
    a.xy = a.xy/coprimes;
    a.zw += a.xy*mod(vec2(s),coprimes);
    s = floor(s/coprimes);
  }
  return a.zw;
}

vec2 getJitter(vec2 pos, int frame)
{
    pos = floor(pos);
    return halton(vec2(frame%8+1)) - .5;
}

// Random unit vector
// Generate a random unit circle and scaled the z with a circular mapping
vec3 randomUnitVector()
{
    vec2 rand = hash2(state);
    rand.y = rand.y*2.-1.;
    rand.x *= PI*2.;
    
    float r = sqrt(1. - rand.y*rand.y);
    vec2 xy = vec2(cos(rand.x), sin(rand.x)) * r;
    
    return vec3(xy, rand.y);
}

vec3 randomHemisphere(vec3 n)
{
    vec3 r = randomUnitVector();
    return dot(r, n) < 0.0 ? -r : r;
}

// Random cosine-weighted unit vector on a hemisphere
// Unit vector + random unit vector
vec3 randomCosineHemisphere(vec3 n)
{
    return normalize(randomUnitVector() + n);
}

vec3 randomUniformCone(float angle)
{
    vec2 rand = hash2(state);
    rand.y = mix(cos(angle), 1.0, rand.y);
    rand.x *= PI*2.;
    
    float r = sqrt(1. - rand.y*rand.y);
    vec2 xy = vec2(cos(rand.x), sin(rand.x)) * r;
    
    return vec3(xy, rand.y);
}

// Random point in circle
// Very straightforward, unit circle scaled by sqrt of the radius
vec2 randomPointInCircle()
{
    vec2 rand = hash2(state);
    
    float a = rand.x * TAU;
    float r = sqrt(rand.y);
    return vec2(cos(a), sin(a)) * r;
}

// Random point in polygon
// Pick a random side and
// generate a point in a rhombus (equal quadrilateral),
// and fold it if the point is outside the inner triangle
vec2 randomPointInPolygon(float sides)
{
    vec3 rand = hash3(state);
    float n = floor(rand.x * sides) / sides;
    float a1 = n * TAU;
    float a2 = a1 + TAU / sides;
    vec2 s1 = vec2(cos(a1), sin(a1));
    vec2 s2 = vec2(cos(a2), sin(a2));
    vec2 p1 = s1 * rand.y + s2 * rand.z;
    vec2 p2 = s1 * (1.0 - rand.y) + s2 * (1.0 - rand.z);
    
    return rand.y + rand.z > 1.0 ? p2 : p1;
}

// Random point in star
// Same as the random point in polygon,
// but without folding the rhombus into a triangle
vec2 randomPointInStar(float sides)
{
    vec3 rand = hash3(state);
    float n = floor(rand.x * sides) / sides;
    float a1 = n * TAU;
    float a2 = a1 + TAU / sides;
    vec2 s1 = vec2(cos(a1), sin(a1));
    vec2 s2 = vec2(cos(a2), sin(a2));
    
    return s1 * rand.y + s2 * rand.z;
}

// Orthonormal Basis
// https://www.shadertoy.com/view/tlVczh
// MBR method 2a variant
mat3 getBasis(in vec3 n)
{
    float sz = n.z >= 0.0 ? 1.0 : -1.0;
    float a  =  n.y/(1.0+abs(n.z));
    float b  =  n.y*a;
    float c  = -n.x*a;

    vec3 xp = vec3(n.z+sz*b, sz*c, -n.x);
    vec3 yp = vec3(c, 1.0-b, -sz*n.y);
    
    return mat3(xp, yp, n);
}

void getBasis(in vec3 n, out vec3 xp, out vec3 yp)
{
    float sz = n.z >= 0.0 ? 1.0 : -1.0;
    float a  =  n.y/(1.0+abs(n.z));
    float b  =  n.y*a;
    float c  = -n.x*a;

    xp = vec3(n.z+sz*b, sz*c, -n.x);
    yp = vec3(c, 1.0-b, -sz*n.y);
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
