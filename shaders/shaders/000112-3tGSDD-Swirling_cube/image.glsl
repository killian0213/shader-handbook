// Image (image) — Swirling cube by tmst
// https://www.shadertoy.com/view/3tGSDD

#define FIXED_UP vec3(0.0, 1.0, 0.0)
#define TAN_HALF_FOVY 0.5773502691896257
#define CAM_Z_NEAR 0.1
#define CAM_Z_FAR 50.0

#define BOX_MIN vec3(-1.0)
#define BOX_MAX vec3(1.0)
#define BOX_CENTER vec3(0.0)
#define EPS 0.001

#define INV_SQRT_2 0.70710678
#define VIGNETTE_INTENSITY 0.25

// ================
// Generic helpers
// ================

float unmix(float a, float b, float x) {
    return (x - a)/(b - a);
}

mat4 getClipToWorld(float aspectWoverH, vec3 nvCamFw) {
    mat4 clipToEye = mat4(
        aspectWoverH * TAN_HALF_FOVY, 0.0, 0.0, 0.0,
        0.0, TAN_HALF_FOVY, 0.0, 0.0,
        0.0, 0.0,  0.0, (CAM_Z_NEAR - CAM_Z_FAR)/(2.0 * CAM_Z_NEAR * CAM_Z_FAR),
        0.0, 0.0, -1.0, (CAM_Z_NEAR + CAM_Z_FAR)/(2.0 * CAM_Z_NEAR * CAM_Z_FAR)
    );

    vec3 nvCamRt = normalize(cross(nvCamFw, FIXED_UP));
    vec3 nvCamUp = cross(nvCamRt, nvCamFw);
    mat4 eyeToWorld = mat4(
         nvCamRt, 0.0,
         nvCamUp, 0.0,
        -nvCamFw, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    return eyeToWorld * clipToEye;
}

// ========================
// Marching through voxels
// ========================

void boxClip(
    in vec3 boxMin, in vec3 boxMax,
    in vec3 p, in vec3 v,
    out vec2 tRange, out float didHit
){
    //for each coord, clip tRange to only contain t-values for which p+t*v is in range
    vec3 tb0 = (boxMin - p) / v;
    vec3 tb1 = (boxMax - p) / v;
    vec3 tmin = min(tb0, tb1);
    vec3 tmax = max(tb0, tb1);

    //t must be > tRange.s and each tmin, so > max of these; similar for t1
    tRange = vec2(
        max(max(tmin.x, tmin.y), tmin.z),
        min(min(tmax.x, tmax.y), tmax.z)
    );

    //determine whether ray intersects the box
    didHit = step(tRange.s, tRange.t);
}

vec3 lmnFromWorldPos(vec3 p) {
    vec3 uvw = (p - BOX_MIN) / (BOX_MAX - BOX_MIN);
    return floor(uvw * vec3(BOX_N));
}

void readLMN(vec3 lmn, out vec3 normal, out float density) {
    vec4 data = texture(iChannel0, vcubeFromLMN(1, lmn));
    normal = 2.0*(data.xyz - 0.5);
    density = clamp(unmix(0.0, 3.0, data.a), 0.0, 1.0);
}

void boxFromLMN(in vec3 lmn, out vec3 boxMin, out vec3 boxMax) {
    vec3 boxSize = (BOX_MAX - BOX_MIN) / BOX_N;

    boxMin = BOX_MIN + (floor(lmn)/BOX_N) * (BOX_MAX - BOX_MIN);
    boxMax = boxMin + boxSize;
}

void march(
    in vec3 p, in vec3 nv,
    out vec4 color
) {
    vec2 tRange;
    float didHitBox;
    boxClip(BOX_MIN, BOX_MAX, p, nv, tRange, didHitBox);

    color = vec4(0.0);
    if (didHitBox < 0.5) {
        return;
    }

    float t = tRange.s;
    for (int i=0; i<500; i++) {
        // Get voxel data
        vec3 worldPos = p + (t+EPS)*nv;
        vec3 lmn = lmnFromWorldPos(worldPos);
        
        vec3 nvNormal;
        float density;
        readLMN(lmn, nvNormal, density);

        // Determine voxel rgba color (with premultiplied alpha)
        vec3 lightPos = vec3(0.0, 10.0, 0.0);
        vec3 nvFragToLight = normalize(lightPos - worldPos);
        
        float maxLen = 0.5*distance(BOX_MIN, BOX_MAX);
        float curLen = length(BOX_CENTER - worldPos);
        
        float lamount = 1.0;
        lamount *= mix( dot(nvNormal, nvFragToLight), 1.0, 0.65);
        lamount *= smoothstep(0.1*maxLen, 0.6*maxLen, curLen);
        
        float calpha = pow(density, 3.0);
        vec3 cbase = clamp(lamount, 0.0, 1.0) * mix(0.5 + 0.5*nvNormal, vec3(1.0), 0.5);
        vec4 ci = vec4(cbase, 1.0)*calpha;

        // Determine path to next voxel
        vec3 curBoxMin, curBoxMax;
        boxFromLMN(lmn, curBoxMin, curBoxMax);

        vec2 curTRange;
        float curDidHit;
        boxClip(curBoxMin, curBoxMax, p, nv, curTRange, curDidHit);

        // Adjust alpha for distance through the voxel
        ci *= clamp((curTRange.t - curTRange.s)*15.0, 0.0, 1.0);

        // Accumulate color
        color = vec4(
            color.rgb + (1.0-color.a)*ci.rgb,
            color.a + ci.a - color.a*ci.a
        );

        // Move up to next voxel
        t = curTRange.t;
        if (t+EPS > tRange.t || color.a > 1.0) { break; }
    }
}

// ================
// Final rendering
// ================

vec3 skybox(vec3 nvDir) {
    return ( mix(0.2, 0.25, smoothstep(-0.2,0.2, nvDir.y)) )*vec3(1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    float isMousePressed = clamp(iMouse.z, 0.0, 1.0);
    vec2 mouseAng = mix(
        vec2(0.1*iTime, 0.5*3.14159 + 0.3*cos(iTime*0.5)),
        3.14159 * iMouse.xy / iResolution.xy,
        isMousePressed
    );
    
    vec3 camPos = 2.0 * (
        sin(mouseAng.y) * vec3(cos(2.0*mouseAng.x), 0.0, sin(2.0*mouseAng.x)) +
        cos(mouseAng.y) * vec3(0.0, 1.0, 0.0)
    );
    vec3 lookTarget = vec3(0.0);

	vec3 nvCamFw = normalize(lookTarget - camPos);
    mat4 clipToWorld = getClipToWorld(iResolution.x/iResolution.y, nvCamFw);

    vec4 vWorld = clipToWorld * vec4(uv*2.0 - 1.0, 1.0, 1.0);
    vec3 nvCamDir = normalize(vWorld.xyz / vWorld.w);

    vec3 bgColor = skybox(nvCamDir);

    vec4 finalColor;
    march(camPos, nvCamDir, finalColor);
    fragColor = vec4(finalColor.rgb + (1.0 - finalColor.a)*bgColor, 1.0);
    
    // Vignette
    vec2 radv = vec2(0.5, 0.5) - uv;
    float dCorner = length(radv) / INV_SQRT_2;
    float vignetteFactor = 1.0 - mix(0.0, VIGNETTE_INTENSITY, smoothstep(0.4, 0.9, dCorner));

    fragColor = vignetteFactor * fragColor;
}
