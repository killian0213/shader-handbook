// Common (common) — Iridescent Car Paint by piyushslayer
// https://www.shadertoy.com/view/mdSyWd

/**
*  Common Stuff
*/

#define PI                            3.1415926535
#define TWO_PI                        6.2831853071
#define HALF_PI                       1.5707963267
#define QUARTER_PI                    0.7853981633
#define PI_INV                        0.3183098861
#define SMOL_EPS                      0.0005
#define EPS                           0.005
#define BIG_EPS                       0.05
#define FLT_MAX                       3.402823466e+38

#define Square(x)                     (x*x)
#define SafeSqrt(x)                   sqrt(max(0.0, x))
#define Saturate(x)                   clamp(x, 0.0, 1.0)
#define Min3(x, y, z)                 min(x, min(y, z))
#define Max3(x, y, z)                 max(x, max(y, z))
#define RemapTo01(x)                  (x * 0.5 + 0.5)
#define SmoothAbs(x, k, offset)       (sqrt(x * x + k * k) - offset)
#define ToRadian(value)               (value / 180.0 * PI)
#define sqr(x) (x*x)

#define TAA_ENABLED 1

#if TAA_ENABLED
    #define CAS_FILTER
#endif

// Camera constants
const float CAMERA_FAR            = 20.0;
const float CAMERA_RADIUS         = 5.0;
const float CAMERA_ZOOM           = tan(ToRadian(52.5)); // zoom = tan(fov * 0.5), where fov is in degrees
const vec3  CAMERA_UP             = vec3(0.0, 1.0, 0.0);
const vec3  CAMERA_TARGET         = vec3(0.0);
const vec4  LIGHT_POSITION        = vec4(-25.0, 75.0, -15.0, 1.0);

// Halton (2, 3) sequence generate offline for camera jitter.
const vec2 HaltonSequence[16u] = vec2[](
    vec2( 0.269531, -0.158436),
    vec2(-0.355469,  0.174897),
    vec2( 0.144531, -0.380658),
    vec2(-0.105469, -0.047325),
    vec2( 0.394531,  0.286008),
    vec2(-0.417969, -0.269547),
    vec2( 0.082031,  0.063786),
    vec2(-0.167969,  0.397119),
    vec2( 0.332031, -0.454733),
    vec2(-0.292969, -0.121399),
    vec2( 0.207031,  0.211934),
    vec2(-0.042969, -0.343621),
    vec2( 0.457031, -0.010288),
    vec2(-0.449219,  0.323045),
    vec2( 0.050781, -0.232510),
    vec2(-0.199219,  0.100823)
);

/**
*  Helper data structures
*/
struct Ray
{
    vec3 origin, direction;
};

struct Material
{
    // alpha channel - unused
    vec4 albedo;
    /**
        red channel - roughness
        green channel - metalness
        blue channel - clearcoat
        alpha channel - material ID
    */
    vec4 pbrParams;
    vec4 iridescenceParams;
};

struct PixelContext
{
    vec3 hitPosition;
    float shadow;
    vec3 normal;
    vec3 clearcoatNormal;
    vec3 lightDirection;
    vec3 viewDirection;
    vec3 halfVector;
    vec3 f0;
    
    Ray reflectionRay;
    
    Material material;
};

struct SHCoefficients
{
	vec3 l00, l1m1, l10, l11, l2m2, l2m1, l20, l21, l22;
};

/**
*  Helper Utility Functions
*/

float pow5(const float x) 
{
    float x2 = x * x;
    return x2 * x2 * x;
}

mat2 Rotate2D(float theta)
{
    float s = sin(theta);
    float c = cos(theta);
    return mat2(c, -s, s, c);
}

mat3 RotateX(float theta) 
{
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s,  c)
    );
}

mat3 RotateY(float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3( c, 0, s),
        vec3( 0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 RotateZ(float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s,  c, 0),
        vec3(0,  0, 1)
    );
}

/**
*  Quality hashes collection by nimitz https://www.shadertoy.com/view/Xt3cDn
*/
uint BaseHash1D(uint p)
{
    p = 1103515245U*((p >> 1U)^(p));
    uint h32 = 1103515245U*((p)^(p>>3U));
    return h32^(h32 >> 16);
}

vec2 Hash21(in uint x)
{
    uint n = BaseHash1D(x);
    uvec2 rz = uvec2(n, n*48271U); //see: http://random.mat.sbg.ac.at/results/karl/server/node4.html
    return vec2((rz.xy >> 1) & uvec2(0x7fffffffU))/float(0x7fffffff);
}

uint BaseHash2D(uvec2 p)
{
    p = 1103515245U*((p >> 1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    return h32^(h32 >> 16);
}

float Hash12(uvec2 x)
{
    uint n = BaseHash2D(x);
    return float(n)*(1.0/float(0xffffffffU));
}

vec3 Hash13(inout float seed) {
    uint n = BaseHash2D(floatBitsToUint(vec2(seed += 0.1, seed += 0.1)));
    uvec3 rz = uvec3(n, n * 16807U, n * 48271U);
    return vec3(rz & uvec3(0x7fffffffU)) / float(0x7fffffff);
}

uint BaseHash3D(uvec3 p)
{
    p = 1103515245U*((p.xyz >> 1U)^(p.yzx));
    uint h32 = 1103515245U*((p.x^p.z)^(p.y>>3U));
    return h32^(h32 >> 16);
}

vec3 Hash33(uvec3 x)
{
    uint n = BaseHash3D(x);
    uvec3 rz = uvec3(n, n*16807U, n*48271U); //see: http://random.mat.sbg.ac.at/results/karl/server/node4.html
    return vec3((rz >> 1) & uvec3(0x7fffffffU))/float(0x7fffffff);
}

/**
*  Source: Karthik Karanth's blog: 
*  https://karthikkaranth.me/blog/generating-random-points-in-a-sphere/#better-choice-of-spherical-coordinates
*/
vec3 RandomPointInUnitSphere(inout float seed) {
    vec3 h = Hash13(seed) * vec3(TWO_PI, 2.0, 1.0) - vec3(0.0, 1.0, 0.0);
    float theta = h.x;
    float sinPhi = sqrt(1.0 - h.y * h.y);
    float r = pow(h.z, 0.3333333334);
    
    return r * vec3(cos(theta) * sinPhi, sin(theta) * sinPhi, h.y);
}

vec3 RandomPointInUnitHemisphere(inout float seed) {
    vec3 h = Hash13(seed) * vec3(TWO_PI, 1.0, 1.0);// - vec3(0.0, 1.0, 0.0);
    float theta = h.x;
    float sinPhi = sqrt(1.0 - h.y * h.y);
    float r = pow(h.z, 0.3333333334);
    
    return r * vec3(cos(theta) * sinPhi, h.y, sin(theta) * sinPhi);
}

/**
*  Camera Matrix Orientation: 
*
*
*             Up
*   -lookAt    ^
*       ↖      |
*         ↖    |
*           ↖  |
*             ↖.------> Right
*/
mat3 GetCameraBasis(in vec3 origin, in vec3 target)
{
    vec3 lookAt = normalize(origin - target); // Towards camera
    vec3 right = normalize(cross(CAMERA_UP, lookAt)); 
    vec3 up = normalize(cross(lookAt, right));
    return mat3(right, up, -lookAt);
}

vec3 GetCameraPosition(in vec2 cameraAngles)
{
    // Make the camera arcball-ish using spherical coordinates
    vec2 theta = vec2(cameraAngles.x * PI * 4.0, mix(PI * 0.1, PI * 0.499, cameraAngles.y));

    return vec3(
        sin(theta.x) * sin(theta.y),
        cos(theta.y),
        cos(theta.x) * sin(theta.y)
    ) * CAMERA_RADIUS;
}

mat4 GetCameraWorldToView(in vec2 cameraAngles)
{
    vec3 camPosition = GetCameraPosition(cameraAngles);
    
    mat4 result = mat4(GetCameraBasis(camPosition, CAMERA_TARGET));
    result[0].w = -dot(result[0].xyz, camPosition);
    result[1].w = -dot(result[1].xyz, camPosition);
    result[2].w = -dot(result[2].xyz, camPosition);
    result[3] = vec4(0.0, 0.0, 0.0, 1.0);
    
    return result;
}

Ray GetCameraRay(in vec2 pixelCoord, in vec2 cameraAngles)
{
    // Generate camera ray through a camera view matrix
    vec3 origin = GetCameraPosition(cameraAngles);
    mat3 cameraWorld = GetCameraBasis(origin, CAMERA_TARGET);
    vec3 direction = normalize(cameraWorld * vec3(pixelCoord, CAMERA_ZOOM));
    return Ray(origin, direction);
}

/**
*  Box Mapping by iq - https://www.shadertoy.com/view/MtsGWH
*/
vec4 TextureMapTriplanar(in sampler2D texMap, in vec3 position, in vec3 normal, in float sharpnessFactor)
{
    // project + fetch
	vec4 x = textureLod(texMap, position.yz, 0.0);
	vec4 y = textureLod(texMap, position.zx, 0.0);
	vec4 z = textureLod(texMap, position.xy, 0.0);
    
    // blend the maps along the 3 orthogonal axes
    vec3 m = pow(abs(normal), vec3(sharpnessFactor));
	return (x * m.x + y * m.y + z * m.z) / (m.x + m.y + m.z);
}

/**
*  Yusuke Tokuyoshi and Anton S. Kaplanyan. 2019. Improved Geometric Specular Antialiasing.
*  https://www.jp.square-enix.com/tech/library/pdf/ImprovedGeometricSpecularAA.pdf
*/
float GetFilteredRoughness(float roughness, vec3 normal)
{
    float linearRoughness = roughness * roughness;
    
    vec3 ddu = dFdx(normal);
    vec3 ddv = dFdy(normal);

    float variance = 0.16 * (dot(ddu, ddu) + dot(ddv, ddv)); // sigma = 0.4

    float kernelRoughness = min(2.0 * variance, 0.18); // kappa = 0.18
    float squareRoughness = Saturate(linearRoughness * linearRoughness + kernelRoughness);

    return sqrt(squareRoughness);
}

/**
*  Tom Duff, James Burgess, Per Christensen, Christophe Hery, Andrew Kensler, Max Liani, and Ryusuke Villemin, Building an Orthonormal Basis, Revisited
*  https://graphics.pixar.com/library/OrthonormalB/paper.pdf
*/
void OrthonormalBasis(in vec3 n, out vec3 b1, out vec3 b2) 
{ 
    float signum = float(n.z > SMOL_EPS) * 2.0 - 1.0;
    float a = -1.0 / (signum + n.z);
    float b = n.x * n.y * a;
    b1 = vec3(1.0 + signum * n.x * n.x * a, signum * b, -signum * n.x);
    b2 = vec3(b, signum + n.y * n.y * a, -n.y);
}