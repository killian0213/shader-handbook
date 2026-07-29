// Image (image) — The Other Great Chrome Donut by elenzil
// https://www.shadertoy.com/view/stlyRr

#define RES     (iResolution)
#define MINRES  (min(RES.x, RES.y))
#define ZERO    (min(iFrame,0))


const float PI       = 3.14159265359;
const float gMaxTime = 3e3;   // numerical precision gets bad above this

const vec3 gV0  = vec3(0.0);
const vec3 gV1  = vec3(1.0);
const vec3 gV1n = normalize(gV1);
const vec3 gVx  = vec3(1.0, 0.0, 0.0);
const vec3 gVy  = vec3(0.0, 1.0, 0.0);
const vec3 gVz  = vec3(0.0, 0.0, 1.0);

vec3 sky(vec3 dir);

// general math
mat2 rot2(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, s, -s, c);
}

float square(float a) { return a * a; }
float selfDot(vec2 a) { return dot(a, a); }
float selfDot(vec3 a) { return dot(a, a); }

// author: Neil Mendoza   license: unknown    link: https://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis
//mat4 rotationMatrix(vec3 axis, float angle) {     axis = normalize(axis);     float s = sin(angle);     float c = cos(angle);     float oc = 1.0 - c;          return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,                0.0,                                0.0,                                0.0,                                1.0); 


// author: blackle mori   license: unknown    link: https://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis
vec3 rotateAxis(vec3 p, vec3 axis, float angle) {
return mix(dot(axis, p)*axis, p, cos(angle)) + cross(axis,p)*sin(angle);
}

// SDF manipulators
float opU(float a, float b) {
    return min(a, b);
}
float opS(float a, float b) {
    return -min(-a, b);
}

// SDF primitives

float sdPlaneY(vec3 p) {
    return p.y;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}



// License: Unknown, author: Martijn Steinrucken, found: https://www.youtube.com/watch?v=VmrIDyYiJBA
vec2 hextile(inout vec2 p) {
  // See Art of Code: Hexagonal Tiling Explained!
  // https://www.youtube.com/watch?v=VmrIDyYiJBA
  const vec2 sz       = vec2(1.0, sqrt(3.0));
  const vec2 hsz      = 0.5*sz;

  vec2 p1 = mod(p, sz)-hsz;
  vec2 p2 = mod(p - hsz, sz)-hsz;
  vec2 p3 = dot(p1, p1) < dot(p2, p2) ? p1 : p2;
  vec2 n = ((p3 - p + hsz)/sz);
  p = p3;

  n -= vec2(0.5);
  // Rounding to make hextile 0,0 well behaved
  return round(n*2.0)*0.5;
}

// author: sam hocevar, license: WTFPL, link: https://stackoverflow.com/a/17897228
vec3 rgb2hsv(vec3 c) {   vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);     vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));     vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));     float d = q.x - min(q.w, q.y);     float e = 1.0e-10;     return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x); }
vec3 hsv2rgb(vec3 c) {   vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);     vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);     return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y); }


// Hash without Sine
// MIT License...
// Copyright (c)2014 David Hoskins. https://www.shadertoy.com/view/4djSRW
//  1 out, 2 in...
//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
///  2 out, 3 in...
vec2 hash23(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
//  3 out, 1 in...
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}






//--------------------------------------------------------------------------------
// @Gijs
// https://www.shadertoy.com/view/7dSSzy Basic : Less Simple Atmosphere

vec3  SUN_COLOR = vec3(1.0,1.0,1.0);
vec3  SKY_SCATTERING = vec3(0.1, 0.3, 0.7);
// vec3  SUN_VECTOR;
float SUN_ANGULAR_DIAMETER = 0.08;
float CAMERA_HEIGHT = -0.3;


// Consider an atmosphere of constant density & isotropic scattering 
// Occupying, in the y axis, from -infty to 0
// This shaders ``solves'' that atmosphere analytically.

float atmosphereDepth(vec3 pos, vec3 dir)
{
    return max(-pos.y, 0.0)/ max(dir.y, 0.0);
}

vec3 transmittance(float l)
{
    return exp(-l * SKY_SCATTERING);
}

vec3 simple_sun(vec3 dir, vec3 lightDir)
{
    //sometimes |dot(dir, SUN_VECTOR)| > 1 by a very small amount, this breaks acos
    float a = acos(clamp(dot(dir, lightDir),-1.0,1.0));
    float t = 0.005;
    float e = smoothstep(SUN_ANGULAR_DIAMETER*0.5 + t, SUN_ANGULAR_DIAMETER*0.5, a);
    return SUN_COLOR * e;
}

vec3 simple_sky(vec3 p, vec3 d, vec3 lightDir)
{
    float l = atmosphereDepth(p, d);
    vec3 sun = simple_sun(d, lightDir) * transmittance(l);
    float f = 1.0 - d.y / lightDir.y;
    float l2 = atmosphereDepth(p, lightDir);
    vec3 sk = simple_sun(lightDir, lightDir) * transmittance(l2) / f * (1.0 - transmittance(f*l));
    return clamp(sun + sk, 0.0, 1.0);
}

//---------------------------------------------------------
float Pow2(float x) { return x * x; }
// PaniniProjection from TinyTexel
// https://www.shadertoy.com/user/TinyTexel
// https://www.shadertoy.com/view/Wt3fzB
// tc ∈ [-1,1]² | fov ∈ [0, π) | d ∈ [0,1]
vec3 PaniniProjection(vec2 tc, float fov, float d)
{
    float d2 = d*d;

    {
        float fo = PI / 2.0 - fov * 0.5;

        float f = cos(fo)/sin(fo) * 2.0;
        float f2 = f*f;

        float b = (sqrt(max(0.0, Pow2(d+d2)*(f2+f2*f2))) - (d*f+f)) / (d2+d2*f2-1.0);

        tc *= b;
    }
    
    /* http://tksharpless.net/vedutismo/Pannini/panini.pdf */
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



vec3 getCamRayDir(vec3 camDir, vec2 uv, float zoom) {

    vec3 camFw  = normalize(camDir);
    vec3 camRt  = normalize(cross(camFw, gVy));
    vec3 camUp  = cross(camRt, camFw);    
    mat3 camMat = mat3(camRt, camUp, camFw);
    
    uv /= zoom;
    
    float paniniFOV = 0.35 * PI;
    float paniniD   = 0.1;
    vec3  rayDirCam = PaniniProjection(uv, paniniFOV, paniniD);
    
    return normalize(camMat * rayDirCam);
}







//-----------------------------------------------------------






const int   gMarchMaxSteps      = 150;
const float gMarchUnderStep     = 0.98;  // slight understepping to allow for convexity of floor tiles
const float gMarchHorizon       = 100.0;
const float gMarchHorizonSq     = gMarchHorizon * gMarchHorizon;
const float gMarchEps           = 0.001;
const float gNormEps            = gMarchEps;

// for development: bigger pixels = clearer problems
const float gDownRes            = 1.0;


const uint  gMaximumRaysInQueue = 20u;

// the maximum total number of calls to Map().
const float gMaxTotalMapIters   = float(gMarchMaxSteps) * 10.0;

// the least significant ray which will be processed
const float gMinRayContribution = 0.001;
const float gMinRayContribSq    = gMinRayContribution * gMinRayContribution;



float gSSZoom;
float gSSEps;
float gT;
float gTotalMapIters = 0.0;

// distance from camera to center of scene
float gCamDist     = 20.0;
vec3  gSceneCenter = gVy * 3.0;
vec3  gLightDir;
vec2  gTorusDims;
vec3  gTorusPos;
float gBallRad;
float gBallOrbit;
vec3  gBallPos;
float gBallTime;
float gBallInset;
float gBallCycle;
float gBallCycleHash;
float gHexTileFac = 0.67;


vec2 gMouse;    // 0 to RES
vec2 gSSMouse;  // 0 to 1

struct ray_t {
    vec3 ro;
    vec3 rd;
    bool internal;
    bool shadow;
    vec3 contribution;
};

struct marchResult_t {
    float t;
    uint  m;
};


// "diffuse"  includes regular diffuse plus ambient
// "specular" includes reflection and transmission
struct material_t {
    vec3 c1;
    vec3 c2;
    
    // 0 = all diffuse, 1 = all specular
    float diffuseVsSpecular1;
    float diffuseVsSpecular2;
    
    // 0 = all reflection, 1 = all transmission
    // scoped to 'specular'
    float reflectionVsTransmission;
    
    // Lambert's linear attenuation coefficient
    float attenuationCoefficient;    
};

const uint kMSky   = 0u;
const uint kMFloor = 1u;
const uint kMTorus = 2u;
const uint kMBall  = 3u;


// scoped to 'diffuse'.
vec3 gAmbientLight;
vec3 gDirectionalLight;


material_t[] kMaterials = material_t[] (
    // sky
    material_t (
        1.0 * vec3(0.1, 0.2, 1.0),
        1.0 * vec3(0.3, 0.05, 0.1),
        0.0, 0.0,        // directional -> specular  1 & 2
        0.0,             // reflection  -> transmission
        0.0              // linear attenuation
    ),
    
    // floor
    material_t (
        gV1 * 0.1,
        vec3(0.5, 0.8, 0.1) * 0.3,
        0.2, 0.7,        // directional -> specular  1 & 2
        0.0,             // reflection  -> transmission
        0.0              // linear attenuation
    ),
    
    // torus
    material_t (
        gV1 * 0.2,
        gV0,
        0.8, 0.0,        // directional -> specular  1 & 2
        0.0,             // reflection  -> transmission
        0.0              // linear attenuation
    ),
    
    // ball
    material_t (
        gV1,
        gV0,
        0.2, 0.0,        // directional -> specular  1 & 2
        0.0,             // reflection  -> transmission
        0.0              // linear attenuation
    )
);

void configMaterials() {
    float ambientLightAmt = 0.04;
    float directionalLightAmt = 1.0 - ambientLightAmt;
    
    gAmbientLight     = ambientLightAmt * sky(gV1n);
    gDirectionalLight = clamp(directionalLightAmt * sky(-gLightDir) * 3.0, 0.0, 1.0);

    if (gBallCycleHash != 0.0) {
        kMaterials[kMBall].diffuseVsSpecular1 = gBallCycleHash * gBallCycleHash;
    }
}


// queue of ray_t's. ------------------------------
#define QTYPE ray_t
const uint gQCapacity = gMaximumRaysInQueue;
const uint gQNumSlots = gQCapacity + 1u; QTYPE gQ[gQNumSlots]; uint gQHead = 0u; uint gQTail = 0u;
uint QCount    ()           { if (gQHead >= gQTail) {return gQHead - gQTail;} else { return gQNumSlots - (gQTail - gQHead); } }
uint QSpaceLeft()           { return gQCapacity - QCount(); }
bool QIsFull   ()           { return QSpaceLeft() == 0u;}
bool QIsEmpty  ()           { return QCount() == 0u; }
void QEnqueue  (QTYPE item) { gQHead = (gQHead + 1u) % gQNumSlots; gQ[gQHead] = item; }
QTYPE QDequeue ()           { gQTail = (gQTail + 1u) % gQNumSlots; return gQ[gQTail]; }
//-------------------------------------------------

float stretchRange(float t, vec2 gap, float fac) {
    float range = gap[1] - gap[0];
    float f     = (t - gap[0]) / range;

    if (f < 0.0) {
        return t;
    }
    else if (f > 1.0) {
        return t + range * (fac - 1.0);
    }
    else {
        return mix(gap[0], gap[1], f * fac);
    }
}

void configGlobals1() {
    gT       = mod(iTime, gMaxTime);
    gT       = stretchRange(gT, vec2(90.6, 97.0), 0.2);
    
    gSSZoom  = 1.3;
    gSSEps   = 4.0 / MINRES / gSSZoom;
    
    gMouse   = length(iMouse.xy) < 50.0 ? (vec2(sin(gT * 0.107), -cos(gT * 0.1)) * 0.5 + 0.5) * RES.xy : iMouse.xy;
    gSSMouse = gMouse/RES.xy;
    
    gLightDir     = normalize(-gVy + gVz * 0.4);
    float sunTime = gT * 0.017 - 0.3;
    gLightDir.yx *= rot2(PI/2.0 * 1.01 * sin(sunTime) * sign(cos(sunTime)));
    
    gTorusDims   = vec2(4.0, 2.0);
    gTorusPos    = gVy * gTorusDims[1] * 0.0;

//  gBallInset   = (sin(gT * 0.1) * 0.3 + 0.7) * gBallRad * 1.2;
    const float insetMinFac = 0.2;
    const float insetMaxFac = 2.1;
    float git    = (gT + 31.0) * 0.015;
    gBallCycle   = floor(git - 31.0 * 0.015);
    gBallCycleHash = hash11(gBallCycle * 15.621341);
    float ballRadMin = 0.2;
    float ballRadMax = 2.2;
    float ballRadFac = mix(ballRadMin, ballRadMax, gBallCycleHash);
    if (gBallCycle == 0.0) {
        gBallCycleHash = 0.0;
        ballRadFac = 1.4;
    }
    
    gBallRad     = gTorusDims.y * ballRadFac;
    float gbx    = smoothstep(1.0, 0.7, -cos(git * PI * 2.0));
    gBallInset   = gBallRad * mix(insetMaxFac, insetMinFac, gbx);
    gBallOrbit   = gTorusDims.x + gTorusDims.y + gBallRad + 1.00;
    float ballDir = gBallCycleHash < 0.5 ? 1.0 : -1.0;
    gBallTime    = gT * ballDir * mix(0.42, 0.9, gBallCycleHash) + 2.2;
    gBallPos     = gVx * gBallOrbit + gVy * (gBallRad - gBallInset);
    gBallPos.xz *= rot2(-gBallTime);

    configMaterials();
}

vec3 toBallSpace(in vec3 p) {
    float f = 40.0;
    p.xz = mod(p.xz + f / 2.0, f) - f/2.0;
    return p - gBallPos;    
}


marchResult_t map(vec3 p) {
    gTotalMapIters += 1.0;
    
    vec3 pbs = toBallSpace(p);
    
    float d1 = p.y;
    // add some convexity to each hexagonal tile
    vec2 v2 = p.xz * gHexTileFac;
    float hexHash = hash12(hextile(v2) * 4.83);
    float lt = length(p.xz);
    float hl = dot(v2, v2);
    d1 += hl * 0.9 / (1.0 + lt);
    if (hexHash < 0.06) {
        d1 += cos(hl * 40.0) * 0.003;
    }
        
    
    float subtractedTorusRad = gBallRad * 1.0001;
    d1 = opS(d1, sdTorus(pbs + gBallPos - gVy * (gBallRad - gBallInset), vec2(gBallOrbit, subtractedTorusRad)));

    vec3 pt = p - dot(gTorusDims, vec2(1.0)) * gVy;
    pt.xy *= rot2(PI/2.0);
    float d2 = sdTorus(pt, gTorusDims);
    
    float d3 = sdSphere(toBallSpace(p), gBallRad);
    
    marchResult_t ret = marchResult_t(1e9, kMSky);
    if (d1 < ret.t) { ret = marchResult_t(d1, kMFloor); }
    if (d2 < ret.t) { ret = marchResult_t(d2, kMTorus); }
    if (d3 < ret.t) { ret = marchResult_t(d3, kMBall); }
    
    return ret;
}

void getCamPosDir(out vec3 camPos, out vec3 camDir) {
    float y    = smoothstep(0.05, 0.95, gSSMouse.y);
    camPos     = gVz * gCamDist;
    camPos.yz *= rot2((0.7 - y * 0.7) *  PI / 2.0);
    camPos.xz *= rot2((gSSMouse.x * 2.0 - 1.0) * -PI * 1.1);
    camPos    += gSceneCenter + gVy * 1.8;
    
 //   camPos     = gBallPos * 2.0;
   // camPos.y   = gBallPos.y * 0.5;
    camDir     = normalize(gSceneCenter - camPos);
}

ray_t getCamRay(in vec2 uv, float camZoom, in vec3 contribution) {
    vec3 camPos;
    vec3 camDir;
    getCamPosDir(camPos, camDir);
    ray_t ray;
    ray.ro           = camPos;
    ray.rd           = getCamRayDir(camDir, uv, camZoom);
    ray.internal     = map(camPos).t < 0.0;
    ray.shadow       = false;
    ray.contribution = contribution;
    return ray;
}


// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(vec3 p) {
    vec3 n = vec3(0.0);
    for (int i = ZERO; i < 4; i++) {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*gNormEps).t;
    }
    return normalize(n);
}

marchResult_t march(vec3 ro, vec3 rd) {
    float t = 0.0;
    
    vec3 p = ro;
    
    for (int n = 0; dot(p, p) < gMarchHorizonSq; ++n) {
        marchResult_t mr = map(p);
        if (mr.t < gMarchEps || n == gMarchMaxSteps) {
            return marchResult_t(t, mr.m);
        }
        
        t += mr.t * gMarchUnderStep;
        p = ro + t * rd;
    }
    
    return marchResult_t(1e9, 0u);
}


vec3 sky(vec3 dir) {
    vec3 ret = simple_sky(gVy * -1.5, dir, -gLightDir);
    // ungamma.
    // I'm not sure if this is 'correct'
    // but without it there are nasty pops in the post-sunset darkness.
    ret = pow(ret, vec3(1.5));
    return ret;
}

struct materialProps_t {
    vec3 albedo;
    vec3 emissive;
    float diffuse_vs_specular;  // 0 = diffuse 1 = specular
};

materialProps_t getMaterialProps(in vec3 p, uint m) {
    materialProps_t ret;
    
    material_t mat = kMaterials[m];
    
    ret.albedo              = mat.c1;
    ret.emissive            = gV0;
    ret.diffuse_vs_specular = mat.diffuseVsSpecular1;

    // special cases
    switch (m) {
        case kMFloor: {
            
            vec2 v2 = p.xz * gHexTileFac;
            vec2 ht = hextile(v2);
            ht.y *= 1.5;
            float hash = hash12(ht);
            if (hash * 4e3 < dot(ht, ht)) {
                ret.albedo = mat.c2;
                ret.emissive = ret.albedo * 0.1;
            }
            ret.diffuse_vs_specular = mix(mat.diffuseVsSpecular1, mat.diffuseVsSpecular2, hash);
            break;
        }
        case kMBall: {
            vec3 pp = toBallSpace(p);
            float at = smoothstep(gBallOrbit + gBallRad + 2.0, gBallOrbit + gBallRad + 1.0, length(p.xz));
            at = 0.1 + 0.9 * at;
            pp.xz *= rot2(gBallTime);                       // orbit
            pp.yz *= rot2(gBallTime * 4.0 * PI / gBallRad); // roll
            pp.xy *= rot2(2.2);                             // de-align
            vec3 rgb = vec3(0.0);
            for (int n = 0; n < 3; ++n) {
                const float eps = 0.03;
                float s = sin(4.0 * PI * (atan(pp[(n + 2)%3], pp[(n + 1)%3]) / (PI/2.0) * 0.5 + 0.5));
                float f = smoothstep(-eps, eps, s);
                rgb[(n + 0)%3] += f * 0.4;
                rgb[(n + 1)%3] += f * 0.4;
                rgb[(n + 2)%3] += f * 0.2;
            }
            rgb *= at;
            ret.albedo = mix(rgb, vec3(1.0), 0.05);
            ret.diffuse_vs_specular *= at;
            break;
        }
    }
    

#if 0
    // ping-pong between totally matte and specular,
    // with the nice tuned materials in the middle.
    float blah = sin(gT * 0.1);
    
    if (blah < 0.0) {
        ret.diffuse_vs_specular = mix(0.0, ret.diffuse_vs_specular, blah + 1.0);
    }
    else {
        ret.diffuse_vs_specular = mix(ret.diffuse_vs_specular, 1.0, blah);
    }
#endif

    
    return ret;
}

vec3 processRays() {

    vec3 rgb = gV0;

    while (!QIsEmpty() && gTotalMapIters < gMaxTotalMapIters) {
        ray_t ray = QDequeue();
        
        vec3 rayRGB = gV0;

        marchResult_t mr = march(ray.ro, ray.rd);
        
        if (ray.shadow) {
            if (mr.t > 1e4) {
                rgb += ray.contribution;
            }
        }
        else {
            if (mr.t < 1e4) {
                vec3 p = ray.ro + ray.rd * mr.t;

                vec3 n = calcNormal(p);

                materialProps_t mp = getMaterialProps(p, mr.m);

                vec3 albedo = mp.albedo;

                float specAmt = mp.diffuse_vs_specular;
                float diffAmt = 1.0 - specAmt;

                float maximumDirectionalContribution = max(0.0, dot(n, -gLightDir));

                vec3 directionalAmt = gDirectionalLight * maximumDirectionalContribution;
                vec3 diffContrib = directionalAmt * albedo * diffAmt;

                if (gLightDir.y < 0.0) {
                    if (maximumDirectionalContribution > 0.0 && !ray.internal && !QIsFull() && dot(diffContrib, diffContrib) > gMinRayContribSq) {
                        ray_t shdwRay;
                        shdwRay.ro           = p + n * gMarchEps * 2.0;
                        shdwRay.rd           = -gLightDir;
                        shdwRay.contribution = ray.contribution * diffContrib;
                        shdwRay.internal     = false;
                        shdwRay.shadow       = true;
                        QEnqueue(shdwRay);
                    }
                    else {
                        rayRGB += diffContrib;
                    }
                }
                
                rayRGB += albedo * gAmbientLight;
                rayRGB += mp.emissive;

                vec3 specContrib = ray.contribution * specAmt;

                if (!QIsFull() && dot(specContrib, specContrib) > gMinRayContribSq) {
                    ray_t rflRay;
                    rflRay.ro = p + n * gMarchEps * 2.0;
                    rflRay.rd = reflect(ray.rd, n);
                    rflRay.contribution = specContrib;
                    rflRay.internal = ray.internal;
                    rflRay.shadow       = false;
                    QEnqueue(rflRay);
                }

            }
            else {
                rayRGB += sky(ray.rd);
            }
            rgb += ray.contribution * rayRGB;
        }
    }
    
    return rgb;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
    configGlobals1();
    
    vec2 uv = (floor((XY - RES.xy/2.0)/gDownRes)) / MINRES * 2.0 * gSSZoom * gDownRes;
    
    QEnqueue(getCamRay(uv, 2.0, gV1));
    
    vec3 rgb = processRays();
    
    // temporal fade-in
    rgb *= 0.2 + 0.8 * square(smoothstep(0.0, 8.0, iTime));

    // gamma
    rgb = pow(rgb, vec3(1.0/2.2));
    
    
    RGBA = vec4(rgb, 1.0);
}