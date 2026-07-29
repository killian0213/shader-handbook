// Common (common) — Interactive fluid with caustics by tmst
// https://www.shadertoy.com/view/ttdXRf

// ================
// Generic helpers
// ================

#define PI_OVER_2 1.570796326794896
#define PI_OVER_4 0.7853981633974483

// Find t so that mix(a,b,t) = x
float unmix(float a, float b, float x) {
    return (x - a)/(b - a);
}

float isInInterval(float a, float b, float x) {
    return step(a, x) * (1.0 - step(b, x));
}

float rand(vec2 p) {
    return fract(sin(dot(p,vec2(12.9898,78.233))) * 43758.5453);
}

float lensq(vec3 v) {
    return dot(v, v);
}

float distsq(vec3 p, vec3 q) {
    vec3 pq = q - p;
    return dot(pq, pq);
}

float sdBox(vec3 boxCenter, vec3 boxRadii, vec3 p) {
    vec3 q = boxRadii - abs(p - boxCenter);
    return length(min(q, 0.0)) - max( min(min(q.x, q.y), q.z), 0.0 );
}

vec2 cpSeg2(vec2 q0, vec2 q1, vec2 p) {
    vec2 vEdge = q1 - q0;
    float t = dot(p - q0, vEdge) / dot(vEdge, vEdge);
    return q0 + clamp(t, 0.0, 1.0)*vEdge;
}

float sdSeg2(vec2 q0, vec2 q1, vec2 p) {
    vec2 x = cpSeg2(q0,q1, p);
    return distance(x, p);
}

void materialShader(
    in float diffuseCoefficient,
    in float specularCoefficient,
    in float specularExponent,
    in vec3 lightColor,
    in vec3 texColor,
    in vec3 nvNormal,
    in vec3 nvFragToLight,
    in vec3 nvFragToCam,
    out vec3 diffuseContribution,
    out vec3 specularContribution
) {
    //compute diffuse intensity
    float intensityDiffuse = clamp(dot(nvNormal, nvFragToLight), 0.0, 1.0);
    intensityDiffuse *= diffuseCoefficient;

    //compute specular intensity
    vec3 blinnH = normalize(nvFragToLight + nvFragToCam);
    float intensitySpecular = pow(clamp(dot(nvNormal, blinnH), 0.0, 1.0), specularExponent);
    intensitySpecular *= specularCoefficient;

    //output diffuse and specular values
    diffuseContribution = intensityDiffuse * texColor * lightColor;
    specularContribution = intensitySpecular * lightColor;
}

// Mouse input
//---------------------------------------
// Not a very good method but it's fine for this purpose

vec2 packUVWithBool(vec2 uv, bool b) {
    return vec2(uv.s, 0.4*uv.t + (b ? 0.5 : 0.0));
}

void unpackUVWithBool(in vec2 pack, out vec2 uv, out bool b) {
    b = pack.t > 0.45;
    uv = vec2(pack.s, 2.5*(pack.t - (b ? 0.5 : 0.0)));
}
//---------------------------------------

// ========================
// Scene helpers/constants
// ========================

#define POOL_SURFACE_WORLD_MIN vec3(-0.8, 0.0, -0.8)
#define POOL_SURFACE_WORLD_MAX vec3( 0.8, 0.0,  0.8)
#define POOL_SURFACE_CENTER (0.5*(POOL_SURFACE_WORLD_MIN+POOL_SURFACE_WORLD_MAX))
#define POOL_BUMP_HEIGHT_WORLD 0.04
#define POOL_DEPTH_WORLD 0.1

#define IR_LIQUID 1.333
#define IR_AIR 1.000

#define TAN_HALF_FOVY 0.5773502691896257
#define CAM_Z_NEAR 0.1
#define CAM_Z_FAR 50.0

mat4 getClipToWorld(vec3 iResolution, vec3 nvCamFw, vec3 nvCamFixedUp) {
    float ratio = iResolution.x / iResolution.y;
    mat4 clipToEye = mat4(
        ratio * TAN_HALF_FOVY, 0.0, 0.0, 0.0,
        0.0, TAN_HALF_FOVY, 0.0, 0.0,
        0.0, 0.0,  0.0, (CAM_Z_NEAR - CAM_Z_FAR) / (2.0 * CAM_Z_NEAR * CAM_Z_FAR),
        0.0, 0.0, -1.0, (CAM_Z_NEAR + CAM_Z_FAR) / (2.0 * CAM_Z_NEAR * CAM_Z_FAR)
    );

    vec3 nvCamRt = normalize(cross(nvCamFw, nvCamFixedUp));
    vec3 nvCamUp = cross(nvCamRt, nvCamFw);
    mat4 eyeToWorld = mat4(
         nvCamRt, 0.0,
         nvCamUp, 0.0,
        -nvCamFw, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    return eyeToWorld * clipToEye;
}

void sceneCamera(
    in vec3 iResolution,
    in vec2 fragCoord,
    in float iTime,
    out vec3 camPos,
    out vec3 nvCamDir
) {
    float t = mod(iTime, 16.0);
    float angS = smoothstep(1.,3.,t) + smoothstep(5.,7.,t) + smoothstep(9.,11.,t) + smoothstep(13.,15.,t);
    float ang = 0.2 + angS*PI_OVER_2;
    float radS = smoothstep(1.,3.,t) - smoothstep(9.,11.,t);
    float rad = mix(0.6, 0.9, radS);
    camPos = (rad+0.05*cos(iTime*0.5))*vec3(sin(ang), 0.5+0.05*sin(iTime*0.5), cos(ang));

    vec3 camTarget = vec3(0.0);
    vec3 nvCamFw = normalize(camTarget - camPos);

    vec2 uv = fragCoord / iResolution.xy;
    vec4 clip = vec4(uv * 2.0 - 1.0, 1.0, 1.0);

    vec3 nvCamFixedUp = vec3(0.0, 1.0, 0.0);
    vec4 world = getClipToWorld(iResolution, nvCamFw, nvCamFixedUp) * clip;
    nvCamDir = normalize(world.xyz / world.w);
}

vec3 sceneLight(in float iTime) {
    return vec3(6.0, 7.8, -6.0);
}

// ================================================
// Cubemap helpers (treat as 6x1024x1024 textures)
// ================================================

vec2 wrapFragCoord(vec2 fragCoord) {
    // Simulate wrap: mirror
    return abs(1023.0 - mod(fragCoord + 1023.0, 2046.0));
}

vec3 vcubeFromFragCoord(int page, vec2 fragCoord)
{
    vec2 p = (wrapFragCoord(fragCoord) + 0.5)*(2.0/1024.0) - 1.0;

    vec3 fv;
    if (page == 1) {
        fv = vec3(1.0, p);
    } else if (page == 2) {
        fv = -vec3(1.0, p);
    } else if (page == 3) {
        fv = vec3(p.x, 1.0, p.y);
    } else if (page == 4) {
        fv = -vec3(p.x, 1.0, p.y);
    } else if (page == 5) {
        fv = vec3(p, 1.0);
    } else if (page == 6) {
        fv = -vec3(p, 1.0);
    }
    return fv;
}

void fragCoordFromVCube(in vec3 vcube, out int page, out vec2 fragCoord)
{
    vec2 p;
    if (abs(vcube.x) > abs(vcube.y) && abs(vcube.x) > abs(vcube.z)) {
        if (vcube.x > 0.0) { page = 1; } else { page = 2; }
        p = vcube.yz/vcube.x;
    } else if (abs(vcube.y) > abs(vcube.z)) {
        if (vcube.y > 0.0) { page = 3; } else { page = 4; }
        p = vcube.xz/vcube.y;
    } else {
        if (vcube.z > 0.0) { page = 5; } else { page = 6; }
        p = vcube.xy/vcube.z;
    }

    fragCoord = floor((0.5 + 0.5*p)*1024.0);
}
