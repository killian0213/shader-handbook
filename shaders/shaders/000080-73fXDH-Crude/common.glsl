// Common (common) — Crude by igneus
// https://www.shadertoy.com/view/73fXDH

/*
    GLOBAL PARAMETERS
    -------------------------------------------------------------------------------------------------------   
*/

// Shader properties
#define kColourfulMode               0                  // Pretty colours. 0 = off, 1 = on. 

// General properties
#define kSpeed                       (1.2 * 1.)         // Controls the speed of the animation
#define kTimeOffset                  40.                // Offsets the starting time
#define kTimeMode                    1                  // Determines how the current time is calculated. 0 = iFrame / kReferenceFPS. 1 = iTime.
#define kReferenceFPS                60                 // The reference framerate when kTimeMode == 0
#define kNormalMode                  1                  // 0 = Compute normals on-demand at shading time. 1 = Pre-cache normals when computing heightmap. 2 = Pre-cache using previous frame's heightmap (much faster)
#define kFocalMode                   1                  // 0 = Camera focus sweeps back and forth. 1 = Camera focus tracks head.

// Post processing effects
#define kApplyVignette               true               // Simulates lens vignetting by darkening the fringes of the image 
#define kApplyColourGrade            true               // Applies a colour grade to the image
#define kApplyFilmGrain              true               // Simulates film grain
#define kApplyInterferenceDamage     false              // Simulates damage caused by signal interference
#define kApplyJPEGDamage             false              // Simulates damage caused by JPEG compression 
#define kSharpening                  3.0                // The amount of sharpening to apply to the final image

// Defocus blur properties
#define kDoFKernelRadius             20                 // The actual radius of the DoF kernel in texture taps
#define kDofKernelAtrousStride       4.                 // The stride of the DoF kernel. Increase to enlarge the kernel at the risk of aliasing
#define kApertureBlades              5                  // The number of blades on the iris
#define kApertureBladeCurvature      .2                 // The curvature of the blades. 0 = no curviture, >0 = positive and <0 = negative curviture.
#define kApertureBladePhase          0.0                // The phase angle offset of the blades
#define kApertureAberration          .7                 // The amount of aberration visible in the bokeh
#define kApertureFalloff             2.                 // The aberration fall-off
#define kApertureGain                3.                 // The gain factor equivalent to the normalization constant

// Wetmap effects 
#define kRunoffRate                  .5                 // How quickly the fluid runs off the head
#define kRunoffDripMax               1.                 // Drip max and min specify unevenness of the flowing effect of the fluid
#define kRunoffDripMin               0.2
#define kRunoffDripScale             0.05               // The scale of the unevenness of the drip effect
#define kDryRate                     0.01               // How quickly the fluid dries up 

// Water effects
#define kWaterHarmonics              8                  // How many noise terms are summed to create the fractional brownian motion of the waves
#define kWaterFlowDirection          vec2(0.1, 0)       // Which direction the liquid flows
#define kWaterNoiseScale             3.1                // 
#define kWaterScaleExp               2.2                // The downscale exponent between each harmonic
#define kWaterAmplitude              0.45               // the peak amplitude of the waves
#define kWaterBias                   0.12               // The bias offset of the heightfield
#define kWaterWaveSpeed              0.1                // How fast waves rise and fall
#define kWaterAdvectionSpeed         0.21               // The speed of the advection effect
#define kWaterAdvectionScale         3.                 // The scale of advection

/***********************************************************************************************************************/

#define kPi                    3.14159265359
#define kInvPi                 (1.0 / 3.14159265359)
#define kTwoPi                 (2.0 * kPi)
#define kFourPi                (4.0 * kPi)
#define kHalfPi                (0.5 * kPi)
#define kRootPi                1.77245385091
#define kRoot2                 1.41421356237
#define kLog10                 2.30258509299
#define kFltMax                3.402823466e+38
#define kLog2                  0.6931471805
#define kOneThird              (1.0 / 3.0)
#define kIntMax                0x7fffffff
#define kOne                   vec3(1.)
#define kZero                  vec3(0.)
#define kRed                   vec3(1., 0., 0.)
#define kYellow                vec3(1., 1., 0.)
#define kGreen                 vec3(0., 1., 0.)
#define kBlue                  vec3(0., 0., 1.)
#define kPink                  vec3(1., 0., 0.2) 

#define iRes                   iResolution
#define iResXYRatio            (iRes.x / iRes.y)
#define iResYXRatio            (iRes.y / iRes.x)

float cubrt(float a)           { return sign(a) * pow(abs(a), 1.0 / 3.0); }
float toRad(float deg)         { return kTwoPi * deg / 360.0; }
float toDeg(float rad)         { return 360.0 * rad / kTwoPi; }
float sqr(float a)             { return a * a; }
vec2 sqr(vec2 a)               { return a * a; }
vec3 sqr(vec3 a)               { return a * a; }
vec4 sqr(vec4 a)               { return a * a; }
int sqr(int a)                 { return a * a; }
int cub(int a)                 { return a * a * a; }
float cub(float a)             { return a * a * a; }
float pow4(float a)            { a *= a; return a * a; }
int mod2(int a, int b)         { return ((a % b) + b) % b; }
float mod2(float a, float b)   { return mod(mod(a, b) + b, b); }
vec3 mod2(vec3 a, vec3 b)      { return mod(mod(a, b) + b, b); }
float length2(vec2 v)          { return dot(v, v); }
float length2(vec3 v)          { return dot(v, v); }
int sum(ivec2 a)               { return a.x + a.y; }
float sum(vec2 v)              { return v.x + v.y; }
float sum(vec3 v)              { return v.x + v.y + v.z; }
float sum(vec4 v)              { return v.x + v.y + v.z + v.w; }
float luminance(vec3 v)        { return v.x * 0.17691 + v.y * 0.8124 + v.z * 0.01063; }
float mean(vec3 v)             { return v.x / 3.0 + v.y / 3.0 + v.z / 3.0; }
vec4 mul4(vec3 a, mat4 m)      { return vec4(a, 1.0) * m; }
vec3 mul3(vec3 a, mat4 m)      { return (vec4(a, 1.0) * m).xyz; }
#define sin01(a)               (0.5 * sin(a) + 0.5)
#define cos01(a)               (0.5 * cos(a) + 0.5)
#define saturate(a)            clamp(a, 0.0, 1.0)
float cwiseMax(vec3 v)         { return max(max(v.x, v.y), v.z); }
int cwiseMax(ivec3 v)         { return max(max(v.x, v.y), v.z); }
float cwiseMax(vec2 v)         { return max(v.x, v.y); }
int cwiseMax(ivec2 v)          { return max(v.x, v.y); }
float cwiseMin(vec3 v)         { return min(min(v.x, v.y), v.z); }
int cwiseMin(ivec3 v)          { return min(min(v.x, v.y), v.z); }
float cwiseMin(vec2 v)         { return min(v.x, v.y); }
float max3(float a, float b, float c) { return (a > b) ? ((a > c) ? a : c) : ((b > c) ? b : c); }
float min3(float a, float b, float c) { return (a < b) ? ((a < c) ? a : c) : ((b < c) ? b : c); }
void sort(inout float a, inout float b) { if(a > b) { float s = a; a = b; b = s; } }
void swap(inout float a, inout float b) { float s = a; a = b; b = s; }
void swap(inout int a, inout int b) { int s = a; a = b; b = s; }

float Smoothstep(float t) { return t * t * (3.0 - 2.0 * t); }
vec2 Smoothstep(vec2 t) { return t * t * (3.0 - 2.0 * t); }
vec3 Smoothstep(vec3 t) { return t * t * (3.0 - 2.0 * t); }
float Smoothstep(float a, float b, float t) { return mix(a, b, t * t * (3.0 - 2.0 * t)); }
float Smootherstep(float t) { return t * t * t * (t * (6. * t - 15.) + 10.); }
float Smootherstep(float a, float b, float t) { return mix(a, b, t * t * t * (t * (6. * t - 15.) + 10.)); }

float saw(float a)             
{ 
    a = mod(a / kPi, 2.);
    return (1. - (2. * abs(fract(a) - 0.5))) * -(floor(a) * 2. - 1.);
}

float cosaw(float a) { return saw(a + kHalfPi); }
float saw01(float a) { return saw(a) * 0.5 + 0.5; }
float cosaw01(float a) { return saw(a + kHalfPi) * 0.5 + 0.5; }

vec3 SafeNormaliseTexel(vec4 t)
{
    return t.xyz / max(1e-15, t.w);
}

vec4 Sign(vec4 v)
{
    return step(vec4(0.0), v) * 2.0 - 1.0;
}

float Sign(float v)
{
    return step(0.0, v) * 2.0 - 1.0;
}


float SignedPow(float v, float gamma) { return sign(v) * pow(abs(v), gamma); }
vec2 SignedPow(vec2 v, vec2 gamma) { return sign(v) * pow(abs(v), gamma); }


float UintToFloat01(uint i)
{
    return float(i) / float(0xffffffffu);
}

float UintToFloat01(uint i, int  bits)
{
    return float(i & ((1u << bits) - 1u)) / float(((1u << bits) - 1u));
}

float Sigmoid(float x, float d)
{
    return 1. / (1. + exp(-((2.*x-1.) * d)));
}


// *******************************************************************************************************
//    Hash functions
// *******************************************************************************************************

// Constants for the Fowler-Noll-Vo hash function
// https://en.wikipedia.org/wiki/Fowler-Noll-Vo_hash_function
#define kFNVPrime              0x01000193u
#define kFNVOffset             0x811c9dc5u
#define kDimsPerBounce         4

// Mix and combine two hashes
uint HashCombine_ShiftXor(uint a, uint b)
{
    return (((a << (31u - (b & 31u))) | (a >> (b & 31u)))) ^
            ((b << (a & 31u)) | (b >> (31u - (a & 31u))));
}

// Old combiner from boost::hash_combine()
uint HashCombine_Boost(uint a, uint b)
{
    return b ^ (a + 0x9e3779b9u + (b<<6) + (b>>2));
}

#define HashCombine HashCombine_Boost

// Compute a 32-bit Fowler-Noll-Vo hash for the given input
uint HashOf_FNV2a(uint i)
{
    uint h = (kFNVOffset ^ (i & 0xffu)) * kFNVPrime;
    h = (h ^ ((i >> 8u) & 0xffu)) * kFNVPrime;
    h = (h ^ ((i >> 16u) & 0xffu)) * kFNVPrime;
    h = (h ^ ((i >> 24u) & 0xffu)) * kFNVPrime;
    return h;
}

// "Single-use" PCG hash functions to reduce n -> 1
uint HashOf_PCG_n_1(uint seed)
{
	uint a = seed * 747796405u + 2891336453u;
	uint b = ((a >> ((a >> 28u) + 4u)) ^ a) * 277803737u;
	return (b >> 22u) ^ b;
}

uint HashOf_PCG_n_1(uvec2 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v>>16u);
    v.x += v.y * 1664525u;
    return v.x ^ (v.x>>16u);
}

uint HashOf_PCG_n_1(uvec3 v) 
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;
    v ^= v >> 16u;
    return v.x + v.y*v.z;
}

uint HashOf_PCG_n_1(uvec4 v)
{
    v = v * 1664525u + 1013904223u;    
    v.x += v.y*v.w;
    v.y += v.z*v.x;
    v.z += v.x*v.y;
    v.w += v.y*v.z;    
    v ^= v >> 16u;    
    return v.x + v.y*v.w;
}

#define HashOf(v) HashOf_PCG_n_1(v)
#define HashOfAsFloat(v) (float(HashOf_PCG_n_1(v)) / float(0xffffffffu))

#define RNGCtx uvec4

uvec4 HashOf_PCG_n_n(uvec4 rngSeed)
{
    rngSeed = rngSeed * 1664525u + 1013904223u;
    
    rngSeed.x += rngSeed.y*rngSeed.w; 
    rngSeed.y += rngSeed.z*rngSeed.x; 
    rngSeed.z += rngSeed.x*rngSeed.y; 
    rngSeed.w += rngSeed.y*rngSeed.z;
    
    rngSeed ^= rngSeed >> 16u;
    
    rngSeed.x += rngSeed.y*rngSeed.w; 
    rngSeed.y += rngSeed.z*rngSeed.x; 
    rngSeed.z += rngSeed.x*rngSeed.y; 
    rngSeed.w += rngSeed.y*rngSeed.z;
    
    return rngSeed;
}

vec2 BoxMuller(vec2 xi)
{
    return sqrt(-2. * log(xi.x)) * vec2(cos(kTwoPi * xi.y), sin(kTwoPi * xi.y));
}

// Generates a tuple of canonical random number and uses them to sample an input texture
vec4 Rand4(inout RNGCtx ctx, ivec2 xy, sampler2D sampler)
{
    ctx = HashOf_PCG_n_n(ctx);
    return texelFetch(sampler, (xy + ivec2(ctx >> 16)) % 1024, 0);
}

// Generates a tuple of canonical random numbers in the range [0, 1]
vec4 Rand4(inout RNGCtx ctx)
{
    ctx = HashOf_PCG_n_n(ctx);
    return vec4(ctx) / float(0xffffffffu);
}

// Generates a tuple of canonical random numbers
uvec4 URand4(inout RNGCtx ctx) 
{ 
    ctx = HashOf_PCG_n_n(ctx);
    return ctx;
}

// Seed the PCG hash function with the current frame multipled by a prime
RNGCtx InitRNG(uint seed)
{    
    return uvec4(20219u, 7243u, 12547u, 28573u) * seed;
}

vec4 HashOfAsVec4(uint seed)
{
    return vec4(HashOf_PCG_n_n(uvec4(20219u, 7243u, 12547u, 28573u) * seed)) / vec4(0xffffffffu);
}

vec4 HashOfAsVec4(uvec2 seed)
{
    return vec4(HashOf_PCG_n_n(uvec4(20219u * seed.x, 7243u * seed.y, 12547u, 28573u))) / vec4(0xffffffffu);
}


// Reverse the bits of 32-bit inteter
uint RadicalInverse(uint i)
{
    i = ((i & 0xffffu) << 16u) | (i >> 16u);
    i = ((i & 0x00ff00ffu) << 8u) | ((i & 0xff00ff00u) >> 8u);
    i = ((i & 0x0f0f0f0fu) << 4u) | ((i & 0xf0f0f0f0u) >> 4u);
    i = ((i & 0x33333333u) << 2u) | ((i & 0xccccccccu) >> 2u);    
    i = ((i & 0x55555555u) << 1u) | ((i & 0xaaaaaaaau) >> 1u);        
    return i;
}

// Samples the radix-2 Halton sequence from seed value, i
float HaltonBase2(uint i)
{    
    return float(RadicalInverse(i)) / float(0xffffffffu);
}

const mat4 kOrderedDither = mat4(vec4(0.0, 8.0, 2.0, 10.), vec4(12., 4., 14., 6.), vec4(3., 11., 1., 9.), vec4(15., 7., 13., 5.));
float OrderedDither(ivec2 xyScreen)
{    
    return (kOrderedDither[xyScreen.x & 3][xyScreen.y & 3] + 0.5) / 16.0;
}


// Fast construction of orthonormal basis using quarternions to avoid expensive normalisation and branching 
// From Duf et al's technical report https://graphics.pixar.com/library/OrthonormalB/paper.pdf, inspired by
// Frisvad's original paper: http://orbit.dtu.dk/files/126824972/onb_frisvad_jgt2012_v2.pdf
mat3 CreateBasis(vec3 n)
{
    float s = Sign(n.z);
    float a = -1.0 / (s + n.z);
    float b = n.x * n.y * a;
    
    return mat3(vec3(1.0f + s * n.x * n.x * a, s * b, -s * n.x),
                vec3(b, s + n.y * n.y * a, -n.y),
                n);
}

mat3 CreateBasis(vec3 n, vec3 up)
{
    vec3 tangent = normalize(cross(n, up));
	vec3 cotangent = cross(tangent, n);

	return transpose(mat3(tangent, cotangent, n));
}


// The minimum amount of data required to define an infinite ray in 3D space
struct RayBasic
{
    vec3   o;                   // Origin 
    vec3   d;                   // Direction  
};

// The "full fat" ray objects that most methods will refer to
struct Ray
{
    RayBasic od;   
    
    float    tNear;
    vec3     weight;
    uint     flags;
    int      depth;
};

struct HitCtx
{
    int      matID;
    int      objID;
    vec3     n;
    vec3     pObj;
    vec3     tangent, cotangent;
    vec2     uv;
    float    alpha, beta;
    float    albedo;
    float    kickoff;
};

struct RenderCtx
{
    RNGCtx rng;
    ivec2 xyScreen;
};

#define kFlagsBackfacing      1u
#define kFlagsSubsurface      2u
#define kFlagsDirectSampleLight 4u
#define kFlagsDirectSampleBxDF 8u
#define kFlagsScattered       16u
#define kFlagsProbePath       32u
#define kFlagsCausticPath     64u
#define kFlagsVolumetricPath  128u
#define kFlagsInteracted      256u

//#define InheritFlags(ray) (ray.flags & kFlagsScattered)
#define InheritFlags(ray) (ray.flags & (kFlagsProbePath | kFlagsCausticPath | kFlagsInteracted))

#define IsBackfacing(ray) ((ray.flags & kFlagsBackfacing) != 0u)
#define IsSubsurface(ray) ((ray.flags & kFlagsSubsurface) != 0u)
#define IsScattered(ray) ((ray.flags & kFlagsScattered) != 0u)
#define IsDirectSampleLight(ray) ((ray.flags & kFlagsDirectSampleLight) != 0u)
#define IsDirectSampleBxDF(ray) ((ray.flags & kFlagsDirectSampleBxDF) != 0u)
#define IsDirectSample(ray) ((ray.flags & (kFlagsDirectSampleLight | kFlagsDirectSampleBxDF)) != 0u)
#define IsProbePath(ray) ((ray.flags & kFlagsProbePath) != 0u)
#define IsCausticPath(ray) ((ray.flags & kFlagsCausticPath) != 0u)
#define IsVolumetricPath(ray) ((ray.flags & kFlagsVolumetricPath) != 0u)
#define HasInteracted(ray) ((ray.flags & kFlagsInteracted) != 0u)


void SetRayFlag(inout Ray ray, in uint flag, in bool set)
{
    ray.flags &= ~flag;
    ray.flags |= flag * uint(set);
}

void CreateRay(inout Ray ray, vec3 o, vec3 d, vec3 kickoff, vec3 weight, int depth, uint flags)
{     
    ray.od.o = o + kickoff;
    ray.od.d = d;
    ray.tNear = kFltMax;
    ray.weight = weight;
    ray.flags = flags;
    ray.depth = depth;
}

vec3 PointAt(Ray ray) { return ray.od.o + ray.od.d * ray.tNear; }
vec3 PointAt(RayBasic ray, float t) { return ray.o + ray.d * t; }

struct Transform
{
    vec3 pos;
    mat3 rot;
    float sca;
};

RayBasic RayToObjectSpace(in RayBasic world, in Transform transform) 
{
	RayBasic object;
	object.o = world.o - transform.pos;
	object.d = world.d + object.o;
	object.o = transform.rot * object.o / transform.sca;
	object.d = (transform.rot * object.d / transform.sca) - object.o;
	return object;
}

vec3 PointToObjectSpace(in vec3 world, in Transform transform) 
{
	return transform.rot * (world - transform.pos) / transform.sca;
}

// Quaternion multiplication
vec4 QuatMul(vec4 r, vec4 q)
{
    return vec4(r[0]*q[0] - r[1]*q[1] - r[2]*q[2] - r[3]*q[3],
                r[0]*q[1] + r[1]*q[0] - r[2]*q[3] + r[3]*q[2],
                r[0]*q[2] + r[1]*q[3] + r[2]*q[0] - r[3]*q[1],
                r[0]*q[3] - r[1]*q[2] + r[2]*q[1] + r[3]*q[0]);
}

// Unit quarternion to 3x3 rotation matrix
vec4 MatToQuat(mat3 m)
{
    float w = 0.5 * sqrt(1. + m[0][0] + m[1][1] + m[2][2]);
    return vec4(w, 
                (m[2][1] - m[1][2]) / (4.*w),
                (m[0][2] - m[2][0]) / (4.*w),
                (m[1][0] - m[0][1]) / (4.*w));
}

// Axis-angle to unit quaternion
vec4 AxisAngleToQuat(vec3 axis, float theta)
{
    return vec4(cos(theta*0.5), axis * sin(theta*0.5)); 
}

// Unit quarternion to 3x3 rotation matrix
mat3 QuatToMat(vec4 q)
{
    return 2. * mat3(vec3(0.5 - q.z*q.z - q.w*q.w, q.y*q.z + q.x*q.w, q.y*q.w - q.x*q.z),
                     vec3(q.y*q.z - q.x*q.w, 0.5 - q.y*q.y - q.w*q.w, q.z*q.w + q.x*q.y),
                     vec3(q.y*q.w + q.x*q.z, q.z*q.w - q.x*q.y, 0.5 - q.y*q.y - q.z*q.z));
}

mat3 Identity()
{
    return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0));
}

mat2 RotMat2(float theta)
{
    float cosTheta = cos(theta), sinTheta = sin(theta);
    return mat2(sinTheta, cosTheta, -cosTheta, sinTheta);
}

mat3 ScaleMat3(float scale)
{
    float invScale = 1.0f / scale;
	return mat3(vec3(invScale, 0.0, 0.0),
			vec3(0.0, invScale, 0.0),
			vec3(0.0, 0.0, invScale));
}

mat3 RotXMat3(float theta)
{
    float cosTheta = cos(theta), sinTheta = sin(theta);
	return mat3(vec3(1.0, 0.0, 0.0),
			vec3(0.0, cosTheta, -sinTheta),
			vec3(0.0, sinTheta, cosTheta));
}

mat3 RotYMat3(const float theta)
{
    float cosTheta = cos(theta), sinTheta = sin(theta);
	return mat3(vec3(cosTheta, 0.0, sinTheta),
			vec3(0.0, 1.0, 0.0),
			vec3(-sinTheta, 0.0, cosTheta));
}

mat3 RotZMat3(const float theta)
{
    float cosTheta = cos(theta), sinTheta = sin(theta);
	return mat3(vec3(cosTheta, -sinTheta, 0.0),
			vec3(sinTheta, cosTheta, 0.0),
			vec3(0.0, 0.0, 1.0));
}

mat3 CompoundRotMat3(vec3 rot)
{
    mat3 m = Identity();
    if (rot.x != 0.0) { m *= RotXMat3(rot.x); }
    if (rot.y != 0.0) { m *= RotYMat3(rot.y); }
    if (rot.z != 0.0) { m *= RotZMat3(rot.z); }
    return m;
}

Transform CompoundTransform(vec3 pos, vec3 rot, float scale)
{
    Transform t;
    t.rot = CompoundRotMat3(rot);
    t.sca = scale;
    t.pos = pos;   
    return t;
}

Transform CompoundTransform(vec3 pos, vec4 quat, float scale)
{
    Transform t;
    t.rot = QuatToMat(quat);
    t.sca = scale;
    t.pos = pos;
    
    return t;
}

Transform IdentityTransform()
{
    Transform t;
    t.rot = Identity();
    t.sca = 1.0;
    t.pos = kZero;
    return t;
}

vec2 ScreenToNormalisedScreen(vec2 p, vec2 iRes)
{   
    return (p - vec2(iRes) * 0.5) / float(iRes.y); 
}

vec3 ApplyRedGrade(vec3 inputColor) 
{
    inputColor = saturate(inputColor.zyx);
 
    // Named constants up front
    const float ZERO  = 0.0;
    const float PAD   = 0.0;  // used for padding only
    const float HALF  = 0.5;
    const float ONE   = 1.0;
    const float TWO   = 2.0;
    const float GELU_C1 = 0.7978845608;
    const float GELU_C2 = 0.044715;

   const mat4 layer0_chunk0_W0 = mat4(0.237038, 0.002839, -0.613395, 0.023955, 2.190638, 0.681709, -2.263870, -0.567830, 0.501725, 1.600221, -0.383257, 0.890942, PAD, PAD, PAD, PAD);
   const vec4 layer0_chunk0_bias = vec4(-0.287044, 0.280783, 0.290978, 0.598706);

   const mat4 layer0_chunk1_W0 = mat4(-0.137439, -0.103585, -0.010283, -1.756933, -0.938134, 1.964871, -0.696499, 1.249109, 1.416610, -0.654387, -0.856150, 1.315522, PAD, PAD, PAD, PAD);
   const vec4 layer0_chunk1_bias = vec4(-0.027628, 0.506725, 0.573981, 0.743510);

   const mat4 layer2_chunk0_W0 = mat4(3.334981, 0.692745, -2.249792, -1.533133, 0.759040, -0.884428, 0.228476, 1.654801, -1.449445, 0.674627, 1.597890, 0.084069, 1.227800, 0.103707, 2.272768, -3.488576);
   const mat4 layer2_chunk0_W1 = mat4(-3.658784, 0.920236, 2.443871, 1.958547, 1.074470, -0.660618, 1.283018, 0.921886, 1.856311, -0.596886, -2.903828, 1.161765, 0.368526, -0.286363, -0.506707, -0.171955);
   const vec4 layer2_chunk0_bias = vec4(1.218964, 0.054669, 0.264244, 0.295188);

   const mat4 layer2_chunk1_W0 = mat4(-0.191983, -0.747375, 0.912338, -1.968686, 0.272265, -0.705990, 0.595160, 1.205564, -0.024412, -0.238474, -0.449195, 0.163486, -1.953892, 1.715119, -0.194429, -2.550383);
   const mat4 layer2_chunk1_W1 = mat4(1.502533, -2.311996, -1.078473, 1.977682, -0.300410, 1.483174, 0.281399, 1.433337, -2.760890, -0.152508, -0.236289, 0.070996, 0.006024, -0.143973, 0.195464, -0.261372);
   const vec4 layer2_chunk1_bias = vec4(1.241102, 0.342907, 0.901451, 0.191256);

   const mat4 layer4_chunk0_W0 = mat4(0.208272, -0.118866, 0.661599, PAD, -1.598513, -2.092330, -0.095411, PAD, 0.630788, -0.224832, 0.052688, PAD, -3.094599, -0.439651, -0.093030, PAD);
   const mat4 layer4_chunk0_W1 = mat4(3.054257, 0.375831, -0.121975, PAD, 0.069616, 0.252565, 0.532385, PAD, -0.114408, 0.896074, -0.793594, PAD, 3.216065, 0.745465, -0.031920, PAD);
   const vec4 layer4_chunk0_bias = vec4(0.230162, -0.046474, -1.497791, PAD);

    // Scale inputColor from [0,1] to [-1,1]
    vec3 scaledColor = inputColor * TWO - ONE;

    vec4 layer0_chunk0_out = layer0_chunk0_W0 * vec4(scaledColor, ZERO) + layer0_chunk0_bias;

    vec4 layer0_chunk1_out = layer0_chunk1_W0 * vec4(scaledColor, ZERO) + layer0_chunk1_bias;

    layer0_chunk0_out = layer0_chunk0_out * (ONE + tanh(GELU_C1 * (layer0_chunk0_out + GELU_C2 * layer0_chunk0_out*layer0_chunk0_out*layer0_chunk0_out))) * HALF;
    layer0_chunk1_out = layer0_chunk1_out * (ONE + tanh(GELU_C1 * (layer0_chunk1_out + GELU_C2 * layer0_chunk1_out*layer0_chunk1_out*layer0_chunk1_out))) * HALF;

    vec4 layer2_chunk0_out = layer2_chunk0_W0 * layer0_chunk0_out + layer2_chunk0_W1 * layer0_chunk1_out + layer2_chunk0_bias;

    vec4 layer2_chunk1_out = layer2_chunk1_W0 * layer0_chunk0_out + layer2_chunk1_W1 * layer0_chunk1_out + layer2_chunk1_bias;

    layer2_chunk0_out = layer2_chunk0_out * (ONE + tanh(GELU_C1 * (layer2_chunk0_out + GELU_C2 * layer2_chunk0_out*layer2_chunk0_out*layer2_chunk0_out))) * HALF;
    layer2_chunk1_out = layer2_chunk1_out * (ONE + tanh(GELU_C1 * (layer2_chunk1_out + GELU_C2 * layer2_chunk1_out*layer2_chunk1_out*layer2_chunk1_out))) * HALF;

    vec4 layer4_chunk0_out = layer4_chunk0_W0 * layer2_chunk0_out + layer4_chunk0_W1 * layer2_chunk1_out + layer4_chunk0_bias;

    layer4_chunk0_out = ONE / (ONE + exp(-layer4_chunk0_out));

    return saturate(layer4_chunk0_out.xyz);
}

#define kDoFKernelSize (kDoFKernelRadius*2 + 1)
#define kDoFKernelArea (kDoFKernelSize * kDoFKernelSize)
#define kDoFParamsX (int(iRes.y) + 1)
#define kDoFParamsY (int(iRes.y) / 2)

#define kHFBBoxLower vec3(-0.5, -0.5, -0.5)
#define kHFBBoxUpper vec3(0.5, 0.5, 0.5)    
#define kHFRange vec2(-0., 1.)

#define kHeadPos vec3(-0.1, -0.035, -0.1)
#define kHeadScale 0.11
#define kHeadRot vec3(-0.4 + kHalfPi, kPi, 0)

#define ComposeHeadMatrix(sampler, iRes) \
    (CompoundRotMat3(kHeadRot) * \
              mat3(texelFetch(sampler, ivec2(iRes.y, 1), 0).xyz, \
                   -texelFetch(sampler, ivec2(iRes.y, 3), 0).xyz, \
                   texelFetch(sampler, ivec2(iResolution.y, 2), 0).xyz))
                   
vec3 GetHeadPos(sampler2D sampler, vec2 iRes)
{
    return vec3(kHeadPos.x,  
                mix(kHFBBoxLower.y, kHFBBoxUpper.y, texelFetch(sampler, ivec2(iRes.y, 0), 0).w) + kHeadPos.y, 
                kHeadPos.z);
}

Transform ComposeHeadTransform(sampler2D sampler, vec2 iRes)
{
    Transform t;
    t.pos = GetHeadPos(sampler, iRes);
    t.rot  = ComposeHeadMatrix(sampler, iRes);
    t.sca = kHeadScale;
    return t;
}

float CubicInterpolate(vec4 f, float t)
{    
    return f[1]                * (1. + t*t*(2.*t - 3.)) + 
           0.5 * (f[2] - f[0]) * t * (1. + t * (t -  2.)) +
           f[2]                * t*t*(3. - 2.*t) +
           0.5 * (f[3] - f[1]) * t*t*(t - 1.);
}

float CubicNoise(vec3 uvw, float scale, uint seed)
{
    uvw *= scale;
    uvec3 ijk = uvec3(ivec3(floor(uvw)) + 0xfffffff);
    vec3 d = fract(uvw);
    vec4 fu;
    for(int u = 0; u < 4; ++u)
    {
        vec4 fv;
        for(int v = 0; v < 4; ++v)
        {
            vec4 fw;
            for(int w = 0; w < 4; ++w)
            {
                fw[w] = HashOfAsFloat(uvec4(seed, uint(ijk.x) + uint(u), 
                                           uint(ijk.y) + uint(v), 
                                           uint(ijk.z) + uint(w)));
            }
            fv[v] = CubicInterpolate(fw, d.z);
        }
        fu[u] = CubicInterpolate(fv, d.y);
    }
    return CubicInterpolate(fu, d.x);
}

float SmoothNoise(float u, float scale, uint seed)
{
    u *= scale;
    uint i = uint(int(floor(u)) + 0x4ffff);
    return mix(HashOfAsFloat(uvec2(seed, i)), HashOfAsFloat(uvec2(seed, i+1u)), Smoothstep(fract(u)));
}

float SmoothNoise(vec2 uv, float scale, uint seed)
{
    uv *= scale;
    uvec2 ij = uvec2(ivec2(floor(uv)) + 0xfffffff);
    vec2 d = Smoothstep(fract(uv));
        
    return (1. - d.x) * (1. - d.y) * HashOfAsFloat(uvec3(seed, ij.x, ij.y)) +
           d.x *        (1. - d.y) * HashOfAsFloat(uvec3(seed, ij.x + 1u, ij.y)) +
           (1. - d.x) * d.y        * HashOfAsFloat(uvec3(seed, ij.x,      ij.y + 1u)) +
           d.x *        d.y        * HashOfAsFloat(uvec3(seed, ij.x + 1u, ij.y + 1u));
}

// Smoothstep noise in xy and cubic in z. Good temporal performance when time = z.
float SmoothXYCubicZNoise(vec3 uvw, float scale, uint seed)
{
    uvw = uvw * scale + 0.5;
    return CubicInterpolate(vec4(SmoothNoise(uvw.xy, 1., seed + uint(uvw.z)      + 0xffffu),
                                 SmoothNoise(uvw.xy, 1., seed + uint(uvw.z) + 1u + 0xffffu),
                                 SmoothNoise(uvw.xy, 1., seed + uint(uvw.z) + 2u + 0xffffu),
                                 SmoothNoise(uvw.xy, 1., seed + uint(uvw.z) + 3u + 0xffffu)),
                            fract(uvw.z));
}

float SmoothNoise(vec3 uvw, float scale, uint seed)
{
   uvw *= scale;
    uvec3 ij = uvec3(ivec3(floor(uvw)) + 0xfffffff);
    vec3 d;
    d.xy = Smoothstep(fract(uvw.xy));
    d.z = (fract(uvw.z));
        
  return (1. - d.x) * (1. - d.y) * (1. - d.z) *   HashOfAsFloat(uvec4(seed, ij.x,      ij.y,      ij.z)) +
           d.x *        (1. - d.y) * (1. - d.z) * HashOfAsFloat(uvec4(seed, ij.x + 1u, ij.y,      ij.z)) +
           (1. - d.x) * d.y *        (1. - d.z) * HashOfAsFloat(uvec4(seed, ij.x,      ij.y + 1u, ij.z)) +
           d.x *        d.y *        (1. - d.z) * HashOfAsFloat(uvec4(seed, ij.x + 1u, ij.y + 1u, ij.z)) + 
           (1. - d.x) * (1. - d.y) * d.z *        HashOfAsFloat(uvec4(seed, ij.x,      ij.y,      ij.z + 1u)) +
           d.x *        (1. - d.y) * d.z *        HashOfAsFloat(uvec4(seed, ij.x + 1u, ij.y,      ij.z + 1u)) +
           (1. - d.x) * d.y *        d.z *        HashOfAsFloat(uvec4(seed, ij.x,      ij.y + 1u, ij.z + 1u)) +
           d.x *        d.y *        d.z *        HashOfAsFloat(uvec4(seed, ij.x + 1u, ij.y + 1u, ij.z + 1u));     
}

float CubicNoise(vec2 uv, float scale, uint seed)
{
    uv *= scale;
    uvec2 ij = uvec2(ivec2(floor(uv)) + 0xfffffff);
    vec2 d = fract(uv);
    vec4 fu;
    for(uint u = 0u; u < 4u; ++u)
    {
        vec4 fv;
        for(uint v = 0u; v < 4u; ++v)
        {
            fv[v] = HashOfAsFloat(uvec3(seed, ij.x + u, ij.y + v));
        }
        fu[u] = CubicInterpolate(fv, d.y);
    }
    return CubicInterpolate(fu, d.x);
}

float SampleGaussian(float sigma, uvec4 seed)
{
    vec4 xi = vec4(HashOf_PCG_n_n(seed)) / vec4(0xffffffffu);
    return length(BoxMuller(xi.xy)) * sigma * (step(0.5, xi.z) * 2. - 1.);
}

float SmoothNoiseGaussian(vec2 uv, float scale, float sigma, uint seed)
{
    uv *= scale;
    uvec2 ij = uvec2(ivec2(floor(uv)) + 0xfffffff);
    vec2 d = (fract(uv));    
        
    return (1. - d.x) * (1. - d.y) * SampleGaussian(sigma, uvec4(ij.x, ij.y, seed, 9872565u)) +
           d.x *        (1. - d.y) * SampleGaussian(sigma, uvec4(ij.x + 1u, ij.y, seed, 9872565u))+
           (1. - d.x) * d.y        * SampleGaussian(sigma, uvec4(ij.x, ij.y + 1u, seed, 9872565u)) +
           d.x *        d.y        * SampleGaussian(sigma, uvec4(ij.x + 1u, ij.y + 1u, seed, 9872565u));
}

#define MLP_WIDTH 16
#define MLP_VEC_WIDTH ((MLP_WIDTH + 3) / 4)

vec4[MLP_VEC_WIDTH] PositionalEncode(vec3 p)
{
     vec4[MLP_VEC_WIDTH] encoding;
     int i = 0;
     for(int d = 0; d < 3; ++d)
     {        
         encoding[i>>2][i&3] = p[d]; ++i;
         for(int harm = 1; harm <= 2; ++harm)
         {
             encoding[i>>2][i&3] = sin(float(harm) * kTwoPi * (p[d] * 0.5 + 0.5)); ++i;
             encoding[i>>2][i&3] = cos(float(harm) * kTwoPi * (p[d] * 0.5 + 0.5)); ++i;
         }
     }
     encoding[MLP_VEC_WIDTH-1].w = 0.;
     return encoding;
}

float EvaluateSiren(vec3 p)
{
    vec4[4] A0 = PositionalEncode(p);
    vec4[4] A1;
    A1[0] = mat4(-4.766, 0.713, 0.946, 0.100, 3.612, -1.577, -2.620, 1.015, -6.073, -2.795, 2.353, -4.050, -2.959, 1.117, 0.679, 0.160) * 1e-2 * A0[0] +
    mat4(0.455, -0.507, 0.719, 0.889, -5.865, 1.043, 3.566, 1.849, -2.632, -0.546, -2.181, 1.230, 0.878, -1.971, 2.610, -0.744) * 1e-2 * A0[1] +
    mat4(0.327, -0.528, 0.634, 0.619, -0.041, -1.185, 0.361, -1.074, -8.633, 2.986, -0.024, -7.121, 1.075, -0.048, 3.264, -4.919) * 1e-2 * A0[2] +
    mat4(-1.199, -1.704, 0.654, 6.548, 2.179, -0.241, 0.169, 1.168, -0.360, -0.264, -0.490, 0.298, 1.841, 1.440, 0.490, 2.445) * 1e-2 * A0[3] +
    vec4(-29.332, 17.733, -12.319, -13.985) * 1e-2;
    A1[0] = sin(30. * A1[0]);

    A1[1] = mat4(6.536, 2.573, -3.232, 2.306, 3.121, 2.534, -2.209, 2.151, 2.043, 3.915, -1.129, 1.473, 3.373, 1.644, 0.766, 0.665) * 1e-2 * A0[0] +
    mat4(-2.226, 0.802, -0.573, -0.030, -4.924, 1.345, 0.585, 5.740, 3.388, -2.449, -4.391, 0.906, 0.914, 3.403, -5.777, 0.256) * 1e-2 * A0[1] +
    mat4(-0.977, -0.584, 0.535, -0.650, 2.531, -1.504, 2.967, -0.823, 1.775, -9.207, 2.114, -1.098, 6.805, 3.581, 0.287, 1.381) * 1e-2 * A0[2] +
    mat4(-4.565, 3.631, 6.406, 1.766, 0.832, 0.945, 0.037, 1.313, -1.011, 1.098, -0.937, -0.356, 4.883, -5.582, 5.568, 4.831) * 1e-2 * A0[3] +
    vec4(-15.449, 16.331, 14.252, 22.609) * 1e-2;
    A1[1] = sin(30. * A1[1]);

    A1[2] = mat4(2.581, 3.074, 6.718, 5.223, -1.191, 0.271, 1.501, -3.778, -0.732, 1.560, -0.863, 0.939, 1.437, 2.115, 0.095, 1.110) * 1e-2 * A0[0] +
    mat4(1.105, -1.265, -1.114, 1.455, -6.340, -3.729, -3.137, -1.596, 3.995, -1.841, 5.517, -4.127, 0.118, 3.121, -1.716, 4.119) * 1e-2 * A0[1] +
    mat4(-1.953, -0.128, -1.148, -3.163, 1.980, -1.362, -4.698, 0.359, -1.903, -1.375, -3.170, -2.652, 1.536, -2.607, 1.231, 2.344) * 1e-2 * A0[2] +
    mat4(5.568, -0.812, -3.918, -3.561, 0.777, 0.562, 0.772, -0.506, -1.407, -0.993, -0.325, 0.168, -2.089, 2.323, 1.831, -4.907) * 1e-2 * A0[3] +
    vec4(11.610, -6.323, -8.235, 6.484) * 1e-2;
    A1[2] = sin(30. * A1[2]);

    A1[3] = mat4(1.254, -1.746, -0.249, -1.414, 1.929, -1.247, -5.712, -1.138, -0.782, -0.952, 5.058, 2.314, -0.757, 0.045, 2.550, -0.227) * 1e-2 * A0[0] +
    mat4(-2.250, 0.207, -3.107, 0.047, -0.097, 2.652, 4.626, 2.093, -0.095, 0.309, 4.990, 0.802, 5.602, 0.938, 2.052, 1.420) * 1e-2 * A0[1] +
    mat4(2.174, 0.281, 5.762, 0.301, -0.430, -0.527, -1.444, 0.188, -0.169, -1.016, 0.384, 1.189, -2.902, 2.309, 4.604, -0.883) * 1e-2 * A0[2] +
    mat4(-5.514, 4.578, -4.404, 1.327, -0.341, 0.870, -1.358, -0.208, -1.131, 0.452, -2.504, 0.509, 3.007, -0.680, 3.864, -1.682) * 1e-2 * A0[3] +
    vec4(19.648, 7.701, -12.910, -10.006) * 1e-2;
    A1[3] = sin(30. * A1[3]);

    A0[0] = mat4(0.359, 0.153, -0.417, 0.183, 0.909, 1.108, -2.414, 0.610, 1.982, 0.633, -2.373, 0.492, 0.176, -0.715, 0.547, 0.874) * 1e-2 * A1[0] +
    mat4(0.680, 0.307, 0.576, -0.731, 0.460, -0.574, 0.126, 0.020, 0.507, -0.097, 0.383, -1.176, -1.581, -1.635, 1.124, -3.203) * 1e-2 * A1[1] +
    mat4(0.178, -0.199, -1.103, -0.835, -0.800, 0.293, 0.844, 2.287, 0.580, -0.338, -1.057, -0.459, -0.659, -0.162, -0.708, 0.096) * 1e-2 * A1[2] +
    mat4(-0.105, -0.418, 0.212, 2.422, 0.269, -1.559, -0.110, 1.000, -0.346, 0.239, -0.466, -0.600, 0.151, 1.716, 2.216, -0.948) * 1e-2 * A1[3] +
    vec4(-13.318, -9.551, -5.665, -25.000) * 1e-2;
    A0[0] = sin(30. * A0[0]);

    A0[1] = mat4(0.415, -0.580, 0.466, -0.322, 2.417, -2.604, -0.719, 2.997, 0.178, -0.874, 2.466, 1.221, -1.322, -0.040, 2.091, 1.223) * 1e-2 * A1[0] +
    mat4(0.032, 0.308, 0.307, -0.778, 1.255, -0.496, -0.606, 0.181, -0.347, 1.865, 2.110, 0.130, 1.322, -3.315, 3.122, -0.446) * 1e-2 * A1[1] +
    mat4(0.325, 0.174, 0.974, -0.361, 0.716, 1.398, -1.074, -0.558, 0.254, 0.632, -0.410, 0.284, -0.016, -0.001, -1.871, 1.340) * 1e-2 * A1[2] +
    mat4(-0.182, -0.227, 0.824, -0.258, 3.696, 2.416, 0.909, -1.509, -0.220, 0.315, 0.116, -0.207, 0.772, 1.065, 3.357, -3.397) * 1e-2 * A1[3] +
    vec4(0.510, 3.612, -2.929, 9.191) * 1e-2;
    A0[1] = sin(30. * A0[1]);

    A0[2] = mat4(0.321, 0.603, -0.968, 0.018, 0.353, 0.313, -0.573, 0.009, 1.877, -1.353, 2.384, -0.240, -1.389, -1.348, -2.032, 0.520) * 1e-2 * A1[0] +
    mat4(-1.580, 0.122, -0.602, -0.142, 0.226, -0.153, 0.394, -0.111, -1.696, 1.073, 0.695, 0.134, 3.649, -1.826, 2.206, -0.736) * 1e-2 * A1[1] +
    mat4(1.078, 0.490, -0.128, 0.079, -1.910, -1.051, -0.849, 0.040, 0.352, 0.408, 0.703, 0.012, -1.685, -0.396, 0.526, 0.159) * 1e-2 * A1[2] +
    mat4(1.478, 1.219, 0.405, 0.154, 0.247, 0.448, 1.114, 0.495, -0.724, 0.307, 0.079, -0.046, 2.103, 0.368, 2.514, 3.970) * 1e-2 * A1[3] +
    vec4(21.931, 8.876, -11.381, -11.263) * 1e-2;
    A0[2] = sin(30. * A0[2]);

    A0[3] = mat4(0.633, 0.091, -0.648, -0.550, 2.912, -2.293, -2.755, 1.790, 0.926, -0.039, -0.109, 1.408, 1.259, 0.373, -0.832, -0.507) * 1e-2 * A1[0] +
    mat4(0.508, 0.405, -0.456, 0.529, 0.915, -0.030, 0.351, -1.972, -0.810, 0.239, 0.385, -0.845, -0.614, -0.515, -0.507, 3.611) * 1e-2 * A1[1] +
    mat4(0.240, 0.098, -0.713, 0.658, 0.028, 0.226, -0.910, 0.149, -1.992, 0.962, -2.540, -0.364, -1.506, -0.009, 0.362, 0.089) * 1e-2 * A1[2] +
    mat4(1.269, 2.381, 0.440, 0.119, 0.630, -2.038, 1.800, 2.306, -0.465, -0.678, 0.358, -0.466, -0.852, 0.286, -2.208, 2.436) * 1e-2 * A1[3] +
    vec4(-15.502, -17.921, -2.149, -4.087) * 1e-2;
    A0[3] = sin(30. * A0[3]);

    A1[0] = mat4(-0.240, -3.519, 0.499, 1.127, -2.197, -1.178, 2.318, 4.592, -0.056, 0.606, -0.813, 0.824, -1.152, -0.952, -0.139, 0.673) * 1e-2 * A0[0] +
    mat4(-0.278, 1.243, 0.543, 1.576, 0.966, 0.908, 0.611, -0.367, 0.562, -0.649, 0.613, 1.924, -3.289, 0.924, 0.648, -2.504) * 1e-2 * A0[1] +
    mat4(0.039, 2.438, -0.240, -0.257, -1.110, 1.378, 0.905, 1.567, 0.932, 0.797, -0.306, -2.382, 3.330, 4.663, 2.518, -3.203) * 1e-2 * A0[2] +
    mat4(-1.310, 0.401, -1.083, -1.291, 0.640, -1.838, 0.844, -1.278, -0.030, 0.104, -0.014, 1.197, 1.484, 2.144, -0.469, 0.550) * 1e-2 * A0[3] +
    vec4(0.187, -18.129, 8.827, 15.138) * 1e-2;
    A1[0] = sin(30. * A1[0]);

    A1[1] = mat4(0.557, 2.291, -1.859, 1.711, 1.135, -2.897, -0.868, 0.385, 1.014, 2.061, 1.254, -1.263, 0.171, -1.846, -0.249, -0.903) * 1e-2 * A0[0] +
    mat4(-2.142, 0.034, -0.313, -3.019, 0.093, 0.378, -0.740, 1.811, 0.243, 0.234, -2.090, 0.074, 0.342, 1.480, -0.116, -0.591) * 1e-2 * A0[1] +
    mat4(-0.002, -0.248, 0.954, 1.096, 0.005, -1.352, -1.056, -2.307, 0.054, -1.439, -0.981, 0.116, 3.972, 0.163, -1.555, 1.902) * 1e-2 * A0[2] +
    mat4(-0.041, 0.653, -0.852, -0.441, 0.349, -0.545, -2.742, 0.218, 0.299, -1.672, -1.478, -0.624, -0.608, -0.511, 1.987, -2.349) * 1e-2 * A0[3] +
    vec4(-25.246, -16.591, 15.722, 6.798) * 1e-2;
    A1[1] = sin(30. * A1[1]);

    A1[2] = mat4(-0.619, 4.465, 4.789, 0.017, -0.362, 2.538, 4.485, -0.757, 0.060, -0.648, 2.287, 0.055, 0.065, -0.870, 0.953, 0.579) * 1e-2 * A0[0] +
    mat4(-0.176, -2.855, 4.103, 0.521, -1.235, -1.104, -1.268, 0.429, -0.577, -0.742, -0.296, 0.324, -2.100, 0.452, 0.719, -0.842) * 1e-2 * A0[1] +
    mat4(0.611, 1.778, -0.194, -0.126, -3.842, 2.660, -4.036, -0.926, 0.187, -1.616, -0.039, -0.022, 2.774, -4.382, 0.641, -3.555) * 1e-2 * A0[2] +
    mat4(0.548, -0.507, 0.714, -0.498, -0.034, -0.145, -1.773, 0.094, 1.203, -1.310, 0.536, 0.641, 0.792, -0.235, 2.104, -0.148) * 1e-2 * A0[3] +
    vec4(-2.538, 6.618, -3.068, -18.743) * 1e-2;
    A1[2] = sin(30. * A1[2]);

    A1[3] = mat4(3.271, 0.153, 1.127, 1.495, 2.316, 0.810, 0.489, 2.603, 1.117, 1.692, 0.733, -0.832, -0.383, 0.132, -0.385, 0.617) * 1e-2 * A0[0] +
    mat4(0.564, 0.700, -2.167, 3.121, 2.252, -0.860, -1.402, -0.670, -1.805, 0.901, -0.659, 1.207, -1.599, 3.216, -2.147, -0.825) * 1e-2 * A0[1] +
    mat4(0.220, -1.960, 0.230, -0.506, -2.151, -0.017, 0.142, -2.185, 1.808, 0.072, -0.059, 2.927, 0.288, -2.241, 0.067, 0.232) * 1e-2 * A0[2] +
    mat4(1.161, -1.826, -0.012, -0.393, -3.065, -0.726, -0.266, -1.860, -0.273, -0.582, 0.856, -0.098, -1.990, 2.184, -2.441, -0.432) * 1e-2 * A0[3] +
    vec4(-20.788, 11.637, -1.263, -8.413) * 1e-2;
    A1[3] = sin(30. * A1[3]);

    A0[0] = mat4(2.747, 1.832, -0.320, -0.207, 0.924, -0.298, -0.971, -0.784, 0.143, -0.832, 1.671, 0.654, -0.426, 1.313, 2.786, 0.911) * 1e-2 * A1[0] +
    mat4(-0.596, 1.152, 2.441, -2.438, -0.482, -0.414, -2.840, 1.896, 2.252, -0.743, -0.744, 1.235, 1.026, -1.906, -4.399, 0.309) * 1e-2 * A1[1] +
    mat4(-0.294, 0.796, 0.720, 1.460, 1.436, 0.458, -2.513, 0.372, 0.546, -0.869, 0.942, -0.276, 0.442, -1.656, -0.966, 3.741) * 1e-2 * A1[2] +
    mat4(0.640, -0.234, 1.754, 0.561, 0.675, -0.364, 0.774, 0.578, 1.049, 0.802, -2.514, 1.963, -1.439, -1.894, -0.861, 1.181) * 1e-2 * A1[3] +
    vec4(-9.693, -11.590, -2.958, 3.785) * 1e-2;
    A0[0] = sin(30. * A0[0]);

    A0[1] = mat4(-0.102, 1.500, 0.811, -1.622, -1.060, 0.475, 0.185, -2.514, -0.841, 0.852, -0.600, -2.581, 1.386, -0.742, -0.208, 0.892) * 1e-2 * A1[0] +
    mat4(-0.544, -0.969, 3.313, -1.037, 1.122, -1.244, -0.410, -3.044, -0.121, -1.113, -0.542, -0.741, -0.759, -1.530, 0.507, -1.229) * 1e-2 * A1[1] +
    mat4(-1.012, 0.158, 1.349, -0.552, 0.460, 1.595, 0.047, -0.885, -0.403, 0.025, -0.231, -0.504, -3.197, 3.378, 1.973, -1.629) * 1e-2 * A1[2] +
    mat4(0.054, 0.292, -0.484, -3.625, -0.088, -0.369, -1.262, -2.878, 0.851, -0.639, -0.696, 2.247, 0.854, 0.323, -0.217, 4.519) * 1e-2 * A1[3] +
    vec4(-18.870, -20.423, 8.474, 4.168) * 1e-2;
    A0[1] = sin(30. * A0[1]);

    A0[2] = mat4(3.459, -0.133, 0.925, 0.885, -1.317, 0.048, -0.833, -0.513, 2.859, 1.526, -2.497, -0.740, -0.602, 0.638, -0.272, -0.947) * 1e-2 * A1[0] +
    mat4(3.720, -0.772, -2.865, 1.090, 1.594, 0.597, -2.480, -2.642, 0.143, -0.255, 0.414, 0.550, -2.151, -0.334, -0.167, -0.815) * 1e-2 * A1[1] +
    mat4(2.292, -1.980, -0.216, 0.811, -0.108, 0.421, -1.919, -0.161, -0.495, -0.414, -0.250, 2.333, 1.876, 2.903, -0.683, 1.025) * 1e-2 * A1[2] +
    mat4(-0.123, -1.988, -2.183, -0.230, 2.506, -0.212, -0.108, 1.224, -1.327, 1.710, 0.182, 1.220, 2.220, 1.098, 2.151, -0.959) * 1e-2 * A1[3] +
    vec4(22.642, -8.306, 6.412, -10.559) * 1e-2;
    A0[2] = sin(30. * A0[2]);

    A0[3] = mat4(-1.101, -1.063, -1.143, 2.178, -1.383, 0.398, 0.452, 0.687, 0.114, 0.106, -0.294, -1.701, 1.605, -1.558, 0.664, 0.644) * 1e-2 * A1[0] +
    mat4(1.916, -2.077, -0.062, -1.347, -1.192, -0.335, 0.923, -1.251, -0.428, -0.480, -0.562, -0.860, 0.716, 0.615, 1.714, -1.119) * 1e-2 * A1[1] +
    mat4(2.803, -0.501, -0.393, 0.676, 0.562, 0.904, -0.656, 0.011, -0.766, -0.019, -0.161, 0.723, 1.913, 1.620, 1.008, -2.086) * 1e-2 * A1[2] +
    mat4(0.329, -0.237, 1.020, 0.564, 1.127, -0.569, -1.363, 0.974, -0.880, -0.494, -1.899, -0.434, 1.461, -0.984, -1.375, -0.032) * 1e-2 * A1[3] +
    vec4(11.368, 0.078, 20.361, 13.632) * 1e-2;
    A0[3] = sin(30. * A0[3]);

    return dot(vec4(-4.543, -3.719, 2.185, -4.767) * 1e-2, A0[0]) + 
           dot(vec4(4.649, -3.944, 6.010, 1.858) * 1e-2, A0[1]) + 
           dot(vec4(-2.605, 5.013, 2.348, -3.348) * 1e-2, A0[2]) + 
           dot(vec4(4.480, -4.839, -5.297, -5.051) * 1e-2, A0[3]) + 0.16332;
}

vec4 EvaluateSirenNormal(vec3 p)
{
    const float h = 0.001;
    const vec2 k = vec2(1,-1);
    vec4 f = vec4(EvaluateSiren( p + k.xyy*h ), EvaluateSiren( p + k.yyx*h ), EvaluateSiren( p + k.yxy*h ), EvaluateSiren( p + k.xxx*h ));
    return vec4(normalize( k.xyy* f[0] + k.yyx*f[1] + k.yxy*f[2] + k.xxx*f[3]), dot(f, vec4(0.25)) );
}

// Returns the polar distance r to the perimeter of an n-sided polygon
float Ngon(float phi, float bladePhase, float bladeCurvature, int numBlades)
{
    float piBlades = kPi / float(numBlades);
    float bladeRadius = cos(piBlades) / cos(mod(((phi + bladePhase) + piBlades) + piBlades, 2.0f*piBlades) - piBlades);
    
    // Take into account the blade curvature 
    return mix(bladeRadius, 1., bladeCurvature);
}

// Simulates a diaphgram aperture on a camera 
float EvaluateAperture(vec2 xyFrag, float kernelRadius)
{    
    vec2 p = (xyFrag - kernelRadius) / (kernelRadius + 1.);
    float d = length(p);
    d /= Ngon(atan(p.y, p.x), kApertureBladePhase, kApertureBladeCurvature, kApertureBlades) * .9;
    
    return step(d, 1.) * mix(1. - kApertureAberration, 1., pow(d, kApertureFalloff)) * kApertureGain;  
}

#if kTimeMode == 0
    #define GetTime() (kTimeOffset + kSpeed * float(iFrame) / float(kReferenceFPS))
#else
     #define GetTime() (kTimeOffset + kSpeed * iTime)
#endif

#define kReferenceResolution 1000.
#define kReferenceRatio (iResolution.y / kReferenceResolution)

// Maps signed RGB float3 to signed RGBE with 8 bits per channel 
float RGBToRGBE8(vec3 rgb)
{
    uvec3 b = floatBitsToUint(rgb);
    uvec3 m = (b & ((1u << 23) - 1u)) | (1u << 23);    
    uvec3 e = (b >> 23) & 0xffu;
    uint f = max(max(e.x, e.y), e.z);
    m = ((m >> (17u + f - e)) & 0x7fu);
    m = m + 0x7fu - (2u * m) * (b >> 31);
    return uintBitsToFloat(m[0] | (m[1] << 8) | (m[2] << 16) | (f << 24));
}

// Dithered version of the above
float RGBToRGBE8(vec3 rgb, vec3 xi)
{
    uvec3 b = floatBitsToUint(rgb);
    uvec3 m = (b & ((1u << 23) - 1u)) | (1u << 23);    
    uvec3 e = (b >> 23) & 0xffu;
    uint f = max(max(e.x, e.y), e.z);
    uvec3 shift = 17u + f - e;    
    m = ((m >> shift) & 0x7fu) + uvec3(step(xi * vec3(uvec3(1) << shift), vec3(m & ((uvec3(1u) << shift) - 1u))));
    m = m + 0x7fu - (2u * m) * (b >> 31);
    return uintBitsToFloat(m[0] | (m[1] << 8) | (m[2] << 16) | (f << 24));
}

// Maps signed 8-bit RGBE to signed RGB float3
vec3 RGBE8ToRGB(float rgbe)
{ 
    return uintBitsToFloat((1u + (floatBitsToUint(rgbe) >> 24)) << 23) * 
           (vec3(float(floatBitsToUint(rgbe) & 0xffu), 
                 float((floatBitsToUint(rgbe) >> 8) & 0xffu), 
                 float((floatBitsToUint(rgbe) >> 16) & 0xffu)) - 127.f) / 128.f;
}

float FractalDither(ivec2 xyScreen, int levels)
{    
    float sum = 0.;
    float sumWeights = 0.;
    for(int i = 0; i < levels; i++)
    {            
        float weight = 1. / float(sqr(1 + i));
        sum += weight * float(kOrderedDither[xyScreen.x & 3][xyScreen.y & 3]) / float(16);
        sumWeights += weight;
        xyScreen = (xyScreen + 2) >> 2;
    }
    return sum / sumWeights;
}

vec3 FractalColourDither(vec3 L, ivec2 xy, int quantLevels, int fractLevels)
{
    L *= float(quantLevels);
    float xi = FractalDither(xy, fractLevels);
    L += step(vec3(xi), fract(L));
    return floor(L) / float(quantLevels);
}

vec3 ColourDither(vec3 L, ivec2 xy, int quantLevels)
{
    L *= float(quantLevels);
    float xi = OrderedDither(xy);
    L += step(vec3(xi), fract(L));
    return floor(L) / float(quantLevels);
}

struct CameraCtx
{
    vec3 position;
    mat3 basis;
    float fov;    
};

CameraCtx GetCameraCtx(float time)
{
    #define kCameraLookAt vec3(0., -0.3, 0.)
    #define kCameraUp vec3(0., 1., 0)   
    #define kCameraFoV 15.
    #define kCameraWobbleSpeed 0.5
    #define kCameraWobbleAmmount 0.05

    CameraCtx ctx;
    ctx.position = vec3(cos( kHalfPi * 2.5), 0.5, sin( kHalfPi * 2.5));
    ctx.fov = mix(16., 14., cub(SmoothNoise(time, kCameraWobbleSpeed, 0x1eafb834u)));

    
    mat3 lookBasis = CreateBasis(normalize(kCameraLookAt - ctx.position));
    vec2 wobble = (vec2(SmoothNoise(time, kCameraWobbleSpeed, 0x87aab178u), SmoothNoise(time, kCameraWobbleSpeed, 0x47aab178u)) - 0.) * kCameraWobbleAmmount;         
    vec3 cameraLookAt = kCameraLookAt + lookBasis[0] * wobble.x + lookBasis[1] * wobble.y;      
    ctx.basis = CreateBasis(normalize(ctx.position - cameraLookAt), kCameraUp);
    
    return ctx;    
}

vec2 PointToCameraSpace(vec3 p, CameraCtx camera)
{
    return (camera.basis * (camera.position - p)).xy * (-1. / tan(toRad(camera.fov)));
}

float GetBlurAlpha(vec2 xyFrag, vec2 iRes, float time, sampler2D sampler)
{
    const vec2 v1 = vec2(-1, -0.3);

    #if kFocalMode == 1
        vec2 focalPoint = -PointToCameraSpace(GetHeadPos(sampler, iRes), GetCameraCtx(time));
    #else
        vec2 focalPoint = 0.25 * sin(time) * vec2(-v1.y, v1.x);
    #endif
    
    vec2 p = xyFrag / iRes.y - vec2(iRes.x / iRes.y, 1) * 0.5 + focalPoint;
    return 1. - exp(-2.5 * length2((dot(p, v1) / dot(v1, v1)) * v1 - p));
}

bool IsKeyDown(sampler2D sampler, vec2 iRes, int index)
{
    return ((floatBitsToUint(texelFetch(sampler, ivec2(iRes.y, iRes.y - 1.), 0).x) >> index) & 1u) != 0u;
}

// A Gaussian function that we use to sample the XYZ standard observer 
float CIEXYZGauss(float lambda, float alpha, float mu, float sigma1, float sigma2)
{
   return alpha * exp(sqr(lambda - mu) / (-2.0 * sqr(lambda < mu ? sigma1 : sigma2)));
}

// Schlick's approximation of the Fresnel term
float FresnelApprox(float cosI, float eta1, float eta2)
{
    cosI = 1. - cosI;
    float cosI5 = cosI*cosI;
    return mix(sqr((eta1 - eta2) / (eta1 + eta2)), 1., cosI5*cosI5 * cosI);   
}

#if kColourfulMode != 0

vec3 SampleSpectrum(float lambda)
{
	// Here we use a set of fitted Gaussian curves to approximate the CIE XYZ standard observer.
	// See https://en.wikipedia.org/wiki/CIE_1931_color_space for detals on the formula
	// This allows us to map the sampled wavelength to usable RGB values. This code needs cleaning 
	// up because we do an unnecessary normalisation steps as we map from lambda to XYZ to RGB.

	#define kRNorm (7000.0 - 3800.0) / 1143.07
	#define kGNorm (7000.0 - 3800.0) / 1068.7
	#define kBNorm (7000.0 - 3800.0) / 1068.25

	// Sample the Gaussian approximations
	vec3 xyz;
	xyz.x = (CIEXYZGauss(lambda, 1.056, 5998.0, 379.0, 310.0) +
             CIEXYZGauss(lambda, 0.362, 4420.0, 160.0, 267.0) +
             CIEXYZGauss(lambda, 0.065, 5011.0, 204.0, 262.0)) * kRNorm;
	xyz.y = (CIEXYZGauss(lambda, 0.821, 5688.0, 469.0, 405.0) +
             CIEXYZGauss(lambda, 0.286, 5309.0, 163.0, 311.0)) * kGNorm;
	xyz.z = (CIEXYZGauss(lambda, 1.217, 4370.0, 118.0, 360.0) +
             CIEXYZGauss(lambda, 0.681, 4590.0, 260.0, 138.0)) * kBNorm;

	// XYZ to RGB linear transform
	vec3 rgb;
	rgb.r = (2.04159 * xyz.x - 0.5650 * xyz.y - 0.34473 * xyz.z) / (2.0 * 0.565);
	rgb.g = (-0.96924 * xyz.x + 1.87596 * xyz.y + 0.04155 * xyz.z) / (2.0 * 0.472);
	rgb.b = (0.01344 * xyz.x - 0.11863 * xyz.y + 1.01517 * xyz.z) / (2.0 * 0.452);

	return rgb;
}

vec3 ThinFilm(in vec3 I, in vec3 n, in vec3 O, in float chi, ivec2 xyFrag)
{
    #define kFilmEta 1.5
    float kSubstrateEta = 20.0;
    float kFilmThickness = mix(1.0, 1500.0, chi);
    
    float cosThetaI = clamp(dot(n, I), -1.0, 1.0);
    float sinThetaI = sqrt(1.0 - sqr(cosThetaI));
    float sinThetaT = sinThetaI * 1.0 / kFilmEta;
    float cosThetaT = sqrt(1.0 - sqr(sinThetaT));
    
    #define kSampleBudget 10
    vec3 sumWeightedColours = kZero;

    for(int subIdx = 0; subIdx < kSampleBudget; subIdx++)
    {
        float xi = (float(subIdx) + OrderedDither(xyFrag)) / float(kSampleBudget);        
        float lambda = mix(380.0, 700.0, xi);    
        vec3 colour = SampleSpectrum(lambda * 10.);

        // Compute the distance travelled by the transmitted ray before it strikes
        // the bottom of the film
        float h = kFilmThickness / cosThetaT;

        float phase_difference = 2.0f * kPi * 2.0f * h / lambda;

        float fresnel1R = FresnelApprox(cosThetaI, 1.0, kFilmEta);
        float fresnel2R = FresnelApprox(cosThetaT, kFilmEta, kSubstrateEta);
        float fresnel3R = FresnelApprox(cosThetaT, kFilmEta, 1.0);

        float transmit = (1.0f - fresnel1R) * fresnel2R * (1.0f - fresnel3R);

        float gain = fresnel1R > transmit ?
                          (fresnel1R + transmit * cos(phase_difference)) :
                          (transmit + fresnel1R * cos(phase_difference));

        sumWeightedColours += colour * gain;
    }

    return normalize(sumWeightedColours / float(kSampleBudget));
}

#endif


