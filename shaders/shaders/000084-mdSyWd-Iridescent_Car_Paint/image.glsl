// Image (image) — Iridescent Car Paint by piyushslayer
// https://www.shadertoy.com/view/mdSyWd

/**
    A small demo illustrating an approximation of goniochromatic fresnel reflectance in 
    iridescent car paint materials based on the paper: "A Practical Extension to Microfacet 
    Theory for the Modeling of Varying Iridescence" by Laurent Belcour (Unity Technologies)
    & Pascal Barla (Inria). Drag the mouse to look around. For more details, look in Buffer B.
*/

#define TONEMAP 1
#define GAMMA_CORRECT 1
#define EXPOSURE_SCALE 0.75

const float GAMMA = 2.2;

/**----------------------------------------------------------------

        *** ACES tonemap ***
   
-------------------------------------------------------------------*/

// From: https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilmicCurve(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0f, 1.0f);
}

/**----------------------------------------------------------------

        *** Lens Flare (from shadertoy.com/view/XdfXRX) ***
   
-------------------------------------------------------------------*/

#define ORB_FLARE_COUNT	8
#define DISTORTION_BARREL 1.3

vec2 GetDistOffset(vec2 uv, vec2 pxoffset)
{
    vec2 tocenter = uv.xy;
    vec3 prep = normalize(vec3(tocenter.y, -tocenter.x, 0.0));
    
    float angle = length(tocenter.xy) * 2.221 * DISTORTION_BARREL;
    vec3 oldoffset = vec3(pxoffset, 0.);
    
    vec3 rotated = oldoffset * cos(angle) + cross(prep, oldoffset)
        * sin(angle) + prep * dot(prep, oldoffset) * (1. - cos(angle));
    
    return rotated.xy;
}

vec3 Flare(vec2 uv, vec2 pos, float dist, float size)
{
    pos = GetDistOffset(uv, pos);
    
    float r = max(0.01 - pow(length(uv + (dist - 0.05) * pos), 2.4) * (1.0 / (size * 2.0)), 0.0) * 6.0;
	float g = max(0.01 - pow(length(uv +  dist         * pos), 2.4) * (1.0 / (size * 2.0)), 0.0) * 6.0;
	float b = max(0.01 - pow(length(uv + (dist + 0.05) * pos), 2.4) * (1.0 / (size * 2.0)), 0.0) * 6.0;
    
    return vec3(r, g, b);
}

vec3 Ring(vec2 uv, vec2 pos, float dist)
{
    vec2 uvd = uv * (length(uv));
    
    float r = max(1.0 / (1.0 + 32.0 * pow(length(uvd + (dist - 0.05) * pos), 2.0)), 0.0) * 0.25;
	float g = max(1.0 / (1.0 + 32.0 * pow(length(uvd +  dist         * pos), 2.0)), 0.0) * 0.23;
	float b = max(1.0 / (1.0 + 32.0 * pow(length(uvd + (dist + 0.05) * pos), 2.0)), 0.0) * 0.21;
    
    return vec3(r, g, b);
}

vec3 LensFlare(vec2 uv, vec2 pos, float brightness, float size)
{
	
    vec3 c = Flare(uv, pos, -1.0,       size) * 3.0;
    c +=     Flare(uv, pos,  0.5, 0.8 * size) * 2.0;
    c +=     Flare(uv, pos, -0.4, 0.8 * size);
    
    c +=     Ring(uv, pos, -1.0) * 0.5 * size;
    c +=     Ring(uv, pos,  1.0) * 0.5 * size;
    
    return c * brightness;
}

vec2 GetLightPositionNDC(in vec2 fragCoord, in vec4 cachedCameraAngles)
{
    mat4 worldToViewMatrix = GetCameraWorldToView(cachedCameraAngles.zw);
                        
    vec3 lightPositionVS = (LIGHT_POSITION * worldToViewMatrix).xyz;
    vec2 lightPositionNDC = CAMERA_ZOOM * lightPositionVS.xy / lightPositionVS.z;
    lightPositionNDC = lightPositionNDC * vec2(iResolution.y / iResolution.x, 1.0);
    return lightPositionNDC;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 halfNdc = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    // Normalized camera angles in range [0.0, 1.0], xy - history, zw - current frame.
    vec4 cachedCameraAngles = texelFetch(iChannel1, ivec2(0), 0);
    
    vec3 linearColor = texelFetch(iChannel0, ivec2(fragCoord), 0).xyz;
    
    vec2 lightPositionNDC = GetLightPositionNDC(fragCoord, cachedCameraAngles);
    
    if (lightPositionNDC.y > 0.0)
    {
        linearColor += LensFlare(halfNdc * 4.0, lightPositionNDC, 0.64, 8.0);
    }
    
    fragColor = vec4(

#if GAMMA_CORRECT
    pow(
#endif

#if TONEMAP
    ACESFilmicCurve(
#endif

     linearColor
    
#if TONEMAP
    * EXPOSURE_SCALE)
#endif

#if GAMMA_CORRECT
    , vec3(1.0 / GAMMA)), 1.0);
#endif    
}