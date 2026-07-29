// Buffer B (buffer) — Iridescent Car Paint by piyushslayer
// https://www.shadertoy.com/view/mdSyWd

/**
    Scene Pass which does most of the heavylifting. The iridescent car paint is based on the paper
    "A Practical Extension to Microfacet Theory for the Modeling of Varying Iridescence" by 
    Laurent Belcour (Unity Technologies) & Pascal Barla (Inria). The logic from the original paper is 
    simplified a bit here to make it run faster but as a result it only does fresnel interference calculations
    for dielectric-dielectric interfaces. In this case even though the underlying car material is metal, 
    it still works out fairly well. 
    
    The basic idea is to add a dielectric thin-film layer of varying thickness on top of the metallic layer
    with an arbitrary roughness value, and then performing analytical spectral integration based on Airy Summation
    in fourier domain, which then is converted back to rgb resulting in a new iridescent term trplacing the usual fresnel
    term used in pbr rendering.
    
    A clearcoat layer is then also added on top of the iridescent thin-film paint layer 
    to make it look more reflective like car paints irl.
    
    Try playing with the debug flags to see different layers of rendering or try turning on the RAINBOW_VOMIT
    flag to see a more pronounced version of the iridescence car paint. Iridescence can also be switched off,
    in which case it will just render a fully carbon fiber car material. 
*/

// #define DEBUG
// #define DEBUG_SPHERE

#define IRIDESCENT_CAR 1
#if IRIDESCENT_CAR
    #define RAINBOW_VOMIT 0
#endif

#define DEBUG_MODE_ALBEDO                         0
#define DEBUG_MODE_NORMAL                         1
#define DEBUG_MODE_CLEARCOAT_NORMAL               2
#define DEBUG_MODE_DIRECT_DIFFUSE                 3
#define DEBUG_MODE_DIRECT_SPECULAR                4
#define DEBUG_MODE_CLEARCOAT_DIRECT_SPECULAR      5
#define DEBUG_MODE_DIFFUSE_AMBIENT_OCCLUSION      6
#define DEBUG_MODE_INDIRECT_DIFFUSE               7
#define DEBUG_MODE_CLEARCOAT_REFLECTION_COLOR     8
#define DEBUG_MODE_CLEARCOAT_INDIRECT_SPECULAR    9
#define DEBUG_MODE_SCENE_REFLECTION_COLOR         10
#define DEBUG_MODE_SCENE_INDIRECT_SPECULAR        11
#define DEBUG_MODE_INDIRECT_SPECULAR_COMBINED     12

#define DEBUG_MODE DEBUG_MODE_DIFFUSE_AMBIENT_OCCLUSION

#ifdef DEBUG

    bool debugValueActivated = false;
    vec3 debugValue = vec3(0.0);
    
    #define DEBUG_SET_MODE(option, value)         \
        if (option == DEBUG_MODE)                 \
        {                                         \
            debugValueActivated = true;           \
            debugValue = value;                   \
        }                                    
        
    #define DEBUG_SET_OUTPUT(option)              \
        if (debugValueActivated)                  \
        {                                         \
            option = debugValue;                  \
        }
        
#else

    #define DEBUG_SET_MODE(option, value)
    #define DEBUG_SET_OUTPUT(option)
    
#endif

#define CalculateDinc(d, eta2)         (2.0 * d * eta2)

const float LIGHT_INTENSITY          = 24.0;
const vec3  LIGHT_COLOR              = vec3(1.0, 0.91, 0.78);
const float LIGHT_SIZE               = 8.0;
const float INDIRECT_LIGHT_INTENSITY = 0.78;

/**
*  HDRI Cubemap used for generating SH coefficients: https://polyhaven.com/a/kloofendal_misty_morning_puresky
*  Tool used for generating SH Coefficients: https://github.com/google/filament/tree/main/tools/cmgen
*/
const SHCoefficients shCoeffs = SHCoefficients(
    vec3( 0.793924391269684,  0.837475955486298,  0.940771281719208), // L00, irradiance, pre-scaled base
    vec3( 0.327819824218750,  0.359646946191788,  0.423689544200897), // L1-1, irradiance, pre-scaled base
    vec3( 0.125889003276825,  0.114405624568462,  0.089422538876534), // L10, irradiance, pre-scaled base
    vec3(-0.005460172425956, -0.013677077367902, -0.021917015314102), // L11, irradiance, pre-scaled base
    vec3( 0.003116087289527, -0.000884470762685, -0.005603316240013), // L2-2, irradiance, pre-scaled base
    vec3( 0.041825212538242,  0.037392575293779,  0.028037762269378), // L2-1, irradiance, pre-scaled base
    vec3( 0.004975790623575,  0.001385384355672, -0.004225638695061), // L20, irradiance, pre-scaled base
    vec3(-0.019441796466708, -0.018265457823873, -0.017435092478991), // L21, irradiance, pre-scaled base
    vec3( 0.008399057202041, -0.004809430800378, -0.024586766958237)  // L22, irradiance, pre-scaled base
);

/**----------------------------------------------------------------

        *** Signed Distance Functions ***
   
-------------------------------------------------------------------*/

vec2 SignedDistanceUnion(in vec2 a, in vec2 b)
{
    return a.x < b.x ? a : b;
}

float SignedDistanceSmoothUnion(in float a, in float b, in float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec4 SignedDistanceSmoothUnionWithAlbedo(in vec4 a, in vec4 b, in float k)
{
    float s = SignedDistanceSmoothUnion(a.x, b.x, k);
    float sA = s - a.x;
    float sB = s - b.x;
    float r = sA / (sA + sB);
    return vec4(s, mix(b.yzw, a.yzw, r));
}

float SignedDistanceSmoothSubtraction(in float d1, in float d2, in float k)
{
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return mix(d2, -d1, h) + k * h * (1.0 - h); 
}


vec3 SignedDistanceCheapBendXY(in vec3 p, in float k)
{
    mat2  m = Rotate2D(k * p.x);
    vec3  q = vec3(m * p.xy, p.z);
    return q;
}

vec3 SignedDistanceCheapBendXZ(in vec3 p, in float k)
{
    mat2  m = Rotate2D(k * p.x);
    vec2  r = m * p.xz;
    vec3  q = vec3(r.x, p.y, r.y);
    return q;
}

vec3 SignedDistanceCheapBendZY(in vec3 p, in float k)
{
    mat2  m = Rotate2D(k * p.z);
    vec3  q = vec3(p.x, m * p.yz);
    return q;
}

// From IQ's video: https://www.youtube.com/watch?v=sl9x19EnKng&t=1892s
void RepeatRadial(inout vec3 position, in float radius, in float sectors)
{
    float angle = TWO_PI * 1.0 / sectors;
    float sector = round(atan(position.z, position.x) / angle);
    position = RotateY(-angle * sector) * position;
    position.x -= radius;
}

float SignedDistanceRoundBox(in vec3 position, in vec3 center, in vec3 bounds, in float radius)
{
  vec3 q = abs(position - center) - bounds;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - radius;
}

float SignedDistanceSphere(in vec3 position, in vec3 center, in float radius)
{
    return length(position - center) - radius;
}

float SignedDistanceEllipsoid(in vec3 position, in vec3 radius) 
{
    float k0 = length(position / radius);
    float k1 = length(position / (radius * radius));
    return k0 * (k0 - 1.0) / k1;
}

float SignedDistanceCylinder(in vec3 position, in float height, in float radius)
{
    vec2 d = abs(vec2(length(position.xz), position.y)) - vec2(radius, height);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float SignedDistancePlaneY(in vec3 position, in float height)
{
    return position.y + height;
}

float SignedDistancePlaneZ(in vec3 position, in float depth)
{
    return position.z + depth;
}

void SignedDistanceCarBody(in vec3 position, inout vec2 result)
{    
#if IRIDESCENT_CAR
    result.y = 0.0;
#else
    result.y = 1.0;
#endif
    
    // Main body
#if 1
    result.x = SignedDistanceRoundBox(RotateY(QUARTER_PI) * vec3(position.xy, SmoothAbs(position.z, 0.42, 0.06)), vec3(-0.5, 0.0, 0.5), vec3(0.2, 0.02, 0.2) + \
        /** skew */ vec3(position.y, 0.0, position.y) * 0.4, 0.6);
#else
    result.x = SignedDistanceSkewedRoundBox(rotateY(QUARTER_PI) * position, vec3(-0.5, 0.0, 0.5), vec3(position.y, 0.0, position.y), 0.4, vec3(0.2, 0.02, 0.2), 0.6);
    result.x = SignedDistanceSmoothUnion(result.x, SignedDistanceSkewedRoundBox(rotateY(QUARTER_PI) * position, vec3(0.5, 0.0, -0.5), vec3(position.y, 0.0, position.y), 0.4, \
        vec3(0.2, 0.02, 0.2), 0.6), 1.0);
#endif
   
    // Rounded front
    result.x = SignedDistanceSmoothUnion(result.x, SignedDistanceEllipsoid(position - vec3(0.0, 0.5, 1.5), vec3(0.9, 0.3, 0.6)), 0.4);
    
    // Rounded back 
    result.x = SignedDistanceSmoothUnion(result.x, SignedDistanceRoundBox(position, vec3(0.0, 0.0, -0.8), vec3(0.35, 0.5, 0.35) + /** skew */ vec3(position.y, 0.0, position.y) * 0.4, 0.2), 0.6);
    
    // Flatten the body top
    result.x = SignedDistanceSmoothSubtraction(-result.x, SignedDistancePlaneY(SignedDistanceCheapBendZY(position + vec3(0., 0., 0.6), 0.04), -0.4), 0.03);    

    vec3 tempPosition = vec3(SmoothAbs(position.x, 0.04, 0.0), position.yz);
    
    // Front headlights
#if 0
    result.x = SignedDistanceSmoothUnion(result.x, SignedDistanceEllipsoid(RotateZ(-0.6283185307) * RotateY(-0.6283185307) * (tempPosition -vec3(0.6, 0.15, 1.15)), vec3(0.15, 0.2, 0.42)), 0.225);
#else
    result.x = SignedDistanceSmoothUnion(result.x, SignedDistanceEllipsoid(RotateY(-0.6283185307) * (tempPosition - vec3(0.575, 0.15, 1.16)), vec3(0.175, 0.2, 0.45)), 0.225);
#endif
    
    // Rear engine exhausts
    result.x = SignedDistanceSmoothUnion(result.x, SignedDistanceEllipsoid(RotateX(-0.1570796326) * (tempPosition - vec3(0.45, 0.25, -0.8)), vec3(0.25, 0.3, 0.7)), 0.25);
    
    // Roof dome
    result.x = SignedDistanceSmoothUnion(result.x, SignedDistanceEllipsoid(SignedDistanceCheapBendZY(position - vec3(0.0, 0.42, 0.0), 0.25), vec3(0.6, 0.3, 0.85)), 0.4);
    
    // Cutoff dome with a skewed plane to make the back look more aerodynamic
    result.x = SignedDistanceSmoothSubtraction(-result.x, SignedDistancePlaneY(SignedDistanceCheapBendZY(position - vec3(0.0, 0.0, 0.8), 0.08), -0.725), 0.15);
    
    // Flatten underneath the body
    result.x = SignedDistanceSmoothSubtraction(-result.x, -SignedDistancePlaneY(position, 0.1), 0.1);
}

void SignedDistanceCarSpoiler(in vec3 position, inout vec2 result)
{
    // Spoiler support beams
    float distanceToSpoiler = SignedDistanceSmoothSubtraction(-SignedDistancePlaneY(RotateX(0.1570796326) * position, -0.3), 
        SignedDistanceRoundBox((RotateX(-0.6283185307) * vec3(abs(position.x), position.yz)) - vec3(0.3, 1.25, -0.95), vec3(0.0, 0.0, 0.0), vec3(0.001, 0.25, 0.05), 0.001), 0.01);
    
    // Spoiler Wing
    distanceToSpoiler = SignedDistanceSmoothUnion(distanceToSpoiler, SignedDistanceSmoothSubtraction(SignedDistancePlaneZ(SignedDistanceCheapBendXZ(position, 0.5), 1.75),
        SignedDistanceRoundBox(SignedDistanceCheapBendXY(RotateX(0.1570796326) * position, -0.125), vec3(0.0, 0.335, -1.75), vec3(0.9, 0.0, 0.2), 0.01), 0.04), 0.025);
        
    result = SignedDistanceUnion(vec2(distanceToSpoiler, 1.0), result);
}

void SignedDistanceTorii(in vec3 position, inout vec2 result)
{
    vec4 torii = vec4(0.0, 0.0, 3.0, 4.0);
    RepeatRadial(position, 6.0, 8.0);
    position = RotateY(HALF_PI) * position;
    vec3 mirrorXPosition = vec3(abs(position.x), position.yz);
    
    
    // Red Parts
    // Hashira (Pillars)
    torii.x = SignedDistanceCylinder(RotateZ(0.15) * mirrorXPosition - vec3(1.0, 0.0, 0.0), 2.5, 0.16 - mirrorXPosition.y * 0.0125);
    
    // Nuki (lower joint bar)
    torii.x = SignedDistanceSmoothUnion(torii.x, SignedDistanceRoundBox(position, vec3(0.0, 1.965, 0.0), vec3(1.06, 0.08, 0.05), 0.01), 0.02);
    
    // Kusabi (Wedges)
    torii.x = SignedDistanceSmoothUnion(torii.x, SignedDistanceSmoothSubtraction(
                                         -SignedDistanceRoundBox(mirrorXPosition - vec3(0.7, 0.0, 0.0), vec3(0.0, 2.075, 0.0), vec3(0.23, 0.03, 0.04), 0.01),
                                         -SignedDistanceCylinder(RotateX(HALF_PI) * mirrorXPosition - vec3(0.7, 0.0, -2.825), 0.25, 0.75),
                                     0.01),
                                  0.02);
    
    // Daiwa (Decorative Rings)
    torii.x = SignedDistanceSmoothUnion(torii.x, SignedDistanceCylinder(RotateZ(0.05) * (mirrorXPosition - vec3(0.64, 2.55, 0.0)), 0.02, 0.2) - 0.02, 0.01);
    
    // Gakuzuka (Supporting center strut)
    torii.x = SignedDistanceSmoothUnion(torii.x, SignedDistanceRoundBox(position, vec3(0.0, 2.25, 0.0), vec3(0.14, 0.32, 0.02), 0.01), 0.01);
    
    // Shimaki (Bent reinforcing lintel for the kasagi) 
    position = SignedDistanceCheapBendXY(position, 0.05);
    torii.x = SignedDistanceSmoothUnion(torii.x, SignedDistanceRoundBox(position, vec3(0.0, 2.645, 0.0), vec3(0.5, 0.06, -0.9) + vec3(position.y, 0.0, position.y) * 0.4, 0.01), 0.01);
    
    
    // Black parts
    // Nemaki (Pillar Sleeves)
    torii.y = SignedDistanceCylinder(RotateZ(0.15) * (mirrorXPosition - vec3(1.024, -0.1, 0.0)), 0.4, 0.18) - 0.015;
    // Kasagi (Top bent horizontal lintel)
    torii.y = SignedDistanceSmoothUnion(torii.y, SignedDistanceRoundBox(position, vec3(0.0, 2.8, 0.0), vec3(-1.75, 0.08, -0.48) + vec3(position.y * 1.25, 0.0, position.y * 0.25), 0.01), 0.01);
    
    result = SignedDistanceUnion(SignedDistanceUnion(torii.xz, torii.yw), result);
}

vec2 SignedDistanceScene(in vec3 position)
{
    vec2 result = vec2(0.0);
    
#if defined(DEBUG_SPHERE)
    result.x = SignedDistanceSphere(position, vec3(0.0, 0.65, 0.0), 0.9);
#if IRIDESCENT_CAR
    result.y = 0.0;
#else
    result.y = 1.0;
#endif
#else
    SignedDistanceCarBody(position, result);
    SignedDistanceCarSpoiler(position, result);
#endif
    SignedDistanceTorii(position, result);
    result = SignedDistanceUnion(result, vec2(SignedDistancePlaneY(position, 0.25), 2.0));

    return result;
}

vec3 CalculateNormal(vec3 position)
{
	vec2 eps = vec2(SMOL_EPS, 0.);
    return normalize(vec3(SignedDistanceScene(position + eps.xyy).x, 
                          SignedDistanceScene(position + eps.yxy).x,
                          SignedDistanceScene(position + eps.yyx).x) 
                     - SignedDistanceScene(position).x);
}

/**----------------------------------------------------------------

        *** Sphere Tracing Functions ***
   
-------------------------------------------------------------------*/

bool SphereTrace(in Ray ray, inout vec2 result)
{
    float totalMarchedDistance = 0.0;
    result = vec2(-1.0);
    vec2 currentMarched = vec2(SMOL_EPS, 0.0);
    
    for(uint i = 0u; i < 200u && totalMarchedDistance < CAMERA_FAR; ++i)
    {
        currentMarched = SignedDistanceScene(ray.origin.xyz + ray.direction.xyz * totalMarchedDistance);
        if (currentMarched.x <= totalMarchedDistance * SMOL_EPS)
        {
            result.x = totalMarchedDistance;
            result.y = currentMarched.y;
            return true;
        }
        totalMarchedDistance += currentMarched.x * 0.9;
    }
    
    result.x = CAMERA_FAR;
    return false;
}

float SoftShadowSphereTrace(in Ray ray)
{
    float totalMarched = SMOL_EPS;
    float currentMarched = 0.0;
    float shadow = 1.0;
    for(uint i = 0u; i < 100u && totalMarched < CAMERA_FAR; ++i)
    {
        currentMarched = SignedDistanceScene(ray.origin.xyz + ray.direction.xyz * totalMarched).x;
        if (currentMarched <= totalMarched * SMOL_EPS)
        {
            return 0.0;
        }
        
        shadow = min(shadow, LIGHT_SIZE * currentMarched / totalMarched);
        totalMarched += currentMarched * 0.8;
    }
    
    return shadow;
}

/**----------------------------------------------------------------

        *** Material Functions ***
   
-------------------------------------------------------------------*/

vec3 GetFogColor(in float height, in float hdrMultiplier)
{
    return mix(vec3(0.75, 0.85, 1.0), vec3(0.05, 0.125, 0.4), height) * hdrMultiplier;
}

vec4 GetFloorAlbedoWithCheckeredMask(in vec3 position)
{
    float checkerboard = mod(floor(position.x * 2.0) + floor(position.z * 2.0), 2.0); // checkered pattern
    return vec4(0.25 + checkerboard * vec3(0.25), checkerboard);
}

void SetupFloorMaterial(inout PixelContext pixel)
{
    pixel.material.albedo = GetFloorAlbedoWithCheckeredMask(pixel.hitPosition);
    pixel.material.pbrParams.x = mix(0.25, 0.95, pixel.material.albedo.w);
    pixel.material.pbrParams.y = mix(0.75, 0.05, pixel.material.albedo.w);
    pixel.material.pbrParams.z = 0.0;
}

void SetupToriiGateMaterial(inout Material material, in bool isRed)
{
    material.albedo = isRed ? vec4(0.8, 0.01, 0.01, 0.0) : vec4(vec3(0.01), 0.0);
    material.pbrParams = vec4(0.8, 0.05, 0.0, 0.0);
}

vec4 GetCarbonFiberTexture(in sampler2D texMap, in vec3 P, in vec3 N, in float sharpnessFactor)
{
    return TextureMapTriplanar(texMap, P, N, sharpnessFactor);
}

void SetupCarbonFiberMaterial(inout PixelContext pixel, in sampler2D texMap, in bool modifyNormal)
{
    pixel.material.albedo = TextureMapTriplanar(texMap, pixel.hitPosition, pixel.normal, 8.0);
    pixel.material.pbrParams.x = Saturate((pixel.material.albedo.y + 0.5) * 1.25);
    pixel.material.pbrParams.y = 0.5;
    pixel.material.pbrParams.z = 0.5;
    
    if (modifyNormal)
    {
        pixel.normal = normalize(pixel.normal - vec3(dFdx(pixel.material.albedo.w), dFdy(pixel.material.albedo.w), pixel.material.albedo.w) * vec3(0.5, 0.5, 2.5));
    }
}

vec4 GetCarPaintAlbedoWithStripeMask(in vec3 position)
{
    vec4 result;
    result.w = smoothstep(0.0725, 0.0675, abs(abs(position.x) - 0.12)); // ~0.6 width per stripe
    // result.xyz = mix(vec3(0.02, 0.125, 0.25), vec3(1.0), result.w);
    result.xyz = mix(vec3(0.1), vec3(0.2), result.w);
    return result;
}

void SetupCarPaintMaterial(inout PixelContext pixel, bool modifyNormal)
{   
#if IRIDESCENT_CAR
    pixel.material.albedo = GetCarPaintAlbedoWithStripeMask(pixel.hitPosition);
    pixel.material.pbrParams.x = mix(0.4, 0.16, pixel.material.albedo.w);
    pixel.material.pbrParams.y = 0.9;//mix(0.9, 0.3,  pixel.material.albedo.w);
    pixel.material.pbrParams.z = 0.9;
#if RAINBOW_VOMIT
    pixel.material.iridescenceParams.x = 1.39; // eta2
    pixel.material.iridescenceParams.y = 1.66; // eta3
    pixel.material.iridescenceParams.z = mix(CalculateDinc(0.5, pixel.material.iridescenceParams.x), CalculateDinc(0.65, pixel.material.iridescenceParams.x), pixel.material.albedo.w);
    pixel.material.iridescenceParams.w = 0.25; // kappa3
#else
    pixel.material.iridescenceParams.x = 1.41; // eta2
    pixel.material.iridescenceParams.y = 1.78; // eta3
    pixel.material.iridescenceParams.z = mix(CalculateDinc(mix(0.35, 0.75, pow(dot(abs(pixel.normal), vec3(1.0)) * 0.33334, 0.75)), pixel.material.iridescenceParams.x), 
                                                           CalculateDinc(0.5, pixel.material.iridescenceParams.x), pixel.material.albedo.w);
    pixel.material.iridescenceParams.w = 0.75; // kappa3
#endif
    
    if (modifyNormal)
    {
        vec3 normalOffset = sqrt(Hash33(uvec3(abs(pixel.hitPosition * min(iResolution.x, iResolution.y)))) * 0.064);
        pixel.normal = mix(pixel.normal - normalOffset, pixel.normal, pixel.material.albedo.w); // subtle flakes
        pixel.material.pbrParams.x += mix(Min3(normalOffset.x, normalOffset.y, normalOffset.z), 0.0, pixel.material.albedo.w);
        pixel.normal = normalize(pixel.normal);
    }
#endif
}

void SetupShadingMaterial(inout PixelContext pixel, in float materialID, in bool modifyNormal)
{
    if (materialID < 4.5)
    {
        SetupToriiGateMaterial(pixel.material, false);
    }
    
    if (materialID < 3.5)
    {
        SetupToriiGateMaterial(pixel.material, true);
    }
    
    if (materialID < 2.5)
    {
        SetupFloorMaterial(pixel);
    }
    
    if (materialID < 1.5
#if IRIDESCENT_CAR
    && materialID > 0.5
#endif
    )
    {
        SetupCarbonFiberMaterial(pixel, iChannel1, modifyNormal);
    }

    if (materialID < 0.5)
    {
        SetupCarPaintMaterial(pixel, modifyNormal);
    }
 
    pixel.material.pbrParams.w = materialID;
}

/**----------------------------------------------------------------

        *** BRDF Functions ***
   
-------------------------------------------------------------------*/

float NormalDistributionGGX(float linearRoughness, float NdotH)
{
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float oneMinusNdotHSquared = 1.0 - NdotH * NdotH;
    float a = NdotH * linearRoughness;
    float k = linearRoughness / (oneMinusNdotHSquared + a * a);
    float d = k * k * (1.0 / PI);
    return d;
}

float VisibilitySmithGGX(float linearRoughness, float NdotV, float NdotL) 
{
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    float a2 = linearRoughness * linearRoughness;
    float GGXV = NdotL * sqrt((NdotV - a2 * NdotV) * NdotV + a2);
    float GGXL = NdotV * sqrt((NdotL - a2 * NdotL) * NdotL + a2);
    // This also compensates for the division by the denominator of 4.0 * NoV * NoL. 
    return 0.5 / max(GGXV + GGXL, SMOL_EPS);
}

vec3 FresnelSchlickApprox(const vec3 f0, float VoH) 
{
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (vec3(1.0) - f0) * pow5(1.0 - VoH);
}

float FresnelSchlickApproxF90(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float VisibilityKelemen(float LoH) {
    // Kelemen 2001, "A Microfacet Based Coupled Specular-Matte BRDF Model with Importance Sampling"
    return Saturate(0.25 / max((LoH * LoH), SMOL_EPS));
}

void FresnelConductorExact(in float cosThetaI, in float eta, in float kappa, out vec2 R)
{
    float cosThetaI2 = Square(cosThetaI);
    float sinThetaI2 = 1.0 - cosThetaI2;
    
    float temp1 = Square(eta) - Square(kappa) - sinThetaI2;
    float a2pb2 = SafeSqrt(Square(temp1) + 4.0 * Square(kappa) * Square(eta)); // safe sqrt
    float a     = SafeSqrt(0.5f * (a2pb2 + temp1));
    
    float term1 = a2pb2 + cosThetaI2;
    float term2 = 2.0 * a * cosThetaI;
    
    R.x    = (term1 - term2) / (term1 + term2);
    
    term1  = a2pb2 * cosThetaI2 + Square(sinThetaI2);
    term2 *= sinThetaI2;
    
    R.y = R.x * (term1 - term2) / (term1 + term2);    
}

void FresnelPhaseExact(in float cosTheta, in float eta1, in float eta2, in float kappa, out vec2 phi)
{
    float A = Square(eta2) * (1.0 - Square(kappa)) - Square(eta1) * (1.0 - Square(cosTheta));
	float B = sqrt(Square(A) + Square(2.0 * Square(eta2) * kappa));
	float U = sqrt(max(0.0, (A + B) / 2.0));
	float V = sqrt(max(0.0, (B - A) / 2.0));
    
    phi.x = atan(2.0 * eta1 * V * cosTheta, Square(U) + Square(V) - Square(eta1 * cosTheta));
    phi.y = atan(2.0 * eta1 * Square(eta2) * cosTheta * (2.0 * kappa * U - (1.0 - Square(kappa)) * V),
            Square(Square(eta2) * (1.0 + Square(kappa)) * cosTheta) - Square(eta1) * (Square(U) + Square(V)));
}

// Evaluation XYZ sensitivity curves in Fourier space
vec3 EvalSensitivity(float OPD, float shift)
{
	// Use Gaussian fits, given by 3 parameters: val, pos and var
	float phase = TWO_PI * OPD * 1.0e-6;
	vec3 val = vec3(5.4856e-13, 4.4201e-13, 5.2481e-13);
	vec3 pos = vec3(1.6810e+06, 1.7953e+06, 2.2084e+06);
	vec3 var = vec3(4.3278e+09, 9.3046e+09, 6.6121e+09);
	vec3 xyz = val * sqrt(TWO_PI * var) * cos(pos * phase + shift) * exp(-var * phase*phase);
	xyz.x   += 9.7470e-14 * sqrt(TWO_PI * 4.5282e+09) * cos(2.2399e+06 * phase + shift) * exp(-4.5282e+09 * phase * phase);
	return xyz / 1.0685e-7;
}

// XYZ to CIE 1931 RGB color space (using neutral E illuminant)
const mat3 XYZ_TO_RGB = mat3(
                                2.3706743, -0.5138850,  0.0052982, 
                               -0.9000405,  1.4253036, -0.0146949,
                               -0.4706338,  0.0885814,  1.0093968
                            );

// Based on: https://stackoverflow.com/questions/8507885/shift-hue-of-an-rgb-color
vec3 RGBHueShift(in vec3 rgb, in float angle /** in degrees */)
{
    angle = abs(mod(angle, 360.0));
    if (angle < SMOL_EPS) return rgb;
    
    const float oneOver3     = 0.33333333333333333334;
    const float sqrtOneOver3 = 0.57735026918962576451;
    
    angle = ToRadian(angle); // in radians now
    
    float cosTheta = cos(angle);
    float sinTheta = sin(angle);
    
    float halfTerm1 = oneOver3 - cosTheta * oneOver3;
    float halfTerm2 = sqrtOneOver3 * sinTheta;
    
    float fullTerm1 = halfTerm1 + cosTheta;
    float fullTerm2 = halfTerm1 - halfTerm2;
    float fullTerm3 = halfTerm1 + halfTerm2;
    
    mat3 m = mat3(fullTerm1, fullTerm2, fullTerm3,
                  fullTerm3, fullTerm1, fullTerm2,
                  fullTerm2, fullTerm3, fullTerm1);
                  
    return Saturate(m * rgb);
}

// L. Belcour and P. Barla : “A Practical Extension to Microfacet Theory for the Modeling of Varying Iridescence”, 
// ACM Transactions on Graphics, 36, 4, pp. 65:1-65:14 (Jul. 2017)
// https://hal.science/hal-01518344/document
vec3 GetIridescenceFresnelTerm(in Material material, in float LoH, in float eta1)
{
    // Force eta2 -> 1.0 when Dinc -> 0.0
	float eta2  = mix(1.0, material.iridescenceParams.x, smoothstep(0.0, 0.03, material.iridescenceParams.z));
    float eta3  = material.iridescenceParams.y;
    float Dinc  = material.iridescenceParams.z;
    float kappa = material.iridescenceParams.w;
    
    vec2 R12  = vec2(0.0);
    vec2 T121 = vec2(0.0);
    vec2 R23  = vec2(0.0);
    
    float cosTheta2 = 0.0;
    
    float cosTheta1 = LoH;
    float etaRatio = eta1 / eta2; // cosTheta1 > 0.0 ? eta1 / eta2 : eta2 / eta1;
    float cosTheta2Square = 1.0 - (1.0 - Square(cosTheta1)) * Square(etaRatio); 
    
    // Check for total internal reflection
    if (cosTheta2Square <= 0.0)
    {
        R12  = vec2(1.0);
        
        // Compute the transmission coefficients
        T121 = vec2(0.0);
    }
    else
    {
        cosTheta2 = sqrt(cosTheta2Square);
        
        FresnelConductorExact(cosTheta1, eta2 / eta1, 0.0, R12);
        
        // Reflected part by the base
        FresnelConductorExact(cosTheta2, eta3 / eta2, kappa / eta2, R23);
        
        T121 = 1.0 - R12;
    }
    
    float D = Dinc * cosTheta2;
    
    vec3 I = vec3(0.0);
    
    vec2 phi21 = vec2(0.0);
    vec2 phi23 = vec2(0.0);
    
    FresnelPhaseExact(cosTheta1, eta1, eta2, 0.0, phi21);
    FresnelPhaseExact(cosTheta2, eta2, eta3, kappa, phi23);
    
    phi21 = PI - phi21;
    
    vec2 phi2 = phi21 + phi23;
    
    vec2 R123 = R12 * R23;
    vec2 r123 = sqrt(R123);
    
    vec2 Rs = (Square(T121) * R23) / (1.0 - R123);
    
    vec2 C0 = R12 + Rs;
    vec3 S0 = vec3(1.0);
    
    I += (C0.x + C0.y) * S0;
    
    vec2 Cm = Rs - T121;
    
    for (float m = 1.0; m <= 2.0; ++m)
    {
        Cm *= r123;
        
        vec3 SmS = 2.0 * EvalSensitivity(m * D, m * phi2.x);
        I += Cm.x * SmS;
        
		vec3 SmP = 2.0 * EvalSensitivity(m * D, m * phi2.y);
        I += Cm.y * SmP;
    }
    
    I *= 0.5;
    
    return RGBHueShift(Saturate(XYZ_TO_RGB * I), 315.0);
}

vec3 SHIrradiance(vec3 nrm)
{
    /**
	const SHCoefficients c = shCoeffs;
	const float c1 = 0.429043;
	const float c2 = 0.511664;
	const float c3 = 0.743125;
	const float c4 = 0.886227;
	const float c5 = 0.247708;
	return (
                c1 * c.l22 * (nrm.x * nrm.x - nrm.y * nrm.y) +
                c3 * c.l20 * nrm.z * nrm.z +
                c4 * c.l00 -
                c5 * c.l20 +
                2.0 * c1 * c.l2m2 * nrm.x * nrm.y +
                2.0 * c1 * c.l21  * nrm.x * nrm.z +
                2.0 * c1 * c.l2m1 * nrm.y * nrm.z +
                2.0 * c2 * c.l11  * nrm.x +
                2.0 * c2 * c.l1m1 * nrm.y +
                2.0 * c2 * c.l10  * nrm.z
		    );
    */
    
    /** 
         cmgen tool premultiplies the spherical harmonics constant factors and lambert diffuse term (1 / PI)
         when generating the SH coefficients, so no need to multiply here again. 
    */
    return (
                shCoeffs.l00  +
                shCoeffs.l1m1 * nrm.y                            +
                shCoeffs.l10  * nrm.z                            +
                shCoeffs.l11  * nrm.x                            +
                shCoeffs.l2m2 * nrm.x * nrm.y                    +
                shCoeffs.l2m1 * nrm.y * nrm.z                    +
                shCoeffs.l20 * (3.0 * nrm.z * nrm.z - 1.0)       + 
                shCoeffs.l21 * nrm.x * nrm.z                     +
                shCoeffs.l22 * (nrm.x * nrm.x - nrm.y * nrm.y)
    );
}

// Karis 2014, "Physically Based Material on Mobile"
// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile
vec2 EnvBRDFApproxLazarov(float roughness, float NoV)
{
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
    const vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.040);

    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

    return vec2(-1.04, 1.04) * a004 + r.zw;
}

float EnvBRDFApproxNonmetal( float Roughness, float NoV )
{
	// Same as EnvBRDFApprox( 0.04, Roughness, NoV )
	const vec2 c0 = vec2( -1.0, -0.0275 );
	const vec2 c1 = vec2( 1.0, 0.0425 );
	vec2 r = Roughness * c0 + c1;
	return min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
}

vec3 IorToF0(in float transmittedIor, in float incidentIor)
{
    return vec3(Square((transmittedIor - incidentIor) / (transmittedIor + incidentIor)));
}

vec3 F0ToIor(in vec3 f0)
{
    vec3 r = sqrt(f0);
    return (1.0 + r) / (1.0 - r);
}

void AdjustNormalAngleReflectance(inout PixelContext pixel)
{
    if (pixel.material.pbrParams.z > BIG_EPS)
    {
        //vec3 clearcoatf0 = IorToF0(F0ToIor(pixel.f0).x, 1.2);
        vec3 clearcoatf0 = Saturate(pixel.f0 * (pixel.f0 * (0.941892 - 0.263008 * pixel.f0) + 0.346479) - 0.0285998);
        pixel.f0 = mix(pixel.f0, clearcoatf0, pixel.material.pbrParams.z);
    }
    
    pixel.f0 = mix(pixel.f0, pixel.material.albedo.xyz, pixel.material.pbrParams.y);
}

vec3 GetDiffuseColor(Material material)
{
    return material.albedo.xyz * (1.0 - material.pbrParams.y);
}

float GetDiffuseLambert()
{
    return PI_INV;
}

float GetDiffuseBurley(float linearRoughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
    float lightScatter = FresnelSchlickApproxF90(1.0, f90, NoL);
    float viewScatter  = FresnelSchlickApproxF90(1.0, f90, NoV);
    return lightScatter * viewScatter * PI_INV;
}

// Lagarde and de Rousiers 2014, "Moving Frostbite to PBR"
float SpecularOcclusionLagarde(float NoV, float visibility, float roughness)
{
    return Saturate(pow(NoV + visibility, exp2(-16.0 * roughness - 1.0)) - 1.0 + visibility);
}

float CalculateAmbientOcclusion(inout PixelContext pixel)
{
    float ambientOcclusion = 0.0;
    pixel.hitPosition += pixel.clearcoatNormal * SMOL_EPS;
    
    // 4spp seemed like a good balance between minimal noise vs decent AO,
    // but feel free to increase this to suppress noise artifacts and fireflies.
    // (If your GPU is up for it that is)
    const float AO_SAMPLES = 4.0;
    const float INV_AO_SAMPLES = 1.0 / float(AO_SAMPLES);
    const float DISTANCE_FACTOR = 0.6;
    
    vec3 tangent, binormal;
    OrthonormalBasis(pixel.clearcoatNormal, tangent, binormal);
    
    // float seed = max(iResolution.x, iResolution.y) * INV_AO_SAMPLES;
    float seed = pixel.hitPosition.z * max(iResolution.x, iResolution.y) + pixel.hitPosition.x + iTime;
    
    for(float i = 0.0; i < AO_SAMPLES; ++i)
    {
        vec3 sampleDirection = RandomPointInUnitHemisphere(seed);
        //vec3 sampleDirection = RandomPointInUnitSphere(seed);
        
        sampleDirection = normalize(sampleDirection.x * tangent + sampleDirection.y * pixel.clearcoatNormal + sampleDirection.z * binormal);
        
        float totalMarched = 0.025, currentMarched;
        for (uint j = 0u; j < 8u; ++j)
        {
            currentMarched = SignedDistanceScene(pixel.hitPosition + sampleDirection * totalMarched).x; 
            totalMarched += currentMarched;
            if(abs(currentMarched) < totalMarched * EPS) break;
        }
        
        ambientOcclusion += totalMarched * DISTANCE_FACTOR; //1.0 - exp(-visibility);
    }
    
    return Saturate(ambientOcclusion * INV_AO_SAMPLES);
}

vec3 BRDF(in PixelContext pixel)
{
    vec3 result = vec3(0.0);
    
    float NoV = abs(dot(pixel.normal, pixel.viewDirection)) + 1e-5;
    float NoL = Saturate(dot(pixel.normal, pixel.lightDirection));
    float NoH = Saturate(dot(pixel.normal, pixel.halfVector));
    float LoH = Saturate(dot(pixel.lightDirection, pixel.halfVector));
    //float VoH = Saturate(dot(V, H));
    
    float clearcoatNoL = Saturate(dot(pixel.clearcoatNormal, pixel.lightDirection));
    float clearcoatNoH = Saturate(dot(pixel.clearcoatNormal, pixel.halfVector));
    float clearcoatNoV = max(SMOL_EPS, dot(pixel.clearcoatNormal, pixel.viewDirection));
    
    float linearRoughness = clamp(pixel.material.pbrParams.x * pixel.material.pbrParams.x, 1e-5, 1.0);
    float clearcoatLinearRoughness = 0.015625; //clamp(clearcoatRoughness, 0.015625 /** 0.045 */, 1.0);
    clearcoatLinearRoughness = GetFilteredRoughness(clearcoatLinearRoughness, pixel.clearcoatNormal);
    
    AdjustNormalAngleReflectance(pixel);
    
    // specular brdf
    float D = NormalDistributionGGX(linearRoughness, NoH);
    float V = VisibilitySmithGGX(linearRoughness, NoV, NoL);
    vec3  F = FresnelSchlickApprox(pixel.f0, LoH);

#if 0
#if IRIDESCENT_CAR
#if RAINBOW_VOMIT
    // Remapping CosTheta1 to [0.5, 1] range yields better results in this case. 
    if (pixel.material.pbrParams.w < 0.5) F = GetIridescenceFresnel(pixel.material, NoL, NoV, NoV * 0.5 + 0.5, 1.2);
#else
    if (pixel.material.pbrParams.w < 0.5) F = GetIridescenceFresnel(pixel.material, NoL, NoV, LoH, 1.2);
#endif
#endif
#else
#if IRIDESCENT_CAR
#if RAINBOW_VOMIT
    // Remapping CosTheta1 to [0.5, 1] range yields better results in this case. 
    if (pixel.material.pbrParams.w < 0.5) F = GetIridescenceFresnelTerm(pixel.material, NoV * 0.5 + 0.5, 1.2);
#else
    if (pixel.material.pbrParams.w < 0.5) F = GetIridescenceFresnelTerm(pixel.material, LoH, 1.2);
#endif
    if (pixel.material.pbrParams.w < 0.5) pixel.material.albedo.xyz *= F; // Preserves iridescent color.
#endif
#endif

    vec3  Fs = D * V * F;
    
    DEBUG_SET_MODE(DEBUG_MODE_DIRECT_SPECULAR, Fs);
    
    // diffuse brdf
    vec3 diffuseColor = GetDiffuseColor(pixel.material);
    vec3 Fd = diffuseColor * GetDiffuseBurley(linearRoughness, NoV, NoL, LoH);
    Fd *= (1.0 - F);

    DEBUG_SET_MODE(DEBUG_MODE_DIRECT_DIFFUSE, Fd * NoL);
    
    // clearcoat specular
    float clearCoatD = NormalDistributionGGX(clearcoatLinearRoughness, clearcoatNoH);
    float clearcoatV = VisibilityKelemen(LoH);
    vec3  clearcoatF = vec3(FresnelSchlickApproxF90(0.04, 1.0, LoH));
    
#if 0
#if IRIDESCENT_CAR
#if RAINBOW_VOMIT
    if (pixel.material.pbrParams.w < 0.5) clearcoatF = GetIridescenceFresnel(pixel.material, clearcoatNoV, 1.0);   
#else
    if (pixel.material.pbrParams.w < 0.5) clearcoatF = GetIridescenceFresnel(pixel.material, NoH, 1.0);   
#endif
#endif
#endif

    clearcoatF *= pixel.material.pbrParams.z;
    
    vec3 clearcoatFs = clearCoatD * clearcoatV * clearcoatF;
    //vec3 attenuation = 1.0 - clearcoatF;
    // attenuation *= pixel.shadow;
    
    DEBUG_SET_MODE(DEBUG_MODE_CLEARCOAT_DIRECT_SPECULAR, clearcoatFs);
    
    result  = Fd + Fs;
    result *= NoL * (1.0 - clearcoatF); // attenuation
    result += clearcoatFs * clearcoatNoL;
    result *= LIGHT_INTENSITY * LIGHT_COLOR * pixel.shadow;
    
    // indirect diffuse
    float diffuseAO = CalculateAmbientOcclusion(pixel);
    DEBUG_SET_MODE(DEBUG_MODE_DIFFUSE_AMBIENT_OCCLUSION, vec3(diffuseAO));
    
    // Notice the absence of diffuse term multiplication because cmgen already premultiplies that into the generated SH coefficients.
    vec3 indirectDiffuse = SHIrradiance(pixel.normal) * sqrt(diffuseColor) * (1.0 - clearcoatF) * diffuseAO * LIGHT_COLOR;
    DEBUG_SET_MODE(DEBUG_MODE_INDIRECT_DIFFUSE, indirectDiffuse);
    
    //result += indirectDiffuse;

#if 1
    vec2 reflectionHitResult;
    Material sceneMaterial = pixel.material;
    
    float specularAO = SpecularOcclusionLagarde(clearcoatNoV, diffuseAO, clearcoatLinearRoughness);
    
    // Default scene indirect specular to indirect diffuse for surfaces that are too rough (hacky). 
    vec3 sceneIndirectSpecular = indirectDiffuse * 0.2, clearcoatIndirectSpecular = vec3(0.0);
    vec2 envBrdfMetal = EnvBRDFApproxLazarov(sceneMaterial.pbrParams.x, NoV);
    // Energy isn't strictly conserved here, but this looks slightly better at near zero angles.
    float envBrdfNonMetal = EnvBRDFApproxNonmetal(0.015625 /**clearcoatRoughness*/, clearcoatNoV);
    envBrdfNonMetal *= sceneMaterial.pbrParams.z * specularAO;
    
    if (sceneMaterial.pbrParams.z > BIG_EPS)
    {
        clearcoatIndirectSpecular = GetFogColor(Saturate(pixel.reflectionRay.direction.y), LIGHT_INTENSITY * 0.5);
        if (SphereTrace(pixel.reflectionRay, reflectionHitResult))
        {
            // BEWARE: Reusing hitposition & material here for reflections!
            pixel.hitPosition = pixel.reflectionRay.origin + pixel.reflectionRay.direction * reflectionHitResult.x;
            SetupShadingMaterial(pixel, reflectionHitResult.y, false); 
            clearcoatIndirectSpecular = GetDiffuseColor(pixel.material) * 2.5;
        }
        
        //clearcoatIndirectSpecular *= envBrdfNonMetal * clearcoatF;
    }
    
    DEBUG_SET_MODE(DEBUG_MODE_CLEARCOAT_REFLECTION_COLOR, clearcoatIndirectSpecular);
    // Again, doesn't conserve energy completely but this (instead of just clearcoatF) looks nicer.
    // clearcoatIndirectSpecular *= envBrdfNonMetal * mix(vec3(0.1), vec3(1.0), sqrt(clearcoatF));
    clearcoatIndirectSpecular *= envBrdfNonMetal * (clearcoatF * 0.9 + 0.1);
    DEBUG_SET_MODE(DEBUG_MODE_CLEARCOAT_INDIRECT_SPECULAR, clearcoatIndirectSpecular);
    
    // Only do the expensive reflection ray march if the material roughness falls below a certain threshold. 
    if (sceneMaterial.pbrParams.x < 0.5)
    {
        float seed = pixel.hitPosition.x * iResolution.y + pixel.hitPosition.z * iResolution.x * mod(iTime, 256.0);
        vec3 randomHemisphereSample = RandomPointInUnitHemisphere(seed);
        pixel.reflectionRay.direction = normalize(pixel.reflectionRay.direction + randomHemisphereSample * linearRoughness);
        sceneIndirectSpecular = GetFogColor(Saturate(pixel.reflectionRay.direction.y), 2.0);


        if (SphereTrace(pixel.reflectionRay, reflectionHitResult))
        {
            // BEWARE: Reusing hitposition & material here for reflections!
            pixel.hitPosition = pixel.reflectionRay.origin + pixel.reflectionRay.direction * reflectionHitResult.x;
            SetupShadingMaterial(pixel, reflectionHitResult.y, false); 
            sceneIndirectSpecular = GetDiffuseColor(pixel.material);
        }

        DEBUG_SET_MODE(DEBUG_MODE_SCENE_REFLECTION_COLOR, sceneIndirectSpecular);

        sceneIndirectSpecular *= pixel.f0 * envBrdfMetal.x + envBrdfMetal.y;
        sceneIndirectSpecular *= specularAO;
        // sceneIndirectSpecular *= smoothstep(0.0, 0.9, specularAO) + 0.1; // hacky af but looks nice.
        if (sceneMaterial.pbrParams.z > BIG_EPS)
        {
            sceneIndirectSpecular *= (1.0 - clearcoatF) * (1.0 - sceneMaterial.pbrParams.z) * (1.0 - envBrdfNonMetal);
        }
    }
    
    DEBUG_SET_MODE(DEBUG_MODE_SCENE_INDIRECT_SPECULAR, sceneIndirectSpecular);
    DEBUG_SET_MODE(DEBUG_MODE_INDIRECT_SPECULAR_COMBINED, clearcoatIndirectSpecular + sceneIndirectSpecular);
    
    result += (indirectDiffuse + (clearcoatIndirectSpecular + sceneIndirectSpecular) * LIGHT_COLOR) * INDIRECT_LIGHT_INTENSITY;
#endif
    
    return result;
}

void ShadePixel(in Ray sceneRay, in vec2 hitResult, inout vec3 result)
{    
    PixelContext pixel;
    
    pixel.hitPosition = sceneRay.origin + sceneRay.direction * hitResult.x;
    pixel.viewDirection = -sceneRay.direction;
    
    pixel.clearcoatNormal = pixel.normal = CalculateNormal(pixel.hitPosition); 
    DEBUG_SET_MODE(DEBUG_MODE_NORMAL, pixel.normal * 0.5 + 0.5);
    DEBUG_SET_MODE(DEBUG_MODE_CLEARCOAT_NORMAL, pixel.clearcoatNormal * 0.5 + 0.5);
    
    pixel.lightDirection = normalize(LIGHT_POSITION.xyz - pixel.hitPosition);
    pixel.halfVector = normalize(pixel.viewDirection + pixel.lightDirection);
    
    pixel.shadow = SoftShadowSphereTrace(Ray(pixel.hitPosition + pixel.normal * SMOL_EPS, pixel.lightDirection));
    
    SetupShadingMaterial(pixel, hitResult.y, true); 
    DEBUG_SET_MODE(DEBUG_MODE_ALBEDO, pixel.material.albedo.xyz);
    
    pixel.f0 = vec3(0.04);
    
    pixel.reflectionRay = Ray(pixel.hitPosition + pixel.clearcoatNormal * SMOL_EPS, normalize(reflect(sceneRay.direction, pixel.clearcoatNormal)));
    
    // Mix shading result with fog
    result = mix(BRDF(pixel), result, Saturate(1.0 - exp(-pow(hitResult.x * 0.06, 8.0))));
}

/**----------------------------------------------------------------

        *** Main Image ***
   
-------------------------------------------------------------------*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.0);
    
    // Halton sequence generated offline within range [-0.5, 0.5]
    vec2 offset = HaltonSequence[uint(iFrame) % 16u];
    
    // Pixel coordinates [-0.5, 0.5]
    vec2 halfNdc = (fragCoord + offset - 0.5 * iResolution.xy) / iResolution.y;
    // Cached polar and azimuthal angles(normalized) for the arcball camera from the previous frame. [0.0, 1.0]
    vec4 cachedCameraAngles = texelFetch(iChannel0, ivec2(0), 0);
    cachedCameraAngles.xy = cachedCameraAngles.zw;
    // Current frame mouse position [0.0, 1.0]
    vec4 currentMouse = iMouse / iResolution.xyxy;
    // Previous frame mouse position [0.0, 1.0]
    vec4 previousMouse = texelFetch(iChannel0, ivec2(1, 0), 0);

    // Add mouse drag velocity to camera angles so it only moves from its current position
    if (currentMouse.z > 0.0 && previousMouse.z > 0.0)
    {
        cachedCameraAngles.zw += currentMouse.xy - previousMouse.xy;
        cachedCameraAngles.w = Saturate(cachedCameraAngles.w); // confine polar angle to [0.0, 1.0] domain, it becomes [0.0, PI] after de-normalization. 
    }
#if 1
    else
    {
        float cameraSpeed = iTime * 0.015;
        cachedCameraAngles.z = cameraSpeed;
        cachedCameraAngles.w = mix(0.9, 0.45, RemapTo01(sin(cameraSpeed * 3.0)));
    }
#endif

    if (iFrame == 0) // Initial camera angles (normalized).
    {
        cachedCameraAngles = vec2(0., 0.85).xyxy;
    }

    vec4 outColor = vec4(0.0);
    outColor.xyz = GetFogColor(pow(halfNdc.y * cachedCameraAngles.w + 0.5, 2.0), 2.0);
    

    Ray sceneRay = GetCameraRay(halfNdc, cachedCameraAngles.zw);
    vec2 hitResult;
    
    // Sun haze
    float sunDot = Saturate(dot(sceneRay.direction, normalize(LIGHT_POSITION.xyz)));
    outColor.xyz += pow(sunDot, 8.0) * 4.0;
    outColor.xyz += pow(sunDot, 6.0) * 3.0;
    outColor.xyz += pow(sunDot, 4.0) * 2.0;
    outColor.xyz += pow(sunDot, 3.0);

    if (SphereTrace(sceneRay, hitResult))
    {
        ShadePixel(sceneRay, hitResult, outColor.xyz);
        DEBUG_SET_OUTPUT(outColor.xyz);
    }
    
    outColor.w = hitResult.x;

    if (fragCoord.y < 1.0)
    {
        if (fragCoord.x < 3.0) outColor.xyz = iResolution;
        if (fragCoord.x < 2.0) outColor     = currentMouse;
        if (fragCoord.x < 1.0) outColor     = cachedCameraAngles;
    }

    fragColor = outColor;
}