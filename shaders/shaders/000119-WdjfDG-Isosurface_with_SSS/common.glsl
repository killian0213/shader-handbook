// Common (common) — Isosurface with SSS by tmst
// https://www.shadertoy.com/view/WdjfDG

#define ITIME iTime
#define INITIALIZING (iFrame < 3)

// ===========
// References
// ===========

// Keyboard input:
// - https://www.shadertoy.com/view/lsXGzf (iq: "Input - Keyboard")
// Colormap:
// - https://www.shadertoy.com/view/ll2GD3 (iq: "Palettes")
// Hash functions:
// - https://www.shadertoy.com/view/4djSRW (Dave_Hoskins: "Hash without Sine")
// Mandelbulb DE:
// - https://www.shadertoy.com/view/wl2SDt (loicvdb: "Filmic mandelbulb animation")

// ==========================
// Generic Helpers/Constants
// ==========================

#define KEY_A 65
#define KEY_S 83
#define KEY_D 68
#define KEY_F 70

#define PI 3.141592653589793
#define TWOPI 6.283185307179586
#define HALFPI 1.570796326794896
#define PI_OVER_4 0.7853981633974483
#define SQRT2 1.414213562373095
#define SQRT3 1.732050807568877
#define INV_SQRT_2 0.7071067811865476

#define POLAR(theta) vec3(cos(theta), 0.0, sin(theta))
#define SPHERICAL(theta, phi) (sin(phi)*POLAR(theta) + vec3(0.0, cos(phi), 0.0))

// #define IR_LIQUID 1.333
// #define IR_AIR 1.000
// SCHLICK_R0 = pow((IR_LIQUID-IR_AIR)/(IR_LIQUID+IR_AIR), 2.0)
#define SCHLICK_R0 0.02040816326530612

// Find t so that mix(a,b,t) = x
float unmix(float a, float b, float x) {
    return (x - a)/(b - a);
}

float len3Inf(vec3 v) {
    vec3 d = abs(v);
    return max(d.x, max(d.y, d.z));
}

void boxClip(
    in vec3 boxMin, in vec3 boxMax,
    in vec3 p, in vec3 v,
    out vec2 tRange, out bool didHit
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
    didHit = step(tRange.s, tRange.t) > 0.5;
}

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

#define PAL(t, a, b, c, d) ( a + b*cos(TWOPI*(c*t+d)) )
vec3 colormap(float t) {
    return PAL(t, vec3(0.5,0.5,0.5), vec3(0.5,0.5,0.5), vec3(1.0,1.0,1.0), vec3(0.0,0.33,0.67));
}

vec4 blendOnto(vec4 cFront, vec4 cBehind) {
    return cFront + (1.0 - cFront.a)*cBehind;
}

vec4 blendOnto(vec4 cFront, vec3 cBehind) {
    return cFront + (1.0 - cFront.a)*vec4(cBehind, 1.0);
}

#define RES iResolution
#define TAN_HALF_FOVY 0.5773502691896257

vec3 nvCamDirFromClip(vec3 iResolution, vec3 nvFw, vec2 clip) {
    vec3 nvRt = normalize(cross(nvFw, vec3(0.,1.,0.)));
    vec3 nvUp = cross(nvRt, nvFw);
    return normalize(TAN_HALF_FOVY*(clip.x*(RES.x/RES.y)*nvRt + clip.y*nvUp) + nvFw);
}

// ======================
// Voxel packing helpers
// ======================

#define BOX_MIN vec3(-1.0)
#define BOX_MAX vec3(1.0)
#define BOX_CENTER vec3(0.0)
#define BOX_N 128.0

vec3 lmnFromWorldPos(vec3 p) {
    vec3 uvw = (p - BOX_MIN) / (BOX_MAX - BOX_MIN);
    return uvw * vec3(BOX_N-1.0);
}

vec3 worldPosFromLMN(vec3 lmn) {
    return mix(BOX_MIN, BOX_MAX, lmn/(BOX_N-1.0));
}

// Data is organized into 3 "pages" of 128x128x128 voxels.
// Each "page" takes up 2 faces of the 1024x1024 cubemap,
// each face storing 8x8=64 of the 128x128 slices.

vec3 vcubeFromLMN(in int page, in vec3 lmn) {
    // subtexture within [0,8)^2
    float l = mod(round(lmn.x), 128.0);
    float tm = mod(l, 8.0);
    float tn = mod((l - tm)/8.0, 8.0);
    vec2 tmn = vec2(tm, tn);

    // mn within [0,128)^2
    vec2 mn = mod(round(lmn.yz), 128.0);

    // pixel position on 1024x1024 face
    vec2 fragCoord = 128.0*tmn + mn + 0.5;
    vec2 p = fragCoord*(2.0/1024.0) - 1.0;

    vec3 fv;
    if (page == 1) {
        fv = vec3(1.0, p);
    } else if (page == 2) {
        fv = vec3(p.x, 1.0, p.y);
    } else {
        fv = fv = vec3(p, 1.0);
    }

    return l < 64.0 ? fv : -fv;
}

void lmnFromVCube(in vec3 vcube, out int page, out vec3 lmn) {
    // page and parity, and pixel position on 1024x1024 texture
    vec2 p;
    float parity;
    if (abs(vcube.x) > abs(vcube.y) && abs(vcube.x) > abs(vcube.z)) {
        page = 1;
        p = vcube.yz/vcube.x;
        parity = vcube.x;
    } else if (abs(vcube.y) > abs(vcube.z)) {
        page = 2;
        p = vcube.xz/vcube.y;
        parity = vcube.y;
    } else {
        page = 3;
        p = vcube.xy/vcube.z;
        parity = vcube.z;
    }
    vec2 fragCoord = floor((0.5 + 0.5*p)*1024.0);

    // mn within [0,128)^2
    vec2 mn = mod(fragCoord, 128.0);

    // subtexture within [0,8)^2
    vec2 tmn = floor(fragCoord/128.0);

    float lAdd;
    if (parity > 0.0) {
        lAdd = 0.0;
    } else {
        lAdd = 64.0;
    }
    lmn = vec3(tmn.y*8.0 + tmn.x + lAdd, mn);
}

// =============
// Blur helpers
// =============

#define BLUR_D 0.0025
#define CBLUR(offset) textureLod(src, uv+offset, 2.0).rgb

vec3 blurV(vec3 iResolution, sampler2D src, vec2 uv) {
    float blurD = BLUR_D * iResolution.x/iResolution.y;
    return (
        0.006 * CBLUR(vec2(0.0, -3.0*blurD)) +
        0.061 * CBLUR(vec2(0.0, -2.0*blurD)) +
        0.242 * CBLUR(vec2(0.0, -1.0*blurD)) +
        0.383 * CBLUR(vec2(0.0,  0.0*blurD)) +
        0.242 * CBLUR(vec2(0.0,  1.0*blurD)) +
        0.061 * CBLUR(vec2(0.0,  2.0*blurD)) +
        0.006 * CBLUR(vec2(0.0,  3.0*blurD))
    );
}

vec3 blurH(sampler2D src, vec2 uv) {
    return (
        0.006 * CBLUR(vec2(-3.0*BLUR_D, 0.0)) +
        0.061 * CBLUR(vec2(-2.0*BLUR_D, 0.0)) +
        0.242 * CBLUR(vec2(-1.0*BLUR_D, 0.0)) +
        0.383 * CBLUR(vec2( 0.0*BLUR_D, 0.0)) +
        0.242 * CBLUR(vec2( 1.0*BLUR_D, 0.0)) +
        0.061 * CBLUR(vec2( 2.0*BLUR_D, 0.0)) +
        0.006 * CBLUR(vec2( 3.0*BLUR_D, 0.0))
    );
}

// ===================
// Density definition
// ===================

// Density value for level surface
#define D_SURF 0.5

#define MAX_ALPHA_PER_UNIT_DIST 8.0
#define QUIT_ALPHA_L 0.99

#define RAY_STEP 0.0125
#define RAY_STEP_L 0.04

#define CAM_THETA(t) (0.2*t)
#define CAM_PHI(t) (HALFPI - 0.3)
#define LIGHT_POS(t) (3.0*POLAR(CAM_THETA(t) - 0.25*PI) + vec3(0.0, 1.0, 0.0))

float Power;
float PhiShift;
float ThetaShift;

float distanceEstimation(vec3 pos) {
    if(length(pos) > 1.5) return length(pos) - 1.2;
    vec3 z = pos;
    float dr = 1.0, r = 0.0, theta, phi;
    for (int i = 0; i < 8; i++) {
        r = length(z);
        if (r>1.5) break;
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        theta = acos(z.z/r) * Power + ThetaShift;
        phi = atan(z.y,z.x) * Power + PhiShift;
        float sinTheta = sin(theta);
        z = pow(r,Power) * vec3(sinTheta*cos(phi), sinTheta*sin(phi), cos(theta)) + pos;
    }
    return 0.5*log(r)*r/dr;
}

float fDensity(vec3 lmn, float time) {
    // Current position adjusted to [-1,1]^3
    vec3 uvw = (lmn - vec3(63.5))/63.5;

    #if 1
        // Mandelbulb
        time -= 1.5;

        Power = 5.0;
        ThetaShift = time;
        PhiShift = 0.5 * time;

        float dRaw = distanceEstimation(uvw*1.3);
        return 0.01 + smoothstep(0.1, -0.1, dRaw);
    #else
    	// Any other density is fine...
    	float r = 1.0 - smoothstep(0.4, 1.0, length(uvw));
    	r = step(0.15, r)*r;
    	vec3 vsph = mod(lmn, 16.0)/8.0 - vec3(1.0);
    	float dsph = mix(length(vsph), len3Inf(vsph), 0.75);
    	return smoothstep(r+0.5, r-0.5, dsph);

    #endif
}

// ========================
// Marching through volume
// ========================

#define DENSITY(lmn) fDensity(lmn, time)
#define T_MAX 1000.0

void hitSurface(
    in vec3 p, in vec3 nv, in float time,
	in vec2 fragCoord,
    out float tHit, out bool didHit
) {
    vec2 tRange;
    bool didHitBox;
    boxClip(BOX_MIN, BOX_MAX, p, nv, tRange, didHitBox);
    tRange.s = max(0.0, tRange.s);

    if (!didHitBox) {
        tHit = T_MAX;
        didHit = false;
        return;
    }

    float t = tRange.s + min(tRange.t-tRange.s, RAY_STEP)*hash12(fragCoord);
    for (int i = 0; i < 150; i++) { // Theoretical max steps: (BOX_MAX-BOX_MIN)*sqrt(3)/RAY_STEP
        if (t > tRange.t) { break; }

        vec3 rayPos = p + t*nv;
        vec3 lmn = lmnFromWorldPos(rayPos);
        float density = DENSITY(lmn);

        if (density > D_SURF) {
            // binary search between last step and this step
            float substep = (max(tRange.s, t-RAY_STEP) - t) * 0.5;
            for(int j=0; j<4; j++) {
                t += substep;

                rayPos = p + t*nv;
                lmn = lmnFromWorldPos(rayPos);
                density = DENSITY(lmn);

                substep = density < D_SURF ? abs(substep)*0.5 : -abs(substep)*0.5;
            }

			tHit = t;
            didHit = true;
            return;
        }

        t += RAY_STEP;
    }

    tHit = T_MAX;
    didHit = false;
}

// ==================
// Surface rendering
// ==================

#define LIGHT(lmn) texture(cubeSampler, vcubeFromLMN(2, lmn)).t

float getLightInterp(samplerCube cubeSampler, vec3 lmn) {
    vec3 flmn = floor(lmn);

    float d000 = LIGHT( flmn );
    float d001 = LIGHT( flmn + vec3(0.0, 0.0, 1.0) );
    float d010 = LIGHT( flmn + vec3(0.0, 1.0, 0.0) );
    float d011 = LIGHT( flmn + vec3(0.0, 1.0, 1.0) );
    float d100 = LIGHT( flmn + vec3(1.0, 0.0, 0.0) );
    float d101 = LIGHT( flmn + vec3(1.0, 0.0, 1.0) );
    float d110 = LIGHT( flmn + vec3(1.0, 1.0, 0.0) );
    float d111 = LIGHT( flmn + vec3(1.0, 1.0, 1.0) );

    vec3 t = lmn - flmn;
    return mix(
        mix(mix(d000, d100, t.x), mix(d010, d110, t.x), t.y),
        mix(mix(d001, d101, t.x), mix(d011, d111, t.x), t.y),
        t.z
    );
}

vec3 getNormalInterp(vec3 lmn, float time) {
    vec3 grad = vec3(
        DENSITY(lmn + vec3(0.1, 0.0, 0.0)) - DENSITY(lmn - vec3(0.1, 0.0, 0.0)),
        DENSITY(lmn + vec3(0.0, 0.1, 0.0)) - DENSITY(lmn - vec3(0.0, 0.1, 0.0)),
        DENSITY(lmn + vec3(0.0, 0.0, 0.1)) - DENSITY(lmn - vec3(0.0, 0.0, 0.1))
    );
    return -grad/(length(grad) + 1e-5);
}

vec3 skybox(vec3 nvDir) {
    return ( mix(0.25, 0.75, smoothstep(-0.2,0.2, nvDir.y)) )*vec3(0.7, 0.8, 1.0);
}

#define SPECULAR_COEFF 0.75
#define SPECULAR_EXP 30.0

bool inputOnlySSS;
bool inputNoSSS;
bool inputDebugNormal;
bool inputDebugDepth;

vec4 mainRender(
    samplerCube cubeSampler, samplerCube skySampler,
    vec3 iResolution, vec4 iMouse, vec2 fragCoord, float time
) {
    vec2 uv = fragCoord / RES.xy;

    // Camera
    bool isMousePressed = clamp(iMouse.z, 0.0, 1.0) > 0.5;
    vec2 mouseAng = isMousePressed
        ? PI * vec2(4.0, 1.0)*iMouse.xy / RES.xy
        : vec2(CAM_THETA(time), CAM_PHI(time));

    vec3 camPos = 1.4 * SPHERICAL(mouseAng.x, mouseAng.y);
    vec3 lookTarget = vec3(0.0);

	vec3 nvCamFw = normalize(lookTarget - camPos);
    vec3 nvCamDir = nvCamDirFromClip(iResolution, nvCamFw, uv*2. - 1.);

    // Hit surface
    float tSurf;
    bool didHitSurf;
    hitSurface(camPos, nvCamDir, time, fragCoord, tSurf, didHitSurf);
    vec3 p = camPos + tSurf*nvCamDir;
    
    // Skybox
    vec3 nvCamToLight = normalize(LIGHT_POS(time) - camPos);
    float towardLight = clamp(dot(nvCamToLight, nvCamDir), 0.0, 1.0);
    towardLight = pow(towardLight, 7.0);
    vec3 bgColor = mix(skybox(nvCamDir), vec3(1.0), towardLight);

    // Render
    vec4 color = vec4(0.0);
    if (didHitSurf) {
        vec3 lmn = lmnFromWorldPos(p);
        vec3 nvNormal = getNormalInterp(lmn, time);
        float lightAmount = getLightInterp(cubeSampler, lmn);

        // User input adjustments
        // -----------------------

        if (inputNoSSS) {
            lightAmount = 0.5;
        }
        if (inputOnlySSS) {
            return vec4(vec3(lightAmount), 0.0);
        } else if (inputDebugNormal) {
            return vec4(0.5+0.5*nvNormal, 0.0);
        }
        // -----------------------

        vec3 cSurfIn = colormap(0.1*time);
        vec3 cSurfOut = mix(colormap(0.1*time+0.375), vec3(1.0), 0.5);
        vec3 cSurfMix = mix(cSurfIn, cSurfOut, lightAmount);

        vec3 nvFragToLight = normalize(LIGHT_POS(time) - p);
        vec3 nvFragToCam = normalize(camPos - p);

        // Specular contribution
        vec3 blinnH = normalize(nvFragToLight + nvFragToCam);
        float valSpecular = SPECULAR_COEFF * pow(max(0.0, dot(nvNormal, blinnH)), SPECULAR_EXP);

        // Schlick approximation
        float cosHitAngle = dot(nvNormal, nvFragToCam);
        float valRefl = mix(SCHLICK_R0, 1.0, pow(clamp(1.0 - cosHitAngle, 0.0, 1.0), 5.0));
        valRefl = clamp(valRefl, 0.025, 0.125);

        vec3 vRefl = reflect(-nvFragToCam, nvNormal);
        vec3 cRefl = texture(skySampler, vRefl).rrr;

        color = vec4(0.1*cSurfOut, 1.0); // Ambient contribution
        color = blendOnto(lightAmount*vec4(cSurfMix, 1.0), color);
        color = blendOnto(valRefl*vec4(cRefl, 1.0), color);
        color = blendOnto(lightAmount*valSpecular*vec4(1.0), color);
        
    }
    vec3 finalColor = blendOnto(color, bgColor).rgb;

    float camDist = distance(camPos, BOX_CENTER);
    float blurAmount = clamp(unmix(-SQRT3*0.5, SQRT3*0.375, tSurf - camDist), 0.0, 1.0);

    return inputDebugDepth ? vec4(vec3(blurAmount), 0.0) : vec4(finalColor, blurAmount);
}
