// Common (common) — Lens Flare Post-Processing by gelami
// https://www.shadertoy.com/view/mtVSRd


// Defines

#define EXPOSURE 0.7

#define ENV_MAP_WHITE_POINT 100.0

#define CHROMATIC_ABERRATION
#define CHROMATIC_ABERRATION_STRENGTH 1.5

#define GHOSTS
#define GHOSTS_COUNT 4
#define GHOSTS_OFFSET 0.2
#define GHOSTS_STRENGTH 0.6

#define HALO
#define HALO_RADIUS 0.6
#define HALO_STRENGTH 0.4

#define GLARE
#define GLARE_COUNT 20
#define GLARE_STEP_SIZE 4.0
#define GLARE_STRENGTH 0.6

#define BLOOM
#define BLOOM_MAX_LOD 6
#define BLOOM_THRESHOLD 2.0
#define BLOOM_STRENGTH 0.4

//#define SHOW_FALSE_COLOR

#define STEPS 512
#define MAX_DIST 100.
#define EPS 1e-4

#define PI (acos(-1.))
#define TAU (PI*2.)


mat2 rot2D(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

vec3 getLookAtPos()
{
    return vec3(0, 0, 0);
}

vec3 getCameraPos(vec4 mouse, vec2 res, float time)
{
    vec2 m = mouse.xy / res.xy;
    
    vec3 ro = vec3(0, 0, 1);
    
    float ax = mouse.z < 0. || mouse.x == 0. ? -0.5 + time * PI / 10.0 : -m.x * TAU + PI;
    float ay = mouse.z < 0. || mouse.y == 0. ? -PI * 0.1 : -m.y * PI + PI * 0.5;
    
    ro.yz *= rot2D(ay);
    ro.xz *= rot2D(ax);
    ro += getLookAtPos();
    
    return ro;
}

#define TEX_BIAS 1.0
#define TEX_SCALE 0.4

vec3 sampleBuffer(sampler2D tex, vec2 uv)
{
    return max(textureLod(tex, uv, 2.5).rgb - TEX_BIAS, vec3(0)) * TEX_SCALE;
}

vec3 sampleBufferLod(sampler2D tex, vec2 uv, float lod)
{
    return max(textureLod(tex, uv, lod).rgb - TEX_BIAS, vec3(0)) * TEX_SCALE;
}

vec3 sampleDistorted(sampler2D tex, vec2 uv, vec2 dir, vec3 str)
{
    return vec3(
        sampleBuffer(tex, uv + dir * str.r).r,
        sampleBuffer(tex, uv + dir * str.g).g,
        sampleBuffer(tex, uv + dir * str.b).b
    );
}

vec4 SampleLod(sampler2D tex, vec2 uv, vec2 res, const int lod)
{
    vec2 hres = floor(res / 2.0);
    
    vec2 nres = hres;
    float xpos = 0.0;
    int i = 0;
    for (; i < lod; i++)
    {
        xpos += nres.x;
        
        nres = floor(nres / 2.0);
    }
    
    vec2 nuv = uv * vec2(nres);
    
    nuv = clamp(nuv, vec2(0.5), vec2(nres)-0.5);
    nuv += vec2(xpos, 0);
    
    return texture(tex, nuv / res);
}


vec3 uvToDir(vec2 uv)
{
    uv -= 0.5;
    float phi = uv.x * TAU;
    float theta = uv.y * PI;
    return vec3(cos(phi) * cos(theta), sin(theta), sin(phi) * cos(theta));
}

vec2 dirToUv(vec3 dir)
{
    float theta = atan(dir.z, dir.x);
    float phi = atan(dir.y, length(dir.xz));
    
    return vec2(theta / TAU, phi / PI) + 0.5;
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
    return .5 + .5 * cos(TAU * (vec3(1, 1, 1) * t + vec3(0, .25, .5)));
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

// From Jodie
// https://www.shadertoy.com/view/4dBcD1
vec3 ReinhardJodie(vec3 v)
{
    float l = luminance(v);
    vec3 tv = v / (1.0f + v);
    return mix(v / (1.0f + l), tv, tv);
}
