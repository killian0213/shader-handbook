// Common (common) — Frostbite Material Render-Ref by TinyTexel
// https://www.shadertoy.com/view/wsScWt

// Lincense: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

/*
Basic implementation of Frostbite's material + relevant sampling strategies.
Camera controls via mouse + shift key.

References:
	https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
	https://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf

The bulk of the material specific code is in the Common tab; direct light sampling routines + rendering in BufferA. Tonemapping in Image.
*/

// render with sharp primaries so bounce light colors behave reasonably well ( https://www.shadertoy.com/view/WltSRB ):
#define USE_ACESCG

//#define USE_BLOOM

// use low-discrepancy sequences for the first direct light sampling and scattered ray direction sampling (doesn't improve quality all that much)
//#define USE_LDS

// LDS sequences don't work when bloom is active since the bloom kernel use LDS sequences themselves
#ifdef USE_BLOOM
 #undef USE_LDS
#endif


#define Frame float(iFrame)
#define rsqrt inversesqrt
#define clamp01(x) clamp(x, 0.0, 1.0)
#define If(cond, resT, resF) mix(resF, resT, cond)

const float Pi = 3.14159265359;
const float RcpPi = 1.0 / Pi;
const float Pi05 = Pi * 0.5;

float Pow2(float x) {return x*x;}
float Pow3(float x) {return x*x*x;}
float Pow4(float x) {return Pow2(Pow2(x));}

vec2 AngToVec(float ang)
{	
	return vec2(cos(ang), sin(ang));
}


vec3 AngToVec(vec2 ang)
{
    float sinPhi   = sin(ang.x);
    float cosPhi   = cos(ang.x);
    float sinTheta = sin(ang.y);
    float cosTheta = cos(ang.y);    

    return vec3(cosPhi * cosTheta, 
                         sinTheta, 
                sinPhi * cosTheta); 
}


float SqrLen(float v) {return v * v;}
float SqrLen(vec2  v) {return dot(v, v);}
float SqrLen(vec3  v) {return dot(v, v);}
float SqrLen(vec4  v) {return dot(v, v);}



uint  asuint2(float x) { return x == 0.0 ? 0u : floatBitsToUint(x); }
uvec2 asuint2(vec2 x) { return uvec2(asuint2(x.x ), asuint2(x.y)); }
uvec3 asuint2(vec3 x) { return uvec3(asuint2(x.xy), asuint2(x.z)); }
uvec4 asuint2(vec4 x) { return uvec4(asuint2(x.xy), asuint2(x.zw)); }

float Float01(uint x) { return float(    x ) * (1.0 / 4294967296.0); }
float Float11(uint x) { return float(int(x)) * (1.0 / 2147483648.0); }

vec2 Float01(uvec2 x) { return vec2(      x ) * (1.0 / 4294967296.0); }
vec2 Float11(uvec2 x) { return vec2(ivec2(x)) * (1.0 / 2147483648.0); }

vec3 Float01(uvec3 x) { return vec3(      x ) * (1.0 / 4294967296.0); }
vec3 Float11(uvec3 x) { return vec3(ivec3(x)) * (1.0 / 2147483648.0); }

vec4 Float01(uvec4 x) { return vec4(      x ) * (1.0 / 4294967296.0); }
vec4 Float11(uvec4 x) { return vec4(ivec4(x)) * (1.0 / 2147483648.0); }

const uint rPhi1  = 2654435761u;

const uint rPhi2a = 3242174893u;
const uint rPhi2b = 2447445397u;

const uint rPhi3a = 3518319149u;
const uint rPhi3b = 2882110339u;
const uint rPhi3c = 2360945581u;

const uint rPhi4a = 3679390609u;
const uint rPhi4b = 3152041517u;
const uint rPhi4c = 2700274807u;
const uint rPhi4d = 2313257579u;

const uvec2 rPhi2 = uvec2(rPhi2a, rPhi2b);
const uvec3 rPhi3 = uvec3(rPhi3a, rPhi3b, rPhi3c);
const uvec4 rPhi4 = uvec4(rPhi4a, rPhi4b, rPhi4c, rPhi4d);

uint  Roberts(uint  off, uint n) { return off + rPhi1 * n; }
uvec2 Roberts(uvec2 off, uint n) { return off + rPhi2 * n; }
uvec3 Roberts(uvec3 off, uint n) { return off + rPhi3 * n; }
uvec4 Roberts(uvec4 off, uint n) { return off + rPhi4 * n; }

#define _SEED uvec4(0xCAF0FC2Eu, 0xEA18994Au, 0x4D86D399u, 0x10EB49F0u)

uvec4 PhiHash(uint  v, uint seed) { return ((v   * rPhi2a)                                                    ^ (_SEED ^ uvec4(seed))) * rPhi1; }
uvec4 PhiHash(uvec2 v, uint seed) { return ((v.x * rPhi2a) ^ (v.y * rPhi2b)                                   ^ (_SEED ^ uvec4(seed))) * rPhi1; }
uvec4 PhiHash(uvec3 v, uint seed) { return ((v.x * rPhi3a) ^ (v.y * rPhi3b) ^ (v.z * rPhi3c)                  ^ (_SEED ^ uvec4(seed))) * rPhi1; }
uvec4 PhiHash(uvec4 v, uint seed) { return ((v.x * rPhi4a) ^ (v.y * rPhi4b) ^ (v.z * rPhi4c) ^ (v.w * rPhi4d) ^ (_SEED ^ uvec4(seed))) * rPhi1; }

vec4 PhiHash01(float v, uint seed) { return Float01(PhiHash(asuint2(v), seed)); }
vec4 PhiHash01(vec2  v, uint seed) { return Float01(PhiHash(asuint2(v), seed)); }
vec4 PhiHash01(vec3  v, uint seed) { return Float01(PhiHash(asuint2(v), seed)); }
vec4 PhiHash01(vec4  v, uint seed) { return Float01(PhiHash(asuint2(v), seed)); }

vec4 PhiHash11(float v, uint seed) { return Float11(PhiHash(asuint2(v), seed)); }
vec4 PhiHash11(vec2  v, uint seed) { return Float11(PhiHash(asuint2(v), seed)); }
vec4 PhiHash11(vec3  v, uint seed) { return Float11(PhiHash(asuint2(v), seed)); }
vec4 PhiHash11(vec4  v, uint seed) { return Float11(PhiHash(asuint2(v), seed)); }

uint MixHash(uvec2 h)
{
    return ((h.x ^ (h.y >> 16u)) * rPhi2.x) ^ 
           ((h.y ^ (h.x >> 16u)) * rPhi2.y);
}

uint MixHash(uvec3 h)
{
    return ((h.x ^ (h.y >> 16u) ^ (h.z << 15u)) * rPhi3.x) ^ 
           ((h.y ^ (h.z >> 16u) ^ (h.y << 15u)) * rPhi3.y) ^
           ((h.z ^ (h.y >> 16u) ^ (h.x << 15u)) * rPhi3.z);
}

uint MixHash(uvec4 h)
{
    return ((h.x ^ (h.y >> 16u) ^ (h.z << 15u)) * rPhi4.x) ^ 
           ((h.y ^ (h.z >> 16u) ^ (h.w << 15u)) * rPhi4.y) ^
           ((h.z ^ (h.w >> 16u) ^ (h.x << 15u)) * rPhi4.z) ^
           ((h.w ^ (h.x >> 16u) ^ (h.y << 15u)) * rPhi4.w);
}

// low bias version https://nullprogram.com/blog/2018/07/31/
uint WellonsHash(uint x)
{
    x ^= x >> 16u;
    x *= 0x7feb352dU;
    x ^= x >> 15u;
    x *= 0x846ca68bU;
    x ^= x >> 16u;

    return x;
}

uvec2 WellonsHash(uvec2 h) { return uvec2(WellonsHash(h.x), WellonsHash(h.y)); }
uvec3 WellonsHash(uvec3 h) { return uvec3(WellonsHash(h.x), WellonsHash(h.y), WellonsHash(h.z)); }
uvec4 WellonsHash(uvec4 h) { return uvec4(WellonsHash(h.x), WellonsHash(h.y), WellonsHash(h.z), WellonsHash(h.w)); }

uvec4 WellonsHash(uint  v, uint seed) { return WellonsHash(        v  ^ (_SEED ^ uvec4(seed))); }
uvec4 WellonsHash(uvec2 v, uint seed) { return WellonsHash(MixHash(v) ^ (_SEED ^ uvec4(seed))); }
uvec4 WellonsHash(uvec3 v, uint seed) { return WellonsHash(MixHash(v) ^ (_SEED ^ uvec4(seed))); }
uvec4 WellonsHash(uvec4 v, uint seed) { return WellonsHash(MixHash(v) ^ (_SEED ^ uvec4(seed))); }

// minimal bias version https://nullprogram.com/blog/2018/07/31/
uint WellonsHash2(uint x)
{
    x ^= x >> 17u;
    x *= 0xed5ad4bbU;
    x ^= x >> 11u;
    x *= 0xac4c1b51U;
    x ^= x >> 15u;
    x *= 0x31848babU;
    x ^= x >> 14u;

    return x;
}

uvec2 WellonsHash2(uvec2 h) { return uvec2(WellonsHash2(h.x), WellonsHash2(h.y)); }
uvec3 WellonsHash2(uvec3 h) { return uvec3(WellonsHash2(h.x), WellonsHash2(h.y), WellonsHash2(h.z)); }
uvec4 WellonsHash2(uvec4 h) { return uvec4(WellonsHash2(h.x), WellonsHash2(h.y), WellonsHash2(h.z), WellonsHash2(h.w)); }

uvec4 WellonsHash2(uint  v, uint seed) { return WellonsHash2(        v  ^ (_SEED ^ uvec4(seed))); }
uvec4 WellonsHash2(uvec2 v, uint seed) { return WellonsHash2(MixHash(v) ^ (_SEED ^ uvec4(seed))); }
uvec4 WellonsHash2(uvec3 v, uint seed) { return WellonsHash2(MixHash(v) ^ (_SEED ^ uvec4(seed))); }
uvec4 WellonsHash2(uvec4 v, uint seed) { return WellonsHash2(MixHash(v) ^ (_SEED ^ uvec4(seed))); }

#undef _SEED


// https://en.wikipedia.org/wiki/Linear_congruential_generator
uint LCG(uint x) { return x * 22695477u + 1u; }

float Hash01(inout uint h)
{
    h = LCG(h);

    return Float01(h * rPhi1);
}

float Hash11(inout uint h)
{
    h = LCG(h);

    return Float11(h * rPhi1);
}

uint HashU(inout uint h)
{
    h = LCG(h);

    return h * rPhi1;
}

vec2 Hash01x2(inout uint h) { return vec2(Hash01(h), Hash01(h)); }
vec3 Hash01x3(inout uint h) { return vec3(Hash01(h), Hash01(h), Hash01(h)); }
vec4 Hash01x4(inout uint h) { return vec4(Hash01(h), Hash01(h), Hash01(h), Hash01(h)); }

vec2 Hash11x2(inout uint h) { return vec2(Hash11(h), Hash11(h)); }
vec3 Hash11x3(inout uint h) { return vec3(Hash11(h), Hash11(h), Hash11(h)); }
vec4 Hash11x4(inout uint h) { return vec4(Hash11(h), Hash11(h), Hash11(h), Hash11(h)); }

uvec2 HashUx2(inout uint h) { return uvec2(HashU(h), HashU(h)); }
uvec3 HashUx3(inout uint h) { return uvec3(HashU(h), HashU(h), HashU(h)); }
uvec4 HashUx4(inout uint h) { return uvec4(HashU(h), HashU(h), HashU(h), HashU(h)); }

/* http://tksharpless.net/vedutismo/Pannini/panini.pdf */
vec3 Pannini(vec2 tc, float fov, float d)
{
    float d2 = d*d;

    {
        float fo = Pi05 - fov * 0.5;

        float f = cos(fo)/sin(fo) * 2.0;
        float f2 = f*f;

        float b = (sqrt(max(0.0, Pow2(d+d2)*(f2+f2*f2))) - (d*f+f)) / (d2+d2*f2-1.0);

        tc *= b;
    }
    
    float h = tc.x;
    float v = tc.y;
    
    float h2 = h*h;
    
    float k = h2/Pow2(d+1.0);
    float k2 = k*k;
    
    float discr = max(0.0, k2*d2 - (k+1.0)*(k*d2-1.0));
    
    float cosPhi = (-k*d+sqrt(discr))/(k+1.0);
    float S = (d+1.0)/(d+cosPhi);
    float tanTheta = v/S;
    
    float sinPhi = sqrt(max(0.0, 1.0-Pow2(cosPhi)));
    if(tc.x < 0.0) sinPhi *= -1.0;
    
    float s = inversesqrt(1.0+Pow2(tanTheta));
    
    return vec3(sinPhi, tanTheta, cosPhi) * s;
}

/*
SOURCE: 
	"Building an Orthonormal Basis from a 3D Unit Vector Without Normalization"
		http://orbit.dtu.dk/files/126824972/onb_frisvad_jgt2012_v2.pdf
		
	"Building an Orthonormal Basis, Revisited" 
		http://jcgt.org/published/0006/01/01/
	
	- modified for right-handedness here
	
DESCR:
	Constructs a right-handed, orthonormal coordinate system from a given vector of unit length.

IN:
	n  : normalized vector
	
OUT:
	ox	: orthonormal vector
	oz	: orthonormal vector
	
EXAMPLE:
	float3 ox, oz;
	OrthonormalBasis(N, OUT ox, oz);
*/
void OrthonormalBasisRH(vec3 n, out vec3 ox, out vec3 oz)
{
	float sig = n.z < 0.0 ? 1.0 : -1.0;
	
	float a = 1.0 / (n.z - sig);
	float b = n.x * n.y * a;
	
	ox = vec3(1.0 + sig * n.x * n.x * a, sig * b, sig * n.x);
	oz = vec3(b, sig + n.y * n.y * a, n.y);
}

// s0 [-1..1], s1 [-1..1]
// samples spherical cap for s1 [cosAng05..1]
// samples hemisphere if s1 [0..1]
vec3 Sample_Sphere(float s0, float s1)
{
    float ang = Pi * s0;
    float s1p = sqrt(1.0 - s1*s1);
    
    return vec3(cos(ang) * s1p, 
                           s1 , 
                sin(ang) * s1p);
}

// s0 [-1..1], s1 [-1..1]
// samples spherical cap for s1 [cosAng05..1]
vec3 Sample_Sphere(float s0, float s1, vec3 normal)
{	 
    vec3 sph = Sample_Sphere(s0, s1);

    vec3 ox, oz;
    OrthonormalBasisRH(normal, ox, oz);

    return (ox * sph.x) + (normal * sph.y) + (oz * sph.z);
}

// s0 [-1..1], s1 [-1..1]
vec3 Sample_Hemisphere(float s0, float s1, vec3 normal)
{
    vec3 smpl = Sample_Sphere(s0, s1);

    if(dot(smpl, normal) < 0.0)
        return -smpl;
    else
        return smpl;
}

// s0 [-1..1], s1 [0..1]
vec2 Sample_Disk(float s0, float s1)
{
    return vec2(cos(Pi * s0), sin(Pi * s0)) * sqrt(s1);
}

// s0 [-1..1], s1 [0..1]
vec3 Sample_ClampedCosineLobe(float s0, float s1)
{	 
    vec2 d  = Sample_Disk(s0, s1);
    float y = sqrt(clamp01(1.0 - s1));
    
    return vec3(d.x, y, d.y);
}

// s0 [-1..1], s1 [0..1]
vec3 Sample_ClampedCosineLobe(float s0, float s1, vec3 normal)
{	 
    vec2 d  = Sample_Disk(s0, s1);
    float y = sqrt(clamp01(1.0 - s1));

    vec3 ox, oz;
    OrthonormalBasisRH(normal, ox, oz);

    return (ox * d.x) + (normal * y) + (oz * d.y);
}

// s [-1..1]
float Sample_Triangle(float s) 
{ 
    float v = 1.0 - sqrt(1.0 - abs(s));
    
    return s < 0.0 ? -v : v; 
}

// Box-Muller Transform: 
// https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
// u (0..1] | v [-1..1]
vec2 Sample_Gauss2D(float u, float v)
{
    float l = sqrt(-2.0 * log(u));
    
    return vec2(cos(v * Pi), sin(v * Pi)) * l;
}

const float pi      = 3.14159274;
const float rpi     = 0.31830989;
				   
const float pi2     = 6.28318530;
const float rpi2    = 0.15915494;
				   
const float pi05    = 1.57079632;
const float rpi05   = 0.63661977;

const float sqrt05  = 0.70710678;
const float rsqrt05 = 1.41421356;

const float phi     = 1.61803398;
const float rphi    = 0.61803398;


float OrenNayar(vec3 V, vec3 N, vec3 L, float sigma)
{
    float NoL = clamp01(dot(N, L));
    float NoV = clamp01(dot(N, V));
    
	float sigma2 = sigma * sigma;

	float A = 1.0 - 0.5  * sigma2 / (sigma2 + 0.33);
	float B =       0.45 * sigma2 / (sigma2 + 0.09);

	float term0 = sqrt((1.0 - NoV * NoV) * (1.0 - NoL * NoL)) / max(NoL, NoV);

	vec3 V_proj = normalize(V - N * NoV);
	vec3 L_proj = normalize(L - N * NoL);

	float term1 = clamp01(dot(V_proj, L_proj));

	return (A + (B * term1 * term0)) * NoL * rpi;
}


// float ct, sang; vec3 Lc, L;
// Sample_SolidAngle(s, p, lp, lr2, /*out*/ ct, /*out*/ Lc, /*out*/ L, /*out*/ sang)
// s [0..1]
void Sample_SolidAngle(vec2 s, vec3 p, vec3 lp, float lr2, 
                       out float ct, out vec3 Lc, out vec3 L, out float sang)
{
    vec3 lvec = lp - p;
    
   	float len2 = dot(lvec, lvec);
    
    if(len2 == 0.0)
    {
        ct = 0.0;
        Lc = vec3(0.0, 1.0, 0.0);
        L  = vec3(0.0, 1.0, 0.0);
        sang = pi2;
        
        return;
    }
    
	float rlen = rsqrt(len2);

    Lc = lvec * rlen;
    
    ct = sqrt(clamp01(1.0 - lr2 * (rlen * rlen)));
    
    L = Sample_Sphere(s.x * 2.0 - 1.0, mix(ct, 1.0, s.y), Lc);

    sang = ct * -pi2 + pi2;
}


float FresnelSchlick(float ct, float f0)
{
	float x = 1.0 - ct;
    float w = (x*x) * (x*x) * x;

    return f0 * (1.0 - w) + w;
}

vec3 FresnelSchlick(float ct, vec3 f0)
{
    float x = 1.0 - ct;
    float w = (x*x) * (x*x) * x;

    return f0 * (1.0 - w) + w;
}

float FresnelSchlick(float ct, float f0, float f90)
{
	float x = 1.0 - ct;
    float w = (x*x) * (x*x) * x;

    return mix(f0, f90, w);
}

vec3 FresnelSchlick(float ct, vec3 f0, vec3 f90)
{
    float x = 1.0 - ct;
    float w = (x*x) * (x*x) * x;

    return mix(f0, f90, w);
}


float GGX_V(float NoL, float NoV, float alpha)
{
	float aa = alpha*alpha;
    
	float t0 = NoL * sqrt((-NoV * aa + NoV ) * NoV + aa);
	float t1 = NoV * sqrt((-NoL * aa + NoL ) * NoL + aa);
	
    return 0.5 / (t0 + t1);
}

float GGX_G(float NoL, float NoV, float alpha)
{
	float aa = alpha * alpha;
    
	float t0 = NoL * sqrt((-NoV * aa + NoV ) * NoV + aa);
	float t1 = NoV * sqrt((-NoL * aa + NoL ) * NoL + aa);
	
    return (NoL * NoV * 2.0) / (t0 + t1);
}

float GGX_G(float ct, float alpha)
{
    float aa = alpha * alpha;
    float ct2 = ct * ct;
    
    return 2.0 * ct / (ct + sqrt(aa + ct2 - aa * ct2));
}

float GGX_D(float NoH, float alpha)
{
    float aa = alpha * alpha;
    
    float t = (NoH * aa - NoH) * NoH + 1.0;

	return aa / (pi * (t * t));
}

/*
#elif 0
float GGX_D(float NoH, float a)
{
    //float t = (NoH * (a*a) - NoH) * NoH + 1.0;
	//return (a*a-1.0) / (log(a*a) * pi * (t));
    
    float t = (NoH * (a*a) - NoH) * NoH + 1.0;
	return (a*a-1.0) / (log(a*a*2.0/(1.0+a*a)) * pi * (t))*0.5;
}
#else
float GGX_D(float NoH, float a)
{
    float t = (NoH * (a*a) - NoH) * NoH + 1.0;
	float n = (a*a-1.0) / (log(a*a) * pi * (t));
    
    float t2 = (NoH * (a*a) - NoH) * NoH + 1.0;
	float n2 = (a*a) / (pi * (t2 * t2));
    
    return mix(n, n2, 0.99);
}
#endif
*/

vec3 GGX_BRDF(vec3 N, vec3 V, vec3 L, float alpha, vec3 f0)
{
    vec3 H  = normalize(V + L);
    float VoH = clamp01(dot(V, H));
    float NoH = clamp01(dot(N, H));
    float NoV = clamp01(dot(N, V));
    float NoL = clamp01(dot(N, L));
    
    float denom = NoV * NoL;

    if (denom == 0.0) return vec3(0.0);

    float D = GGX_D(NoH, alpha);
    float G = GGX_G(NoL, NoV, alpha);
    vec3  F = FresnelSchlick(VoH, f0);

    return (F * G * D) * 0.25 / denom;
}

vec3 GGX_R(vec3 N, vec3 V, vec3 L, float alpha, vec3 f0)
{
    vec3 H  = normalize(V + L);
    float VoH = clamp01(dot(V, H));
    float NoH = clamp01(dot(N, H));
    float NoV = clamp01(dot(N, V));
    float NoL = clamp01(dot(N, L));
    
    float denom = NoV;

    if (denom == 0.0) return vec3(0.0);

    float D = GGX_D(NoH, alpha);
    float G = GGX_G(NoL, NoV, alpha);
    vec3  F = FresnelSchlick(VoH, f0);

    return (F * G * D) * 0.25 / denom;
}


float GGXAlphaFromRoughness(float roughness) 
{
    return roughness * roughness;
}

float F0FromReflectance(float reflectance)
{
    return reflectance * reflectance * 0.16;
}

void ConvertMtlParams(vec3 color, float reflectance, float metalness, out vec3 albedo, out vec3 F0)
{
    F0 = mix(vec3(F0FromReflectance(reflectance)), color, metalness);
    
    albedo = color * (1.0 - metalness);
}
                      
/* https://media.gdcvault.com/gdc2017/Presentations/Hammon_Earl_PBR_Diffuse_Lighting.pdf */
/* https://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf */ 
/* https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf */
float DisneyDiffuse_BRDF(float NoV, float NoL, float HoL, float linearRoughness)
{
	float energyBias   = mix(0.0,     0.5 , linearRoughness);
	float energyFactor = mix(1.0, 1.0/1.51, linearRoughness);
    
	float fd90 = energyBias + 2.0 * (HoL*HoL) * linearRoughness;
    
	const float f0 = 1.0;
    
	float lightScatter = FresnelSchlick(NoL, f0, fd90);
	float viewScatter  = FresnelSchlick(NoV, f0, fd90);
	
	return lightScatter * viewScatter * energyFactor * rpi;
}

/* https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf */
vec3 Frostbite_R(vec3 V, vec3 N, vec3 L, vec3 albedo, float roughness, vec3 F0)
{    
    float alpha = GGXAlphaFromRoughness(roughness);
    
    vec3 H = normalize(V + L);
    
    float NoH = clamp01(dot(N, H));
    float NoV = clamp01(dot(N, V));
    float NoL = clamp01(dot(N, L));
    float HoV = clamp01(dot(H, V));
    
    if(NoL == 0.0 || NoV == 0.0) return vec3(0.0);
    
    float D   = GGX_D(NoH,      alpha);
    float Vis = GGX_V(NoL, NoV, alpha);
    float G   = GGX_G(NoV, NoL, alpha);
    
    vec3 F = FresnelSchlick(HoV, F0);

    vec3 diffuse = albedo * DisneyDiffuse_BRDF(NoV, NoL, HoV, roughness);

    return (diffuse + D * F * Vis) * NoL;
}


/* Eric Heitz | Sampling the GGX Distribution of Visible Normals | http://jcgt.org/published/0007/04/01/ */
// Input Ve: view direction
// Input alpha_x, alpha_y: roughness parameters
// Input U1, U2: uniform random numbers
// Output Ne: normal sampled with PDF D_Ve(Ne) = G1(Ve) * max(0, dot(Ve, Ne)) * D(Ne) / Ve.z
vec3 Sample_GGX_VNDF(vec3 Ve, float alpha_x, float alpha_y, float U1, float U2)
{
	// Section 3.2: transforming the view direction to the hemisphere configuration
	vec3 Vh = normalize(Ve * vec3(alpha_x, alpha_y, 1.0));
	
    // Section 4.1: orthonormal basis (with special case if cross product is zero)
	float lensq = (Vh.x*Vh.x) + (Vh.y*Vh.y);
	vec3 T1 = lensq > 0.0 ? vec3(-Vh.y, Vh.x, 0.0) * inversesqrt(lensq) : vec3(1.0, 0.0, 0.0);
	vec3 T2 = cross(Vh, T1);
	
    // Section 4.2: parameterization of the projected area
	float r = sqrt(U1);
	float phi = 2.0 * pi * U2;
	float t1 = r * cos(phi);
	float t2 = r * sin(phi);
	float s = 0.5 * (1.0 + Vh.z);
	t2 = (1.0 - s)*sqrt(1.0 - t1*t1) + s*t2;
    
	// Section 4.3: reprojection onto hemisphere
	vec3 Nh = t1*T1 + t2*T2 + sqrt(max(0.0, 1.0 - t1*t1 - t2*t2))*Vh;
    
	// Section 3.4: transforming the normal back to the ellipsoid configuration
	vec3 Ne = normalize(vec3(Nh.xy, max(0.0, Nh.z)) * vec3(alpha_x, alpha_y, 1.0));
    
	return Ne;
}

#if 1
// routines that sample the visible distribution of microfacet normals

// s [0..1]
void Sample_GGX_R(vec2 s, vec3 V, vec3 N, float alpha, vec3 F0, out vec3 L, out vec3 w)
{
    vec3 H;
    {
    	vec3 ox, oz;
		OrthonormalBasisRH(N, /*out*/ ox, oz);
    	
    	vec3 Vp = vec3(dot(V, ox), dot(V, oz), dot(V, N));
    	
        vec3 Hp = Sample_GGX_VNDF(Vp, alpha, alpha, s.x, s.y);
    	
        H = ox*Hp.x + N*Hp.z + oz*Hp.y;
    }
    
    vec3 F = FresnelSchlick(dot(H, V), F0);

    L = 2.0 * dot(V, H) * H - V;
    
    float NoV = clamp01(dot(N, V));
    float NoL = clamp01(dot(N, L));
    
    float G2 = GGX_G(NoV, NoL, alpha);
    float G1 = GGX_G(NoV, alpha);
    
    w = G1 == 0.0 ? vec3(0.0) : F * G2 / G1;
}

// s [0..1]
void Sample_GGX_R(vec2 s, vec3 V, vec3 N, float alpha, vec3 F0, out vec3 L, out vec3 f, out float pdf)
{
    vec3 H;
    {
    	vec3 ox, oz;
		OrthonormalBasisRH(N, /*out*/ ox, oz);
    	
    	vec3 Vp = vec3(dot(V, ox), dot(V, oz), dot(V, N));
    	
        vec3 Hp = Sample_GGX_VNDF(Vp, alpha, alpha, s.x, s.y);
    	
        H = ox*Hp.x + N*Hp.z + oz*Hp.y;
    }
    
    vec3 F = FresnelSchlick(dot(H, V), F0);

    L = 2.0 * dot(H, V) * H - V;
    
    float NoV = clamp01(dot(N, V));
    float NoL = clamp01(dot(N, L));
    float HoV = clamp01(dot(H, V));
    float NoH = clamp01(dot(N, H));
    
    float G1 = GGX_G(NoV, alpha);
    float G2 = GGX_G(NoV, NoL, alpha);
    float D  = GGX_D(NoH, alpha);
    
    f   = NoV == 0.0 ? vec3(0.0) : (F * G2 * D) * 0.25 / NoV;
    pdf = NoV == 0.0 ?      0.0  : (    G1 * D) * 0.25 / NoV;
}

float EvalPDF_GGX_R(vec3 V, vec3 N, vec3 L, float alpha)
{
    vec3 H = normalize(V + L);
    float NoH = clamp01(dot(N, H));
    float NoV = clamp01(dot(N, V));
    
    /*
    float G1 = GGX_G(NoV, alpha);
    float D  = GGX_D(NoH, alpha);
    
    return (G1 * D) * 0.25 / NoV;
    /*/
    float alpha2 = alpha*alpha;
    float NoV2 = NoV*NoV;
    
    float t0 =     (NoH  *  alpha2 - NoH) * NoH + 1.0;
    float t1 = sqrt(NoV2 * -alpha2 + NoV2 + alpha2) + NoV;
    
    float denom = (t0*t0) * t1;
    
    return denom == 0.0 ? 0.0 : (alpha2 * rpi2) / denom;
    //*/
}

#else
// routines that sample the distribution of microfacet normals (ignoring visibility)

// s [0..1]
void Sample_GGX_R(vec2 s, vec3 V, vec3 N, float alpha, vec3 F0, out vec3 L, out vec3 w)
{
    float l = rsqrt((alpha*alpha)/s.y + 1.0 - (alpha*alpha));
    
    vec3 H = Sample_Sphere(s.x * 2.0 - 1.0, l, N);

    L = 2.0 * dot(V, H) * H - V;
    
    float HoV = clamp01(dot(H, V));
    float NoV = clamp01(dot(N, V));
    float NoL = clamp01(dot(N, L));
    float NoH = clamp01(dot(N, H));

    vec3  F = FresnelSchlick(HoV, F0);  
    float G = GGX_G(NoV, NoL, alpha);
    
    float denom = NoV * NoH;
    
    w = denom == 0.0 ? vec3(0.0) : F * G * HoV / denom;
}

// s [0..1]
void Sample_GGX_R(vec2 s, vec3 V, vec3 N, float alpha, vec3 F0, out vec3 L, out vec3 f, out float pdf)
{
    float l = rsqrt((alpha*alpha)/s.y + 1.0 - (alpha*alpha));
    
    vec3 H = Sample_Sphere(s.x * 2.0 - 1.0, l, N);

    L = 2.0 * dot(V, H) * H - V;
    
    float HoV = clamp01(dot(H, V));
    float NoV = clamp01(dot(N, V));
    float NoL = clamp01(dot(N, L));
    float NoH = clamp01(dot(N, H));

    vec3 F = FresnelSchlick(HoV, F0);  
    float G = GGX_G(NoL, NoV, alpha);
    float D = GGX_D(NoH, alpha);
    
    f   = NoV == 0.0 ? vec3(0.0) : (F * G  * D) * 0.25 / NoV;
    pdf = HoV == 0.0 ?      0.0  : (   NoH * D) * 0.25 / HoV;
}

float EvalPDF_GGX_R(vec3 V, vec3 N, vec3 L, float alpha)
{
    vec3 H = normalize(V + L);
    float NoH = clamp01(dot(N, H));
    float HoV = clamp01(dot(H, V));
    
    float D  = GGX_D(NoH, alpha);
    
    return HoV == 0.0 ? 0.0 : (NoH * D) * 0.25 / HoV;
}
#endif


// s0 [0..1], s1 [0..1], s2 [0..1]
void Sample_ScatteredDir(vec2 s0, vec2 s1, float s2, inout vec3 rd, inout vec3 W, vec3 N, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    vec3 V = -rd;

    vec3 L0, w0;
    {
        vec3 L = Sample_ClampedCosineLobe(s0.x * 2.0 - 1.0, s0.y, N);
        
        vec3 H = normalize(V + L);
        
        float HoV = clamp01(dot(H, V));
    	float NoV = clamp01(dot(N, V));
    	float NoL = clamp01(dot(N, L));
        
    	w0 = albedo * DisneyDiffuse_BRDF(NoV, NoL, HoV, roughness) * pi;
        L0 = L;
    }
    
    vec3 L1, w1;
    {
        vec3 L, w;
    	Sample_GGX_R(s1, V, N, alpha, F0, /*out*/ L1, /*out*/ w1);
    }

    float w0s = dot(w0, vec3(0.2, 0.7, 0.1));
    float w1s = dot(w1, vec3(0.2, 0.7, 0.1));
    
    if(w0s == 0.0 && w1s == 0.0)
    {
        W = vec3(0.0);
        rd = L0;
        
        return;
    }
    
    #if 0
    w0s = 0.5;
    w1s = 1.0 - w0s;
    #elif 0
    float wn = (w0s*w0s) / ((w0s*w0s) + (w1s*w1s));
    #else
    float wn = w0s / (w0s + w1s);
	#endif
    
    bool doUseSmpl0 = s2 <= wn;

    float denom = doUseSmpl0 ? wn : (1.0 - wn);

    rd = doUseSmpl0 ? L0 : L1;
    W *= doUseSmpl0 ? w0 : w1;

    W /= denom == 0.0 ? 1.0 : denom;
}

// s0 [0..1], s1 [0..1], s2 [0..1]
void Sample_ScatteredDirMIS(vec2 s0, vec2 s1, float s2, inout vec3 rd, inout vec3 W, vec3 N, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    vec3 V = -rd;

    vec3 L0; float pdf00;
    {
        L0 = Sample_ClampedCosineLobe(s0.x * 2.0 - 1.0, s0.y, N);
		pdf00 = dot(N, L0) * rpi;        
    }

    vec3 L1; vec3 f1; float pdf11;
    Sample_GGX_R(s1, V, N, alpha, F0, /*out*/ L1, /*out*/ f1, /*out*/ pdf11);

    vec3 f0 = Frostbite_R(V, N, L0, albedo, roughness, F0);
         f1 = Frostbite_R(V, N, L1, albedo, roughness, F0);

    float pdf01 = dot(N, L1) * rpi;
    float pdf10 = EvalPDF_GGX_R(V, N, L0, alpha);

    float w0, w1;
    #if 0
    w0 = 0.5; 
    w1 = 1.0 - w1;
    #elif 1
    w0 = Pow2(pdf00) / (Pow2(pdf00) + Pow2(pdf10));
    w1 = Pow2(pdf11) / (Pow2(pdf11) + Pow2(pdf01));        
    #else
    w0 = (pdf00) / ((pdf00) + (pdf10));
    w1 = (pdf11) / ((pdf11) + (pdf01));  
    #endif

    #if 0
    if(albedo.r == 0.0 && albedo.g == 0.0 && albedo.b == 0.0)
    {
    	w0 = 0.0;
    	w1 = 1.0;
    }
    #endif
    
    float wn = w0 / (w0 + w1);

    bool doUseSmpl0 = s2 <= wn;

    float denom = doUseSmpl0 ? pdf00 *        wn : 
                               pdf11 * (1.0 - wn);

    rd = doUseSmpl0 ? L0 : L1;

    if(denom == 0.0)
    {
        W = vec3(0.0);
        
        return;
    }
    
    if(doUseSmpl0)
        W *= f0 * w0;
    else
        W *= f1 * w1;

    W /= denom;
}



float Intersect_Ray_Sphere(
vec3 rp, vec3 rd, 
vec3 sp, float sr2, 
out vec2 t)
{	
	rp -= sp;
	
	float a = dot(rd, rd);
	float b = 2.0 * dot(rp, rd);
	float c = dot(rp, rp) - sr2;
	
	float D = b*b - 4.0*a*c;
	
	if(D < 0.0) return 0.0;
	
	float sqrtD = sqrt(D);
	// t = (-b + (c < 0.0 ? sqrtD : -sqrtD)) / a * 0.5;
	t = (-b + vec2(-sqrtD, sqrtD)) / a * 0.5;
	
	// if(start == inside) ...
	if(c < 0.0) t.xy = t.yx;

	// t.x > 0.0 || start == inside ? infront : behind
	return t.x > 0.0 || c < 0.0 ? 1.0 : -1.0;
}

float Intersect_Ray_Cube(vec3 rp, vec3 rd, vec3 cth, out vec2 t)
{	
	vec3 m = 1.0 / -rd;
	vec3 o = If(lessThan(rd, vec3(0.0)), -cth, cth);
	
	vec3 uf = (rp + o) * m;
	vec3 ub = (rp - o) * m;
	
	t.x = max(uf.x, max(uf.y, uf.z));
	t.y = min(ub.x, min(ub.y, ub.z));
	
	bool inside = t.x < 0.0 && t.y > 0.0;
    
	if(inside) {return 0.0;}
	
	return t.y < t.x ? -1.0 : (t.x > 0.0 ? 1.0 : -1.0);
}
