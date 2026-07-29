// Image (image) — SF Shadertoy party invite by otaviogood
// https://www.shadertoy.com/view/wsSXzz

/*--------------------------------------------------------------------------------------
License CC0 - http://creativecommons.org/publicdomain/zero/1.0/
To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
----------------------------------------------------------------------------------------
^ This means do ANYTHING YOU WANT with this code. Because we are programmers, not lawyers.
-Otavio Good
*/

// THIS NEEDS A WEBGL 2.0 CAPABLE BROWSER OR IT WILL NOT WORK.

// ---------------- Config ----------------
// This is an option that lets you render high quality frames for screenshots. It enables
// stochastic antialiasing and motion blur automatically for any shader.
//#define NON_REALTIME_HQ_RENDER
const float frameToRenderHQ = 50.0; // Time in seconds of frame to render
const float antialiasingSamples = 16.0; // 16x antialiasing - too much might make the shader compiler angry.

//#define MANUAL_CAMERA


// --------------------------------------------------------
// These variables are for the non-realtime block renderer.
float localTime = 0.0;
#ifdef NON_REALTIME_HQ_RENDER
float seed = 1.0;
#endif

// Animation variables
vec3 sunDir;
int currentText;

// Animation key frames
const int numKeyFrames = 8;
const float keys[numKeyFrames] = float[numKeyFrames]
    (0.0, 14.0, 16.0, 24.0, 32.0, 40.0, 50.0, 59.0);

// Deterministic hash that should work the same on all video cards. Just something I made up.
// Should return a number [0..1)
float JankyHash(uint seed) {
    seed ^= ((seed ^ uint(1000000207)) * uint(1000000007)) >> 7;
    seed = (seed ^ uint(1000000409)) * uint(1000000531);
    return float(seed & uint(0xffff)) / (65536.0);
}

vec2 JankyHash2(uint seed) {
    seed ^= ((seed ^ uint(1000000207)) * uint(1000000007)) >> 7;
    seed = (seed ^ uint(1000000409)) * uint(1000000531);
    return vec2(seed & uint(0xffff), seed >> 16) / (65536.0);
}

// ---- noise functions ----
float v31(vec3 a)
{
    return a.x + a.y * 37.0 + a.z * 521.0;
}
float v21(vec2 a)
{
    return a.x + a.y * 37.0;
}
float Hash11(float a)
{
    return fract(sin(a)*10403.9);
}
float Hash21(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(sin(f)*104003.9);
}
vec2 Hash22(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(cos(f)*vec2(10003.579, 37049.7));
}
vec2 Hash12(float f)
{
    return fract(cos(f)*vec2(10003.579, 37049.7));
}
float Hash1d(float u)
{
    return fract(sin(u)*143.9);	// scale this down to kill the jitters
}
float Hash2d(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(sin(f)*104003.9);
}
float Hash3d(vec3 uv)
{
    float f = uv.x + uv.y * 37.0 + uv.z * 521.0;
    return fract(sin(f)*110003.9);
}
float mixP(float f0, float f1, float a)
{
    return mix(f0, f1, a*a*(3.0-2.0*a));
}
const vec2 zeroOne = vec2(0.0, 1.0);
float noise2d(vec2 uv)
{
    vec2 fr = fract(uv.xy);
    vec2 fl = floor(uv.xy);
    float h00 = Hash2d(fl);
    float h10 = Hash2d(fl + zeroOne.yx);
    float h01 = Hash2d(fl + zeroOne);
    float h11 = Hash2d(fl + zeroOne.yy);
    return mixP(mixP(h00, h10, fr.x), mixP(h01, h11, fr.x), fr.y);
}
float noise(vec3 uv)
{
    vec3 fr = fract(uv.xyz);
    vec3 fl = floor(uv.xyz);
    float h000 = Hash3d(fl);
    float h100 = Hash3d(fl + zeroOne.yxx);
    float h010 = Hash3d(fl + zeroOne.xyx);
    float h110 = Hash3d(fl + zeroOne.yyx);
    float h001 = Hash3d(fl + zeroOne.xxy);
    float h101 = Hash3d(fl + zeroOne.yxy);
    float h011 = Hash3d(fl + zeroOne.xyy);
    float h111 = Hash3d(fl + zeroOne.yyy);
    return mixP(
        mixP(mixP(h000, h100, fr.x),
             mixP(h010, h110, fr.x), fr.y),
        mixP(mixP(h001, h101, fr.x),
             mixP(h011, h111, fr.x), fr.y)
        , fr.z);
}

vec2 NoiseTex(in vec3 x) {
    vec3 fr = fract(x);
    vec3 fl = floor(x);
	fr.xy = fr.xy * fr.xy * (3.0 - 2.0 * fr.xy);
	vec2 uva = (fl.xy + vec2(37.0, 17.0)*fl.z) + fr.xy;
	vec2 uvb = (fl.xy + vec2(37.0, 17.0)*fl.z + vec2(37.0, 17.0)) + fr.xy;
	vec2 a = textureLod( iChannel1, (uva + 0.5) / 256.0, 0.0).yx;
	vec2 b = textureLod( iChannel1, (uvb + 0.5) / 256.0, 0.0).yx;
    return mix(a, b, fr.z) - 0.5;
}

const float PI=3.14159265;

#define saturate(a) clamp(a, 0.0, 1.0)

// Noise generator from https://otaviogood.github.io/noisegen/
// Params: 2D, Seed 10, Waves 8, Octaves 5, Smooth 1
float NoiseGen(vec2 p) {
    // This is a bit faster if we use 2 accumulators instead of 1.
    // Timed on Linux/Chrome/TitanX Pascal
    float wave0 = 0.0;
    float wave1 = 0.0;
    wave0 += sin(dot(p, vec2(0.600, -2.119))) * 0.2939877018;
    wave1 += sin(dot(p, vec2(0.972, 2.283))) * 0.2387554666;
    wave0 += sin(dot(p, vec2(3.511, 0.119))) * 0.1406977328;
    wave1 += sin(dot(p, vec2(0.494, -5.303))) * 0.0817366769;
    wave0 += sin(dot(p, vec2(8.383, -1.242))) * 0.0473036532;
    wave1 += sin(dot(p, vec2(3.356, -7.905))) * 0.0465956513;
    wave0 += sin(dot(p, vec2(-7.794, 10.606))) * 0.0290698451;
    wave1 += sin(dot(p, vec2(15.407, -2.728))) * 0.0241393549;
    return wave0+wave1;
}

// Returns gradient of the noise function at position p.
vec2 NoiseGenGrad(vec2 p) {
    vec2 dWave0 = vec2(0.0);
    vec2 dWave1 = vec2(0.0);
    vec2 dir = vec2(0.0);
    dir = vec2(0.600, -2.119);    dWave0 += dir * cos(dot(p, dir)) * 0.2939877018;
    dir = vec2(0.972, 2.283);    dWave1 += dir * cos(dot(p, dir)) * 0.2387554666;
    dir = vec2(3.511, 0.119);    dWave0 += dir * cos(dot(p, dir)) * 0.1406977328;
    dir = vec2(0.494, -5.303);    dWave1 += dir * cos(dot(p, dir)) * 0.0817366769;
    dir = vec2(8.383, -1.242);    dWave0 += dir * cos(dot(p, dir)) * 0.0473036532;
    dir = vec2(3.356, -7.905);    dWave1 += dir * cos(dot(p, dir)) * 0.0465956513;
    dir = vec2(-7.794, 10.606);    dWave0 += dir * cos(dot(p, dir)) * 0.0290698451;
    dir = vec2(15.407, -2.728);    dWave1 += dir * cos(dot(p, dir)) * 0.0241393549;
    return dWave0+dWave1;
}

vec3 RotateY(vec3 v, float rad)
{
  float c = cos(rad);
  float s = sin(rad);
  return vec3(c * v.x - s * v.z, v.y, s * v.x + c * v.z);
}

vec2 Rotate(vec2 v, float rad)
{
  float c = cos(rad);
  float s = sin(rad);
  return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

// This function basically is a procedural environment map that makes the sun
vec3 GetSunColorSmall(vec3 rayDir, vec3 sunDir, vec3 sunCol)
{
	vec3 localRay = rayDir;
	float dist = 1.0 - (dot(localRay, sunDir) * 0.5 + 0.5);
	float sunIntensity = 0.05 / dist;
    sunIntensity += exp(-dist*150.0)*7000.0;
	sunIntensity = min(sunIntensity, 40000.0);
	return sunCol * sunIntensity*0.002;
}

vec3 GetEnvMap(vec3 rayDir, vec3 sunDir,
               vec3 sunCol, vec3 groundCol, vec3 horizonCol, vec3 skyCol)
{
    // fade the sky color, multiply sunset dimming
    vec3 finalColor = mix(horizonCol, skyCol, pow(saturate(rayDir.y), 0.25))*0.95;
    // make clouds - just a horizontal plane with noise
    //float n = noise2d(rayDir.xz/rayDir.y*1.0);
    //n += noise2d(rayDir.xz/rayDir.y*2.0)*0.5;
    //n += noise2d(rayDir.xz/rayDir.y*4.0)*0.25;
    //n += noise2d(rayDir.xz/rayDir.y*8.0)*0.125;
    float n = NoiseGen(rayDir.xz/rayDir.y)*2.0+0.6;
    vec2 ng = NoiseGenGrad(rayDir.xz/rayDir.y);
    n = pow(abs(n), 3.0);
    n = n * saturate(abs(rayDir.y * 4.0));  // fade clouds in distance
	float dist = 1.0 - (dot(rayDir, sunDir) * 0.5 + 0.5);
    float cloudShadow = -dot(ng, sunDir.xz)*0.5+0.5;
    vec3 cloudCol = (vec3(0.5,0.3,0.1)/dist+sunCol*cloudShadow)*saturate((rayDir.y+0.2)*5.0);
    finalColor = mix(finalColor, cloudCol, saturate(n*0.0625));

    // Background mountains
    float n2 = NoiseGen(rayDir.xz*16.0)*0.75;
    n2 += 1.5 - saturate(-rayDir.x)*3.0;
    vec3 mountainCol = (horizonCol * 0.75 + skyCol * 0.25) * 0.55 - rayDir.y*3.0;
    finalColor = mix(finalColor, mountainCol, saturate((n2*0.025-rayDir.y)*512.0));

    // Foreground mountains
    n2 = NoiseGen(-rayDir.xz*16.0)*1.0;
    n2 += 1.8 - saturate(-rayDir.x)*3.0;;
    mountainCol = (horizonCol * 0.8 + skyCol * 0.2) * 0.40 + vec3(0.035, 0.0, 0.0);
    finalColor = mix(finalColor, mountainCol, saturate((n2*0.0125-rayDir.y)*512.0));

    // Foreground mountains
    n2 = NoiseGen(-rayDir.zx*16.0)*1.0;
    n2 += 0.6 - saturate(-rayDir.x)*3.0;;
    mountainCol = (horizonCol * 0.5 + groundCol * 0.5) * 0.45 + vec3(0.0, 0.025, 0.0);
    finalColor = mix(finalColor, mountainCol, saturate((n2*0.0125-rayDir.y)*512.0));

    // Ground color fade
    finalColor = mix(finalColor, (groundCol + horizonCol)*0.4, saturate(-rayDir.y*16.0));
    finalColor = mix(finalColor, groundCol*0.4, saturate(-5.0-rayDir.y*8.0));

    // add the sun
    finalColor += GetSunColorSmall(rayDir, sunDir, sunCol);
    return finalColor;
}

vec3 GetEnvMapSimple(vec3 rayDir, vec3 sunDir, vec3 sunCol, vec3 horizonCol, vec3 skyCol)
{
    // fade the sky color, multiply sunset dimming
    vec3 finalColor = mix(horizonCol, skyCol, pow(saturate(rayDir.y), 0.25))*0.95;
    // make clouds - just a horizontal plane with noise
    float n = NoiseGen(rayDir.xz/rayDir.y)*2.0+0.6;
    n = pow(abs(n), 3.0);
    n = n * saturate(abs(rayDir.y * 4.0));  // fade clouds in distance
	float dist = 1.0 - (dot(rayDir, sunDir) * 0.5 + 0.5);
    vec3 cloudCol = (vec3(0.5,0.3,0.1)/dist+sunCol)*saturate((rayDir.y+0.2)*5.0);
    finalColor = mix(finalColor, cloudCol, saturate(n*0.0625));

    // Background mountains
    float n2 = NoiseGen(rayDir.xz*16.0)*0.75;
    n2 += 1.5 - saturate(-rayDir.x)*3.0;
    vec3 mountainCol = (horizonCol * 0.75 + skyCol * 0.25) * 0.55 - rayDir.y*3.0;
    finalColor = mix(finalColor, mountainCol, saturate((n2*0.025-rayDir.y)*512.0));

    // Ground color fade
    //finalColor = mix(finalColor, (groundCol + horizonCol)*0.4, saturate(-rayDir.y*16.0));
    //finalColor = mix(finalColor, groundCol*0.4, saturate(-5.0-rayDir.y*8.0));

    // add the sun
    finalColor += GetSunColorSmall(rayDir, sunDir, sunCol);
    return finalColor;
}

vec3 GetEnvMapSkyline(vec3 rayDir, vec3 sunDir, float height,
                      vec3 sunCol, vec3 horizonCol, vec3 skyCol)
{
    vec3 finalColor = GetEnvMapSimple(rayDir, sunDir, sunCol, horizonCol, skyCol);

    // Make a skyscraper skyline reflection.
    float radial = atan(rayDir.z, rayDir.x)*4.0;
    float skyline = floor((sin(5.3456*radial) + sin(1.234*radial)+ sin(2.177*radial))*0.6);
    radial *= 4.0;
    skyline += floor((sin(5.0*radial) + sin(1.234*radial)+ sin(2.177*radial))*0.6)*0.1;
    float mask = saturate((rayDir.y*8.0 - skyline-2.5+height)*24.0);
    float vert = sign(sin(radial*32.0))*0.5+0.5;
    float hor = sign(sin(rayDir.y*256.0))*0.5+0.5;
    mask = saturate(mask + (1.0-hor*vert)*0.05);
    finalColor = mix(finalColor * vec3(0.1,0.07,0.05), finalColor, mask);

	return finalColor;
}

// min function that supports materials in the y component
vec2 matmin(vec2 a, vec2 b)
{
    if (a.x < b.x) return a;
    else return b;
}
vec2 matmax(vec2 a, vec2 b)
{
    if (a.x > b.x) return a;
    else return b;
}

// -------- Ray intersection functions and data structures --------
const float farPlane = 1024.0;

vec4 Union(vec4 a, vec4 b)
{
    if (a.w < b.w) return a;
    else return b;
}

// dirVec MUST BE NORMALIZED FIRST!!!!
float SphereIntersect(vec3 pos, vec3 dirVecPLZNormalizeMeFirst, vec3 spherePos, float rad)
{
    vec3 radialVec = pos - spherePos;
    float b = dot(radialVec, dirVecPLZNormalizeMeFirst);
    float c = dot(radialVec, radialVec) - rad * rad;
    float h = b * b - c;
    if (h < 0.0) return -1.0;
    return -b - sqrt(h);
}

// Return value is normal in xyz, t in w.
// outside is 1 to intersect from the outside of the sphere, -1 to intersect from inside of sphere.
vec4 SphereIntersect3(vec3 pos, vec3 dirVecPLZNormalizeMeFirst, vec3 spherePos, float rad, int outside)
{
    vec4 rh = vec4(farPlane);
    vec3 delta = spherePos - pos;
    float projdist = dot(delta, dirVecPLZNormalizeMeFirst);
    vec3 proj = dirVecPLZNormalizeMeFirst * projdist;
    vec3 bv = proj - delta;
    float b2 = dot(bv, bv);
    if (b2 > rad*rad) return rh;  // Ray missed the sphere
    float x = sqrt(rad*rad - b2);
    rh.w = projdist - (x * float(outside));
    vec3 hitPos = pos + dirVecPLZNormalizeMeFirst * rh.w;
    rh.xyz = normalize(hitPos - spherePos);  // Normal still points outwards if collision from inside.
    return rh;
}

// Return value is normal in xyz, t in w.
vec4 PlaneIntersect(vec3 camPos, vec3 dirVecPLZNormalizeMeFirst, vec3 planeNormal, vec3 pointOnPlane) {
    vec4 rh = vec4(farPlane);
    float denom = dot(planeNormal, dirVecPLZNormalizeMeFirst);
    if (denom != 0.0) {
        vec3 p0l0 = pointOnPlane - camPos;
        rh.w = dot(p0l0, planeNormal) / denom;
        //rh.hit = camPos + dirVecPLZNormalizeMeFirst * rh.t;
        rh.xyz = planeNormal * sign(-denom);
    }
    if (rh.w <= 0.0) rh.w = farPlane;
    return rh;
}

// https://tavianator.com/fast-branchless-raybounding-box-intersections/
// Return value is normal in xyz, t in w.
// rayInv is 1.0 / direction vector
vec4 BoxIntersect(vec3 pos, vec3 rayInv, vec3 boxPos, vec3 rad)
{
    vec3 bmin = boxPos - rad;
    vec3 bmax = boxPos + rad;
//    vec3 rayInv = 1.0 / dirVecPLZNormalizeMeFirst;

    vec3 t1 = (bmin - pos) * rayInv;
    vec3 t2 = (bmax - pos) * rayInv;

    vec3 vmin = min(t1, t2);
    vec3 vmax = max(t1, t2);

    float tmin = max(vmin.z, max(vmin.x, vmin.y));
    float tmax = min(vmax.z, min(vmax.x, vmax.y));

    vec4 rh = vec4(0,1,0,farPlane);
    if ((tmax <= tmin)) return rh;
    if ((tmin <= 0.0)) return rh;
    rh.w = tmin;
    // optimize me!
    if (t1.x == tmin) rh.xyz = vec3(-1.0, 0.0, 0.0);
    if (t2.x == tmin) rh.xyz = vec3(1.0, 0.0, 0.0);
    if (t1.y == tmin) rh.xyz = vec3(0.0, -1.0, 0.0);
    if (t2.y == tmin) rh.xyz = vec3(0.0, 1.0, 0.0);
    if (t1.z == tmin) rh.xyz = vec3(0.0, 0.0, -1.0);
    if (t2.z == tmin) rh.xyz = vec3(0.0, 0.0, 1.0);
    return rh;
}

// ---- shapes defined by distance fields ----
// See this site for a reference to more distance functions...
// https://iquilezles.org/articles/distfunctions

// signed box distance field
float sdBox(vec3 p, vec3 radius)
{
  vec3 dist = abs(p) - radius;
  return min(max(dist.x, max(dist.y, dist.z)), 0.0) + length(max(dist, 0.0));
}

// capped cylinder distance field
float cylCap(vec3 p, float r, float lenRad)
{
    float a = length(p.xy) - r;
    a = max(a, abs(p.z) - lenRad);
    return a;
}

// k should be negative. -4.0 works nicely.
// smooth blending function
float smin(float a, float b, float k)
{
	return log2(exp2(k*a)+exp2(k*b))/k;
}

float Repeat(float a, float len)
{
    return mod(a, len) - 0.5 * len;
}

// Font rendering macros (ASCII codes)
#define _SPACE 32
#define _EXCLAMATION 33
#define _COMMA 44
#define _DASH 45
#define _PERIOD 46
#define _SLASH 47
#define _COLON 58
#define _AT 64
#define _A 65
#define _B 66
#define _C 67
#define _D 68
#define _E 69
#define _F 70
#define _G 71
#define _H 72
#define _I 73
#define _J 74
#define _K 75
#define _L 76
#define _M 77
#define _N 78
#define _O 79
#define _P 80
#define _Q 81
#define _R 82
#define _S 83
#define _T 84
#define _U 85
#define _V 86
#define _W 87
#define _X 88
#define _Y 89
#define _Z 90

#define _a 97
#define _b 98
#define _c 99
#define _d 100
#define _e 101
#define _f 102
#define _g 103
#define _h 104
#define _i 105
#define _j 106
#define _k 107
#define _l 108
#define _m 109
#define _n 110
#define _o 111
#define _p 112
#define _q 113
#define _r 114
#define _s 115
#define _t 116
#define _u 117
#define _v 118
#define _w 119
#define _x 120
#define _y 121
#define _z 122

#define _0 48
#define _1 49
#define _2 50
#define _3 51
#define _4 52
#define _5 53
#define _6 54
#define _7 55
#define _8 56
#define _9 57

// San Francisco
// Shadertoy party
// March 19 2019 18:30
// @ Figma
// 116 New Montgomery, 9th floor
// meetup.com/San-Francisco-shadertoy

const int numLetters = 118;
const int wordStarts[6] = int[6] (0, 14, 31, 44, 62, 94);  // This is weird. Oh well. Bugs.
const int wordLens[6] = int[6] (13, 15, 19, 7, 28, 35);
const float wordScales[6] = float[6] (2.0, 0.35, 0.5, 0.087, 0.044, 1.0);
const vec3 currentTextPos[6] = vec3[6] (
    vec3(-12.0,6.0,29.0),
    vec3(-1.35,0.11,16.5),
    vec3(-2.0,3.5,2.2),
    vec3(16.795, 0.88, 2.5),
    vec3(10.83, 0.02, 0.948),
    vec3(-19.5,8.0,33.2));
const int letterArray[numLetters] = int[numLetters]
    (_S,_a,_n,_SPACE,_F,_r,_a,_n,_c,_i,_s,_c,_o,  // 13
     _S,_H,_A,_D,_E,_R,_T,_O,_Y,_SPACE,_P,_A,_R,_T,_Y,  // 15
    _M,_a,_r,_c,_h,_SPACE,_1,_9,_SPACE,_2,_0,_1,_9,_SPACE,_1,_8,_COLON,_3,_0,  // 19
    _AT,_SPACE,_F,_I,_G,_M,_A,  // 7
    _1,_1,_6,_SPACE,_N,_e,_w,_SPACE,_M,_o,_n,_t,_g,_o,_m,_e,_r,_y,_COMMA,_9,_t,_h,_SPACE,_f,_l,_o,_o,_r, _SPACE,  // 29
    _m,_e,_e,_t,_u,_p,_PERIOD,_c,_o,_m,_SLASH,_S,_a,_n,_DASH,_F,_r,_a,_n,_c,_i,_s,_c,_o,_DASH,_s,_h,_a,_d,_e,_r,_t,_o,_y, _SPACE);  // 35

vec4 SampleFontTex(vec2 uv)
{
    float fl = floor(uv + 0.5).x;
    float cursorPos = fl;
    int letter = 0;

    letter = letterArray[int(cursorPos - 0.0)];
    vec2 lp = vec2(letter % 16, 15 - letter/16);
    vec2 uvl = lp + fract(uv+0.5)-0.5;

    // Sample the font texture. Make sure to not use mipmaps.
    // Add a small amount to the distance field to prevent a strange bug on some gpus. Slightly mysterious. :(
    return texture(iChannel2, (uvl+0.5)*(1.0/16.0), -100.0) + vec4(0.0, 0.0, 0.0, 0.000000001);
}

// Distance function that defines the car.
// Basically it's 2 boxes smooth-blended together and a mirrored cylinder for the wheels.
vec2 Car(vec3 baseCenter, float unique)
{
    // bottom box
    float car = sdBox(baseCenter + vec3(0.0, -0.008, 0.002), vec3(0.009, 0.00225, 0.0275)) - 0.0015;
    // top box smooth blended
    car = smin(car, sdBox(baseCenter + vec3(0.0, -0.016, 0.0075), vec3(0.004, 0.0005, 0.007)), -160.0);
    // mirror the z axis to duplicate the cylinders for wheels
    vec3 wMirror = baseCenter + vec3(0.0, -0.005, 0.002);
    wMirror.z = abs(wMirror.z)-0.02;
    float wheels = cylCap((wMirror).zyx, 0.004, 0.0135);
    // Set materials
    vec2 distAndMat = vec2(wheels, 3.0);	// car wheels
    // Car material is some big number that's unique to each car
    // so I can have each car be a different color
    distAndMat = matmin(distAndMat, vec2(car, 100000.0 + unique));	// car
    return distAndMat;
}

const float parkHeight = 0.1;
float Hills(vec3 p) {
    vec2 tempP = p.xz;
    tempP.y = abs(tempP.y - 29.6) - 29.6;
    float pxz2 = dot(tempP.xy, tempP.xy);
    float noise = NoiseGen(-p.zx*0.125)*0.2;
    float height = p.y;
    height -= 2.0f / exp(pxz2*0.008);
    return height + 0.13 + noise ;
}

// How much space between voxel borders and geometry for voxel ray march optimization
const float voxelPad = 0.2;
// p should be in [0..1] range on xz plane
// pint is an integer pair saying which city block you are on
vec2 CityBlock(vec3 p, vec2 pint)
{
    // Get random numbers for this block by hashing the city block variable
    vec4 rand;
    //rand.xy = Hash22(pint);
    //rand.zw = Hash22(rand.xy);
    //vec2 rand2 = Hash22(rand.zw);
    rand.xy = JankyHash2(uint(pint.x + pint.y * 103.0 + 10009.0));
    rand.zw = JankyHash2(uint(pint.x + pint.y * 103.0 + 10007.0 + rand.x*211.0));
    vec2 rand2 = JankyHash2(uint(pint.x + pint.y * 103.0 + 10007.0 + rand.y*211.0));

    // Radius of the building
    float baseRad = 0.2 + (rand.x) * 0.1;
    baseRad = floor(baseRad * 20.0+0.5)/20.0;	// try to snap this for window texture

    // make position relative to the middle of the block
    vec3 baseCenter = p - vec3(0.5, 0.0, 0.5);
    float height = rand.w*rand.z + 0.1; // height of first building block
    // Make the city skyline higher in the middle of the city.
    float downtown = saturate(4.0 / length(pint.xy));
    height *= downtown;
    height *= 0.5+(baseRad-0.15)*20.0;
    height += 0.1;	// minimum building height
    //height += sin(iTime + pint.x);	// animate the building heights if you're feeling silly
    height = floor(height*20.0)*0.05;	// height is in floor units - each floor is 0.05 high.
	float d = sdBox(baseCenter, vec3(baseRad, height, baseRad)); // large building piece

    // road
    d = min(d, p.y);

    //if (length(pint.xy) > 8.0) return vec2(d, mat);	// Hack to LOD in the distance

    // height of second building section
    float height2 = max(0.0, rand.y * 2.0 - 1.0) * downtown;
    height2 = floor(height2*20.0)*0.05;	// floor units
    rand2 = floor(rand2*20.0)*0.05;	// floor units
    // size pieces of building
	d = min(d, sdBox(baseCenter - vec3(0.0, height, 0.0), vec3(baseRad, height2 - rand2.y, baseRad*0.4)));
	d = min(d, sdBox(baseCenter - vec3(0.0, height, 0.0), vec3(baseRad*0.4, height2 - rand2.x, baseRad)));
    // second building section
    if (rand2.y > 0.25)
    {
		d = min(d, sdBox(baseCenter - vec3(0.0, height, 0.0), vec3(baseRad*0.8, height2, baseRad*0.8)));
        // subtract off piece from top so it looks like there's a wall around the roof.
        float topWidth = baseRad;
        if (height2 > 0.0) topWidth = baseRad * 0.8;
		d = max(d, -sdBox(baseCenter - vec3(0.0, height+height2, 0.0), vec3(topWidth-0.0125, 0.015, topWidth-0.0125)));
    }
    else
    {
        // Cylinder top section of building
		if (height2 > 0.0) d = min(d, cylCap((baseCenter - vec3(0.0, height, 0.0)).xzy, baseRad*0.8, height2));
    }
    // mini elevator shaft boxes on top of building
	d = min(d, sdBox(baseCenter - vec3((rand.x-0.5)*baseRad, height+height2, (rand.y-0.5)*baseRad),
                     vec3(baseRad*0.3*rand.z, 0.1*rand2.y, baseRad*0.3*rand2.x+0.025)));
    // mirror another box (and scale it) so we get 2 boxes for the price of 1.
    vec3 boxPos = baseCenter - vec3((rand2.x-0.5)*baseRad, height+height2, (rand2.y-0.5)*baseRad);
    float big = sign(boxPos.x);
    boxPos.x = abs(boxPos.x)-0.02 - baseRad*0.3*rand.w;
	d = min(d, sdBox(boxPos,
    vec3(baseRad*0.3*rand.w, 0.07*rand.y, baseRad*0.2*rand.x + big*0.025)));

    // Put domes on some building tops for variety
    if (rand.y < 0.04)
    {
        d = min(d, length(baseCenter - vec3(0.0, height, 0.0)) - baseRad*0.8);
    }

    // Transamerica pyramid special-case building.
    if ((pint.x == 0.0) && (pint.y == 1.0)) {
        vec3 slice = abs(baseCenter) - 0.25;
    	d = max(max(slice.x + slice.y * 0.1, slice.z + slice.y * 0.1), baseCenter.y - 2.55);
        d = min(d, sdBox(baseCenter - vec3(0.0, 1.2, 0.0), vec3(0.05, 0.9, 0.17)));

    } //else
    //d = max(d, p.y);  // flatten the city for debugging cars

    // Need to make a material variable.
    vec2 distAndMat = vec2(d, 0.0);
    // sidewalk box with material
    distAndMat = matmin(distAndMat, vec2(sdBox(baseCenter, vec3(0.35, 0.005, 0.35)), 1.0));

    return distAndMat;
}

// landmark ideas
// gg bridge
// lombard
// pier 39
// transamerica
// salesforce tower?
// alcatraz
// coit tower
// figma office

vec2 Render3dText(vec3 p, vec3 textOrigin, float angle, int start, int len, float scale) {
	// Load the font texture's distance field.
    vec3 p2 = p - textOrigin;
    vec3 pr = RotateY(p2.xyz, angle)/scale + vec3(6+start, 0.0, 0.0);
    float letterDistField = ((SampleFontTex(pr.xy).w - 0.5) + 1.0 / 256.0)*wordScales[currentText];
    vec3 boxDim = abs(RotateY(vec3(float(len) * 0.5, 0.5, 0.1025), angle)) * scale;
    float cropBox = sdBox(p + vec3(0.0, 0.0, 0.0) - textOrigin, boxDim);
    return vec2(max(cropBox, letterDistField), 5.0);
}

// This is the distance function that defines all the scene's geometry.
// The input is a position in space.
// The output is the distance to the nearest surface and a material index.
vec2 DistanceToObject(vec3 p)
{
    vec3 origp = p;
    p.y = Hills(p);
    vec3 rep = p;
    rep.xz = fract(p.xz); // [0..1] for representing the position in the city block
    vec2 pint = floor(p.xz);
    vec2 distAndMat = CityBlock(rep, pint);

    float blockHill = Hills(vec3(pint.x, 0, pint.y));
    if ((blockHill > -parkHeight) || (pint.y > 15.0)) distAndMat = matmax(distAndMat, vec2(p.y, 4.0));

    // Make an extra hill (mirrored) at the 2 ends of the Golden Gate Bridge
    vec3 hillPos = p + vec3(6.0, 3.65, -20.0);
    hillPos.z = abs(hillPos.z-12.8)-12.8;
    //float d = length(hillPos * vec3(2.0, 1.0, 1.0)) / vec3(2.0,1.0,1.0) - 4.0;
    vec3 r = vec3(8.0, 4.0, 1.0);
    // Ellipse distance field
    float k0 = length(hillPos/r);
    float k1 = length(hillPos/(r*r));
    float d = k0*(k0-1.0)/k1;

    // Add noise and smooth blend it into the landscape.
    float noiseTemp = NoiseGen(hillPos.xz*2.0)*0.25;
    noiseTemp += NoiseGen(hillPos.xz*16.0)*0.0625*0.25;
    distAndMat.x = smin(distAndMat.x, d + noiseTemp, -2.2);

    // Set up the cars. This is doing a lot of mirroring and repeating because I
    // only want to do a single call to the car distance function for all the
    // cars in the scene. And there's a lot of traffic!
    vec3 p2 = p;
    rep.xyz = p2;
    float carTime = localTime*0.2;  // Speed of car driving
    float crossStreet = 1.0;  // whether we are north/south or east/west
    float repeatDist = 0.25;  // Car density bumper to bumper
    // If we are going north/south instead of east/west (?) make cars that are
    // stopped in the street so we don't have collisions.
    if (abs(fract(rep.x)-0.5) < 0.35)
    {
        p2.x += 0.05;
        p2.xz = p2.zx * vec2(-1.0,1.0);  // Rotate 90 degrees
        rep.xz = p2.xz;
        crossStreet = 0.0;
        repeatDist = 0.1;  // Denser traffic on cross streets
    }

    rep.z += floor(p2.x);	// shift so less repitition between parallel blocks
    rep.x = Repeat(p2.x - 0.5, 1.0);	// repeat every block
    rep.z = rep.z*sign(rep.x);	// mirror but keep cars facing the right way
    rep.x = (rep.x*sign(rep.x))-0.09;
    rep.z -= carTime * crossStreet;	// make cars move
    float uniqueID = floor(rep.z/repeatDist);	// each car gets a unique ID that we can use for colors
    rep.z = Repeat(rep.z, repeatDist);	// repeat the line of cars every quarter block
    rep.x += (Hash11(uniqueID)*0.075-0.01);	// nudge cars left and right to take both lanes
    float frontBack = Hash11(uniqueID*0.987)*0.18-0.09;
    frontBack *= sin(localTime*2.0 + uniqueID);
    rep.z += frontBack * crossStreet; // nudge cars forward back for variation
    float isBridge = 0.0;
    if ((p.x > -7.15) && (p.x < -6.85)){
        isBridge = 0.7;
        rep.y = origp.y;
    }
    vec2 carDist = Car(rep-vec3(0.0, isBridge, 0.0), uniqueID); // car distance function

    // Drop the cars in the scene with materials
    if ((blockHill < -parkHeight) && (pint.y < 15.0) || (isBridge > 0.0)) distAndMat = matmin(distAndMat, carDist);

    // ******************** Render the text ********************
    int startIndex = wordStarts[currentText];
    int len = wordLens[currentText];
    vec3 tp = currentTextPos[currentText];
    float rot = PI;
    if ((currentText >= 2)) rot = -PI * 0.5;
    distAndMat = matmin(distAndMat, Render3dText(p, tp, rot,
        startIndex, len, wordScales[currentText]));

    return distAndMat;
}

// This basically makes a procedural texture map for the sides of the buildings.
// It makes a texture, a normal for normal mapping, and a mask for window reflection.
void CalcWindows(vec2 block, vec3 pos, inout vec3 texColor, inout float windowRef, inout vec3 normal)
{
    bool pyramid =((block.x == 0.0) && (block.y == 1.0));

    vec3 hue = vec3(Hash21(block)*0.8, Hash21(block*7.89)*0.4, Hash21(block*37.89)*0.5);
    if (pyramid) hue = vec3(2.5, 1.6, 1.0)*0.8;
    texColor += hue*0.4;
    texColor *= 0.75;
    float window = 0.0;
    window = max(window, mix(0.2, 1.0, floor(fract(pos.y*20.0-0.35)*2.0+0.1)));
    if (pos.y < 0.05) window = 1.0;
    float winWidth = Hash21(block*4.321)*2.0;
    if (pyramid) winWidth = 1.0;
    if ((winWidth < 1.2) && (winWidth >= 1.0)) winWidth = 1.2;
    window = max(window, mix(0.2, 1.0, floor(fract(pos.x * 40.0+0.05)*winWidth)));
    window = max(window, mix(0.2, 1.0, floor(fract(pos.z * 40.0+0.05)*winWidth)));
    if (window < 0.5)
    {
        windowRef += 1.0;
    }
    if (!pyramid) window *= Hash21(block*1.123);
    texColor *= window;

    if (!pyramid) {
        float wave = floor(sin((pos.y*40.0-0.1)*PI)*0.505-0.5)+1.0;
        normal.y -= max(-1.0, min(1.0, -wave*0.5));
        float pits = min(1.0, abs(sin((pos.z*80.0)*PI))*4.0)-1.0;
        normal.z += pits*0.25;
        pits = min(1.0, abs(sin((pos.x*80.0)*PI))*4.0)-1.0;
        normal.x += pits*0.25;
    }
}

vec4 RayTraceBridgeTower(vec3 pos, vec3 dirVecN) {
    vec3 rayInv = 1.0 / dirVecN;
    vec4 rh = BoxIntersect(pos, rayInv, vec3(0.0, 1.135, 0.0), vec3(0.03, 2.27, 0.08)*0.5);
    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 1.135, 0.0), vec3(0.03, 2.27, 0.08)*0.5));

    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.6, 0.0), vec3(0.08, 1.2, 0.14)*0.5));
    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.6, 0.0), vec3(0.08, 1.2, 0.14)*0.5));

    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.775, 0.0), vec3(0.06, 1.55, 0.12)*0.5));
    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.775, 0.0), vec3(0.06, 1.55, 0.12)*0.5));

    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.95, 0.0), vec3(0.04, 1.9, 0.10)*0.5));
    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.95, 0.0), vec3(0.04, 1.9, 0.10)*0.5));

    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.325, 0.0), vec3(0.1, 0.65, 0.16)*0.5));
    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.325, 0.0), vec3(0.1, 0.65, 0.16)*0.5));
    return rh;
}

void MakeCables(inout vec4 cables, vec3 hitPos) {
    if ((hitPos.y > 2.3) || (hitPos.y < 0.65) || (abs(hitPos.z) > 12.8)) cables.w = farPlane;
    else {
        vec3 tempNormal = cables.xyz;
        float repz = Repeat(hitPos.z+6.4, 12.8);
        float base = hitPos.y - 0.75;
        float curve = 0.0365;
        bool isSmallCable = (abs(repz * repz) * curve) > base;
        float reps = Repeat(repz, 0.15);
        if (reps < 0.065) isSmallCable = false;
        bool isBigCable = abs((abs(repz * repz) * curve) - base) < 0.0125;
        float cablePosY = -((abs(repz * repz) * curve) - base)*50.0;
        if (isBigCable) tempNormal = normalize(tempNormal + vec3(0.0, cablePosY, 0.0));
        //tempNormal = vec3(0.0, -1.0, 0.0);
        if ((!isBigCable) && (!isSmallCable)) cables.w = farPlane;
        else cables.xyz = tempNormal;
    }
}

vec4 RayTraceGoldenGateBridge(vec3 pos, vec3 dirVecN) {
    vec3 rayInv = 1.0 / dirVecN;
    vec4 rh = BoxIntersect(pos, rayInv, vec3(0.0, 0.65, 0.0), vec3(0.27, 0.1, 25.6)*0.5);
    rh = Union(rh, RayTraceBridgeTower(pos + vec3(-0.15, 0.0, -6.4), dirVecN));
    rh = Union(rh, RayTraceBridgeTower(pos + vec3(0.15, 0.0, -6.4), dirVecN));

    rh = Union(rh, RayTraceBridgeTower(pos + vec3(-0.15, 0.0, 6.4), dirVecN));
    rh = Union(rh, RayTraceBridgeTower(pos + vec3(0.15, 0.0, 6.4), dirVecN));

    vec4 struts = PlaneIntersect(pos, dirVecN, vec3(0.0, 0, 1.0), vec3(-6.4));
    vec3 hitPos = pos + dirVecN * struts.w;
    if ((abs(hitPos.x) < 0.135) && (hitPos.y < 2.27) && (hitPos.y > 1.0)) {
        float repy = Repeat(hitPos.y, 0.35);
		if (repy < -0.05) rh = Union(rh, struts);
    }
    struts = PlaneIntersect(pos, dirVecN, vec3(0.0, 0, 1.0), vec3(6.4));
    hitPos = pos + dirVecN * struts.w;
    if ((abs(hitPos.x) < 0.135) && (hitPos.y < 2.27) && (hitPos.y > 1.0)) {
        float repy = Repeat(hitPos.y, 0.35);
		if (repy < -0.05) rh = Union(rh, struts);
    }
    hitPos = pos + dirVecN * rh.w;
    if (abs(rh.z) > 0.9) {
		rh.xyz = normalize(rh.xyz + vec3(abs(Repeat(hitPos.x, 0.05)), 0.0, 0.0)*75.0);
    }

    vec4 cables = PlaneIntersect(pos, dirVecN, vec3(1.0, 0.0, 0.0), vec3(0.135, 0.0, 0.0));
    hitPos = pos + dirVecN * cables.w;
    MakeCables(cables, hitPos);
    rh = Union(rh, cables);

    cables = PlaneIntersect(pos, dirVecN, vec3(1.0, 0.0, 0.0), vec3(-0.135, 0.0, 0.0));
    hitPos = pos + dirVecN * cables.w;
    MakeCables(cables, hitPos);
    rh = Union(rh, cables);

    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.0, -6.4), vec3(0.8, 0.1, 0.3)*0.5));
    rh = Union(rh, BoxIntersect(pos, rayInv, vec3(0.0, 0.0, 6.4), vec3(0.8, 0.1, 0.3)*0.5));

    return rh;
}

// Input is UV coordinate of pixel to render.
// Output is RGB color.
vec3 RayTrace(in vec2 fragCoord )
{
	// -------------------------------- animate ---------------------------------------
	sunDir = normalize(vec3(0.2, 1.0, 0.9));
    vec3 sunCol = vec3(250.0, 220.0, 200.0) / 155.0;
    vec3 horizonCol = vec3(0.75, 0.7, 0.85)*1.5;
    vec3 skyCol = vec3(0.02,0.45,1.0)*0.7;
	vec3 groundCol = vec3(0.8,0.75,0.67)*0.45;
    currentText = 0;
    float exposure = 1.0;

	vec3 camPos, camUp, camLookat;
    camUp = vec3(0,1,0);
	// ------------------- Set up the camera rays for ray marching --------------------
    // Map uv to [-1.0..1.0]
	vec2 uv = fragCoord.xy/iResolution.xy * 2.0 - 1.0;
    uv /= 2.0;  // zoom in

    // Do the camera fly-by animation and different scenes.
    // Time variables for start and end of each scene
    // Repeat the animation after time t6
    float keyEnd = keys[numKeyFrames - 1];
    localTime = fract(localTime / keyEnd) * keyEnd;// + keys[6];
    if (localTime < keys[1])
    {
        currentText = 0;
        float time = localTime - keys[0];
        exposure = saturate(time+0.1);
        float alpha = time / (keys[1] - keys[0]);
        camPos = vec3(7.0, 1.4, 27.5);
        camPos.x -= smoothstep(0.0, 1.0, alpha) * 11.5;
        camPos.z += smoothstep(0.0, 1.0, alpha) * 15.0;
        camUp=vec3(0,1,0);
        camLookat=vec3(-8,1.5,32.0);
    } else if (localTime < keys[2]) {
        currentText = 0;
        camPos = vec3(7.0, 1.4, 27.5);
        camPos.x -= 11.5;
        camPos.z += 15.0;
        camLookat=vec3(-8,1.5,32.0);
    } else if (localTime < keys[3]) {
        float time = localTime - keys[2];
        float alpha = time / (keys[3] - keys[2]);
        alpha = saturate(alpha*1.4);
        if (alpha > 0.33) currentText = 1;
        float salpha = smoothstep(0.0, 1.0, alpha);
        camPos = vec3(-4.5, 1.4, 42.5);
        camPos += vec3(2.0, -0.5, -23) * salpha;

        camLookat=vec3(-8,1.5,32.0);
        camLookat += vec3(8, -1.5, -24) * salpha;
    } else if (localTime < keys[4]) {
        currentText = 2;
        float time = localTime - keys[3];
        float alpha = time / (keys[4] - keys[3]);
        alpha = saturate(alpha*1.4);
        float salpha = smoothstep(0.0, 1.0, alpha);
        camPos = vec3(2, 2.3, 2.5);
        camPos += vec3(0, 2.0, -2.1) * salpha;
        camLookat=vec3(0.5,3.2,1.5);
        camLookat.y += 1.0 * salpha;
    } else if (localTime < keys[5]) {
        currentText = 3;
        float time = localTime - keys[4];
        float alpha = time / (keys[5] - keys[4]);
        alpha = saturate(alpha*1.4);
        float salpha = smoothstep(0.0, 1.0, alpha);
        camPos = vec3(21, 0.1, 1.5);
        camPos += vec3(-3.6, 0.6, 1.0) * salpha;
        camLookat=vec3(0.5,3.2,1.5);
        sunDir = normalize(vec3(3,1,1));
    } else if (localTime < keys[6]) {
        currentText = 4;
        float time = localTime - keys[5];
        float alpha = time / (keys[6] - keys[5]);
        alpha = saturate(alpha*1.4);
        float salpha = smoothstep(0.0, 1.0, alpha);
        camPos = vec3(14.5, 0.3, 1.0);
        camPos += vec3(-2.97, 0.4, -0.1) * salpha;
        camLookat=vec3(0.5,0.2,1.0);
        sunDir = normalize(vec3(1.3,1,1.1));
    } else if (localTime < keys[7]) {
        currentText = 5;
        float time = localTime - keys[6];
        float alpha = time / (keys[7] - keys[6]);
        alpha = saturate(alpha*1.7);
        float salpha = smoothstep(0.0, 1.0, alpha);
        camPos = vec3(12.0, 0.5, 32.7);
        camPos += vec3(-11.0, 0.0, 0.0) * salpha;
        camLookat=vec3(-10.5,0.2,32.7);

        sunDir = normalize(vec3(-10.95, -1.3, 0.1));
        sunCol = vec3(258.0, 60.0, 10.0) / 35.0;
        exposure *= 0.2;
        horizonCol = vec3(1.0, 0.25, 0.08)*1.95;
        skyCol = vec3(0.15,0.5,0.95);
    }
#ifdef MANUAL_CAMERA
    if (length(iMouse.xy) > 10.0) {
        // Camera up vector.
        camUp=vec3(0,1,0);

        // Camera lookat.
        camLookat=vec3(0.0,0.0,12.0);

        // debugging camera
        float mx=-iMouse.x/iResolution.x*PI*2.0;// + localTime * 0.05;
        float my=iMouse.y/iResolution.y*3.14*0.5 + PI/2.0;// + sin(localTime * 0.3)*0.8+0.1;//*PI/2.01;
        camPos = camLookat + vec3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*8.0;
    }
#endif

	// Camera setup for ray tracing / marching
	vec3 camVec=normalize(camLookat - camPos);
	vec3 sideNorm=normalize(cross(camUp, camVec));
	vec3 upNorm=cross(camVec, sideNorm);
	vec3 worldFacing=(camPos + camVec);
	vec3 worldPix = worldFacing + uv.x * sideNorm * (iResolution.x/iResolution.y) + uv.y * upNorm;
	vec3 rayVec = normalize(worldPix - camPos);

	// ----------------------------- Ray march the scene ------------------------------
	vec2 distAndMat;  // Distance and material
	float t = 0.05;// + Hash2d(uv)*0.1;	// random dither-fade things close to the camera
	float maxDepth = 55.0; // farthest distance rays will travel
	vec3 pos = vec3(0.0);
    const float smallVal = 0.000625;

    int rtMaterial = 0;
	vec4 rh = RayTraceGoldenGateBridge(camPos + vec3(7.0, 0.0, -32.7), rayVec);

    if (rh.w < maxDepth) {
        maxDepth = min(maxDepth, rh.w);
        rtMaterial = 1;
    }
    vec4 waterPlane = PlaneIntersect(camPos, rayVec, vec3(0.0, 1.0, 0.0), vec3(0.0));
    rh = Union(rh, waterPlane);
    if ((waterPlane.w == rh.w) && (waterPlane.w < farPlane)) {
        rtMaterial = 2;
        maxDepth = min(maxDepth, rh.w);
    }

    // ray marching time
    for (int i = 0; i < 250; i++)	// This is the count of the max times the ray actually marches.
    {
        // Step along the ray.
        pos = (camPos + rayVec * t);
        // This is _the_ function that defines the "distance field".
        // It's really what makes the scene geometry. The idea is that the
        // distance field returns the distance to the closest object, and then
        // we know we are safe to "march" along the ray by that much distance
        // without hitting anything. We repeat this until we get really close
        // and then break because we have effectively hit the object.
        distAndMat = DistanceToObject(pos);

        // 2d voxel walk through the city blocks.
        // The distance function is not continuous at city block boundaries,
        // so we have to pause our ray march at each voxel boundary.
        float walk = distAndMat.x;
        float dx = -fract(pos.x);
        if (rayVec.x > 0.0) dx = fract(-pos.x);
        float dz = -fract(pos.z);
        if (rayVec.z > 0.0) dz = fract(-pos.z);
        float nearestVoxel = min(fract(dx/rayVec.x), fract(dz/rayVec.z))+voxelPad;
        nearestVoxel = max(voxelPad, nearestVoxel);// hack that assumes streets and sidewalks are this wide.
        //nearestVoxel = max(nearestVoxel, t * 0.02); // hack to stop voxel walking in the distance.
        walk = min(walk, nearestVoxel);

        // move down the ray a safe amount
        t += walk;
        // If we are very close to the object, let's call it a hit and exit this loop.
        if ((t > maxDepth) || (abs(distAndMat.x) < smallVal)) break;
    }
    
    // Combine ry tracing and ray marching results.
    if (abs(distAndMat.x) < smallVal) rtMaterial = 0;
    else {
        t = rh.w;
        pos = camPos + rayVec * t;
    } 

	// --------------------------------------------------------------------------------
	// Now that we have done our ray marching, let's put some color on this geometry.
	vec3 finalColor = vec3(0.0);

	// If a ray actually hit the object, let's light it.
    if ((t <= maxDepth) || (rtMaterial > 0))
	{
        float dist = distAndMat.x;
        // calculate the normal from the distance field. The distance field is a volume, so if you
        // sample the current point and neighboring points, you can use the difference to get
        // the normal.
        vec3 smallVec = vec3(smallVal, 0, 0);
/*        vec3 normalU = vec3(dist - DistanceToObject(pos - smallVec.xyy).x,
                           dist - DistanceToObject(pos - smallVec.yxy).x,
                           dist - DistanceToObject(pos - smallVec.yyx).x);
        vec3 normal = normalize(normalU);*/
        vec3 normalU = vec3(0.0);
        for( int i=min(0,iFrame); i<4; i++ )
        {
            vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
            normalU += e*DistanceToObject(pos+0.0005*e).x;
        }

        vec3 normal = normalize(normalU);
        if (rtMaterial > 0) normal = rh.xyz;

        // calculate ambient occlusion.
        float ff = 0.0125;
        float aa = 80.0;
        float ambient = 1.0;
        for( int i=min(0,iFrame); i<6; i++ )
        {
            ambient *= saturate(DistanceToObject(pos + normal * ff).x*aa);
            ff *= 2.0;
            aa /= 2.0;
        }

/*        float ambient = 1.0;
        ambient *= saturate(DistanceToObject(pos + normal * 0.0125).x*80.0);
        ambient *= saturate(DistanceToObject(pos + normal * 0.025).x*40.0);
        ambient *= saturate(DistanceToObject(pos + normal * 0.05).x*20.0);
        ambient *= saturate(DistanceToObject(pos + normal * 0.1).x*10.0);
        ambient *= saturate(DistanceToObject(pos + normal * 0.2).x*5.0);
        ambient *= saturate(DistanceToObject(pos + normal * 0.4).x*2.5);*/
        ambient = max(0.025, pow(ambient, 0.5));	// tone down ambient with a pow and min clamp it.
        ambient = saturate(ambient);
        float ambientAvg = ambient;// (ambient*3.0 + ambientS) * 0.25;

        // calculate the reflection vector for highlights
        vec3 ref = reflect(rayVec, normal);

        // Trace a ray toward the sun for sun shadows
        float sunShadow = 1.0;
        if (length(pos.xz) < 20.0) {
            float iter = 0.01;
            vec3 nudgePos = pos + normal*0.002;	// don't start tracing too close or inside the object
            for (int i = 0; i < 40; i++)
            {
                vec3 shadowPos = nudgePos + sunDir * iter;
                float tempDist = DistanceToObject(shadowPos).x;
                sunShadow *= saturate(tempDist*150.0);	// Shadow hardness
                if (tempDist <= 0.0) break;

                float walk = tempDist;
                float dx = -fract(shadowPos.x);
                if (sunDir.x > 0.0) dx = fract(-shadowPos.x);
                float dz = -fract(shadowPos.z);
                if (sunDir.z > 0.0) dz = fract(-shadowPos.z);
                float nearestVoxel = min(fract(dx/sunDir.x), fract(dz/sunDir.z))+smallVal;
                nearestVoxel = max(0.2, nearestVoxel);// hack that assumes streets and sidewalks are this wide.
                walk = min(walk, nearestVoxel);

                iter += max(0.01, walk);
                if (iter > 4.5) break;
            }
            sunShadow = saturate(sunShadow);
        	// Raytraced shadows
			//vec4 rhs = RayTraceGoldenGateBridge(nudgePos + vec3(7.0, 0.0, -32.7), sunDir);
        	//if (rhs.w < farPlane) sunShadow = 0.0;
        }

        // make a few frequencies of noise to give it some texture
        float n =0.0;
        n += noise2d(pos.xz*32.0);
        n += noise2d(pos.xz*64.0);
        n += noise(fract(pos)*128.0);
        n += noise(fract(pos)*256.0);
        n += noise(fract(pos)*512.0);
        n = mix(0.7, 0.95, n);

        // ------ Calculate texture color  ------
    	float posHilly = Hills(pos);
        vec2 block = floor(pos.xz);
        vec3 texColor = vec3(0.95, 1.0, 1.0);
        texColor *= 0.8;
        float windowRef = 0.0;
        // texture map the sides of buildings
        if ((normal.y < 0.1) && (distAndMat.y == 0.0))
        {
            vec3 posdx = dFdx(pos);
            vec3 posdy = dFdy(pos);
            vec3 posGrad = posdx * Hash21(uv) + posdy * Hash21(uv*7.6543);

            // Quincunx antialias the building texture and normal map.
            // I guess procedural textures are hard to mipmap.
            vec3 colTotal = vec3(0.0);
            vec3 colTemp = texColor;
            vec3 nTemp = vec3(0.0);
            CalcWindows(block, pos, colTemp, windowRef, nTemp);
            colTotal = colTemp;

            colTemp = texColor;
            CalcWindows(block, pos + posdx * 0.666, colTemp, windowRef, nTemp);
            colTotal += colTemp;

            colTemp = texColor;
            CalcWindows(block, pos + posdx * 0.666 + posdy * 0.666, colTemp, windowRef, nTemp);
            colTotal += colTemp;

            colTemp = texColor;
            CalcWindows(block, pos + posdy * 0.666, colTemp, windowRef, nTemp);
            colTotal += colTemp;

            colTemp = texColor;
            CalcWindows(block, pos + posdx * 0.333 + posdy * 0.333, colTemp, windowRef, nTemp);
            colTotal += colTemp;

            texColor = colTotal * 0.2;
            windowRef *= 0.2;

            normal = normalize(normal + nTemp * 0.2);
        }
        else
        {
            // Draw the road
            float xroad = abs(fract(pos.x+0.5)-0.5);
            float zroad = abs(fract(pos.z+0.5)-0.5);
            float road = saturate((min(xroad, zroad)-0.143)*480.0);
            texColor *= 1.0-normal.y*0.95*Hash21(block*9.87)*road; // change rooftop color
            texColor *= mix(0.1, 1.0, road);

            // double yellow line in middle of road
            float yellowLine = saturate(1.0-(min(xroad, zroad)-0.002)*480.0);
            yellowLine *= saturate((min(xroad, zroad)-0.0005)*480.0);
            yellowLine *= saturate((xroad*xroad+zroad*zroad-0.05)*880.0);
            texColor = mix(texColor, vec3(1.0, 0.8, 0.3), yellowLine);

            // white dashed lines on road
            float whiteLine = saturate(1.0-(min(xroad, zroad)-0.06)*480.0);
            whiteLine *= saturate((min(xroad, zroad)-0.056)*480.0);
            whiteLine *= saturate((xroad*xroad+zroad*zroad-0.05)*880.0);
            whiteLine *= saturate(1.0-(fract(zroad*8.0)-0.5)*280.0);  // dotted line
            whiteLine *= saturate(1.0-(fract(xroad*8.0)-0.5)*280.0);
            texColor = mix(texColor, vec3(0.5), whiteLine);

            whiteLine = saturate(1.0-(min(xroad, zroad)-0.11)*480.0);
            whiteLine *= saturate((min(xroad, zroad)-0.106)*480.0);
            whiteLine *= saturate((xroad*xroad+zroad*zroad-0.06)*880.0);
            texColor = mix(texColor, vec3(0.5), whiteLine);

            // crosswalk
            float crossWalk = saturate(1.0-(fract(xroad*40.0)-0.5)*280.0);
            crossWalk *= saturate((zroad-0.15)*880.0);
            crossWalk *= saturate((-zroad+0.21)*880.0)*(1.0-road);
            crossWalk *= n*n;
            texColor = mix(texColor, vec3(0.25), crossWalk);
            crossWalk = saturate(1.0-(fract(zroad*40.0)-0.5)*280.0);
            crossWalk *= saturate((xroad-0.15)*880.0);
            crossWalk *= saturate((-xroad+0.21)*880.0)*(1.0-road);
            crossWalk *= n*n;
            texColor = mix(texColor, vec3(0.25), crossWalk);

            {
                // sidewalk cracks
                float sidewalk = 1.0;
                vec2 blockSize = vec2(100.0);
                if (posHilly > 0.1) blockSize = vec2(10.0, 50);
                //sidewalk *= pow(abs(sin(pos.x*blockSize)), 0.025);
                //sidewalk *= pow(abs(sin(pos.z*blockSize)), 0.025);
                sidewalk *= saturate(abs(sin(pos.z*blockSize.x)*800.0/blockSize.x));
                sidewalk *= saturate(abs(sin(pos.x*blockSize.y)*800.0/blockSize.y));
                sidewalk = saturate(mix(0.7, 1.0, sidewalk));
                sidewalk = saturate((1.0-road) + sidewalk);
                texColor *= sidewalk;
            }
        }
        // Car tires are almost black to not call attention to their ugly.
        if (distAndMat.y == 3.0)
        {
            texColor = vec3(0.05);
        }

        // apply noise
        texColor *= vec3(1.0)*n;//*0.05;
        texColor *= 0.7;
        texColor = saturate(texColor);

        float windowMask = 0.0;
        if (distAndMat.y >= 100.0)
        {
            // car texture and windows
            texColor = vec3(Hash11(distAndMat.y)*1.0, Hash11(distAndMat.y*8.765), Hash11(distAndMat.y*17.731))*0.1;
            texColor = pow(abs(texColor), vec3(0.2));  // bias toward white
            texColor = max(vec3(0.25), texColor);  // not too saturated color.
            texColor.z = min(texColor.y, texColor.z);  // no purple cars. just not realistic. :)
            texColor *= Hash11(distAndMat.y*0.789) * 0.15;
            windowMask = saturate( max(0.0, abs(posHilly - 0.0175)*3800.0)-10.0);
            vec2 dirNorm = abs(normalize(normal.xz));
            float pillars = saturate(1.0-max(dirNorm.x, dirNorm.y));
            pillars = pow(max(0.0, pillars-0.15), 0.125);
            windowMask = max(windowMask, pillars);
            texColor *= windowMask;
            texColor *= 10.0;
            //if (normal.x > .995) texColor = vec3(0.02);
        } else
        // Parks, beach
        if (distAndMat.y == 4.0) {
            vec3 grassCol = vec3(0.45, 0.7, 0.3)*0.345;
            vec3 dirtCol = vec3(1.0, 0.8, 0.5)*0.46;
            texColor = mix(dirtCol, grassCol, saturate(n-0.4));
            dirtCol = vec3(1.3, 0.45, 0.2)*0.1;
            texColor = mix(dirtCol, texColor, saturate(normal.y*normal.y*normal.y*normal.y));
            //texColor = mix(vec3(0.35, 0.32, 0.3), grassCol, saturate(normal.y-0.4));
            // Fade to beach
            vec3 beachCol = vec3(1.0, 0.85, 0.7)*0.3*(n+0.8);
            texColor = mix(texColor, beachCol, saturate((0.015-pos.y)*200.0));
            //if (pos.y < 0.003) texColor = vec3(1.0, 0.9, 0.8)*0.04;
        } else if (distAndMat.y == 5.0) {
            // Letters
            texColor = mix(vec3(0.97, 0.2, 0.1), vec3(1.0, 1.0, 0.1), abs(normal.z));
        }

        // Golden Gate Bridge
        if (rtMaterial == 1) {
	        if (rtMaterial > 0) normal = rh.xyz;
            float bridgeX = 7.0;
            texColor = vec3(1.0, 0.2, 0.1)*0.6;
            ambient = 1.0;
            if (pos.y < 0.125) texColor = vec3(0.55, 0.4, 0.3)*0.5*n*saturate(pos.y*10.0);
            if ((pos.y > 0.62) && (pos.y < 0.68) && (abs(pos.x+bridgeX) < 0.14)) {
                texColor = mix(texColor, texColor * 0.2, saturate((abs(Repeat(pos.z, 0.15))-0.02) * 30.0));
            }
            if ((pos.y > 0.68) && (pos.y < 0.72) && (abs(pos.x+bridgeX) < 0.128) && (normal.y == 1.0)) {
                // Road pavement on bridge
                texColor = vec3(0.1);

                float xroad = abs(fract(pos.x+bridgeX+0.5)-0.5);
                float zroad = abs(fract(pos.z+0.5)-0.5);
                //float road = saturate((min(xroad, zroad)-0.143)*480.0);
                // double yellow line in middle of road
                float yellowLine = saturate(1.0-(xroad-0.002)*480.0);
                yellowLine *= saturate((xroad-0.0005)*480.0);
                //yellowLine *= saturate((xroad*xroad+zroad*zroad-0.05)*880.0);
                texColor = mix(texColor, vec3(1.0, 0.8, 0.3), yellowLine);

                // white dashed lines on road
                float whiteLine = saturate(1.0-(xroad-0.06)*480.0);
                whiteLine *= saturate((xroad-0.056)*480.0);
                whiteLine *= saturate(1.0-(fract(zroad*8.0)-0.5)*280.0);  // dotted line
                //whiteLine *= saturate(1.0-(fract(xroad*8.0)-0.5)*280.0);
                texColor = mix(texColor, vec3(0.45), whiteLine);

                whiteLine = saturate(1.0-(xroad-0.11)*480.0);
                whiteLine *= saturate((xroad-0.106)*480.0);
                texColor = mix(texColor, vec3(0.5), whiteLine);
                texColor *= vec3(0.7)*n;
                texColor = saturate(texColor);
            }
        }

        // ------ Calculate lighting color ------
        // Start with sun color, standard lighting equation, and shadow
        vec3 lightColor = (sunCol * saturate(dot(normal, sunDir))) * sunShadow;
        // Add sky color with ambient acclusion
        lightColor += (skyCol * saturate(normal.y *0.5+0.5))*pow(ambientAvg, 0.35)*0.35;
        // Ground light
        lightColor += (groundCol * saturate(-normal.y *0.5+0.5)) * 0.25 * ambientAvg;

        // finally, apply the light to the texture.
        finalColor = texColor * lightColor;
        // Reflections for cars
        if ((distAndMat.y >= 100.0) && (rtMaterial == 0))
        {
            float yfade = max(0.01, min(1.0, ref.y*100.0));
            // low-res way of making lines at the edges of car windows. Not sure I like it.
            yfade *= (saturate(1.0-abs(dFdx(windowMask)*dFdy(windowMask))*250.995));
            finalColor += GetEnvMapSkyline(ref, sunDir, posHilly-1.5, sunCol, horizonCol, skyCol)*
                0.3*yfade*max(0.4,sunShadow);
            finalColor += saturate(texture(iChannel0, ref).xyz-0.35)*0.15*max(0.2,sunShadow);
        }
        // reflections for building windows
        if ((windowRef != 0.0) && (rtMaterial == 0))
        {
            finalColor *= mix(1.0, 0.6, windowRef);
            float yfade = max(0.01, min(1.0, ref.y*100.0));
            finalColor += GetEnvMapSkyline(ref, sunDir, posHilly-0.5, sunCol, horizonCol, skyCol)
                *0.6*yfade*max(0.6,sunShadow)*windowRef;//*(windowMask*0.5+0.5);
            finalColor += saturate(texture(iChannel0, ref).xyz-0.35)*0.15*max(0.25,sunShadow)*windowRef;
        }
        // water
        if ((pos.y <= 0.001f) || (rtMaterial == 2)) {
            if (rtMaterial == 2){
                pos.y = -10.1f;
                //finalColor = vec3(0.0);
            }
            /*float waterNoise = noise2d(pos.xz*4.0+localTime)*0.1 +
                noise2d(pos.xz*8.0+localTime)*0.03 +
                noise2d(pos.xz*16.0-localTime)*0.015 +
                noise2d(pos.xz*32.0-localTime)*0.005 +
                noise2d(pos.xz*64.0-localTime)*0.002;
            // Fade the waves a bit in the distance.
            float r = dot(pos.xz, pos.xz);
            waterNoise = waterNoise * saturate(1.0/(r));
            vec3 dx = vec3(1.0, dFdx(waterNoise)*8000.0, 0.0);
            vec3 dy = vec3(0.0, dFdy(waterNoise)*8000.0, 1.0);
            normal = -cross(dx, dy);*/

            vec2 sp = pos.xz * 2.0;
            vec2 waterNoise = NoiseTex(vec3(sp.x*32.0, sp.y*32.0 + localTime, localTime))*0.125;
            waterNoise += NoiseTex(vec3(sp.x*16.0 + localTime, sp.y*16.0, localTime+0.2))*0.25;
            waterNoise += NoiseTex(vec3(sp.x*8.0, sp.y*8.0 - localTime, localTime+0.4))*0.5;
            waterNoise += NoiseTex(vec3(sp.x*4.0 - localTime, sp.y*4.0, localTime+0.6));
	        ref = reflect(rayVec, normalize(normal + vec3(waterNoise.x, 0.0, waterNoise.y)* 0.4));
            ref.y = abs(ref.y);

            // This make the water either reflect or refract with the right amount
            // Schlick's approximation
            float oneMinusCos = 1.0 - saturate(dot(rayVec, -normal));
            float fresnel = 0.02;  // reflectance
            float reflectProb = fresnel + (1.0-fresnel) * pow(oneMinusCos, 5.0);

            float waterDepth = saturate(1.0+pos.y*256.0);
            vec3 waterColor = mix(vec3(0.025, 0.35, 0.1)*0.2 * lightColor, finalColor, waterDepth);
            vec3 env = GetEnvMapSimple(ref, sunDir, sunCol, horizonCol, skyCol);
            float bridgeX = 7.0;
			vec4 rh = BoxIntersect(pos, 1.0/normalize(ref), -vec3(7.0, 10.0, -32.7+6.4), vec3(0.3, 1.55*2.0, 0.1));
			rh = Union(rh, BoxIntersect(pos, 1.0/normalize(ref), -vec3(7.0, 10.0, -32.7-6.4), vec3(0.3, 1.55*2.0, 0.1)));
			rh = Union(rh, BoxIntersect(pos, 1.0/normalize(ref), -vec3(7.0, 9.3, -32.7), vec3(0.2, 0.1, 32.7)));
            if (rh.w < farPlane) env *= vec3(0.3, 0.15, 0.15);
            waterColor = mix(waterColor*0.75, env, reflectProb);
        	finalColor = mix(finalColor, waterColor, saturate((0.0-pos.y)*2048.0));
        }
        // fog
        vec3 rv2 = rayVec;
        rv2.y *= saturate(sign(rv2.y));
        vec3 fogColor = groundCol*0.7 + horizonCol * 0.3;
        fogColor = min(vec3(9.0), fogColor);
        finalColor = mix(fogColor, finalColor, exp(-t*0.013));

        // visualize length of gradient of distance field to check distance field correctness
        //finalColor = vec3(0.5) * (length(normalU) / smallVec.x);
        //finalColor = normal * 0.5 + 0.5;
        //finalColor = vec3(ambientAvg)*0.7;
	}
    else
    {
        // Our ray trace hit nothing, so draw sky.
        finalColor = GetEnvMap(rayVec, sunDir, sunCol, groundCol, horizonCol, skyCol);
    }

    // vignette FTW
    finalColor *= vec3(1.0) * saturate(1.0 - length(uv/1.3));
    finalColor *= 1.3*exposure;

	// output the final color without gamma correction - will do gamma later.
	return vec3(clamp(finalColor, 0.0, 1.0));
}

#ifdef NON_REALTIME_HQ_RENDER
// This function breaks the image down into blocks and scans
// through them, rendering 1 block at a time. It's for non-
// realtime things that take a long time to render.

// This is the frame rate to render at. Too fast and you will
// miss some blocks.
const float blockRate = 20.0;
void BlockRender(in vec2 fragCoord)
{
    // blockSize is how much it will try to render in 1 frame.
    // adjust this smaller for more complex scenes, bigger for
    // faster render times.
    const float blockSize = 64.0;
    // Make the block repeatedly scan across the image based on time.
    float frame = floor(iTime * blockRate);
    vec2 blockRes = floor(iResolution.xy / blockSize) + vec2(1.0);
    // ugly bug with mod.
    //float blockX = mod(frame, blockRes.x);
    float blockX = fract(frame / blockRes.x) * blockRes.x;
    //float blockY = mod(floor(frame / blockRes.x), blockRes.y);
    float blockY = fract(floor(frame / blockRes.x) / blockRes.y) * blockRes.y;
    // Don't draw anything outside the current block.
    if ((fragCoord.x - blockX * blockSize >= blockSize) ||
    	(fragCoord.x - (blockX - 1.0) * blockSize < blockSize) ||
    	(fragCoord.y - blockY * blockSize >= blockSize) ||
    	(fragCoord.y - (blockY - 1.0) * blockSize < blockSize))
    {
        discard;
    }
}
#endif

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
#ifdef NON_REALTIME_HQ_RENDER
    // Optionally render a non-realtime scene with high quality
    BlockRender(fragCoord);
#endif

    // Do a multi-pass render
    vec3 finalColor = vec3(0.0);
#ifdef NON_REALTIME_HQ_RENDER
    for (float i = 0.0; i < antialiasingSamples; i++)
    {
        const float motionBlurLengthInSeconds = 1.0 / 60.0;
        // Set this to the time in seconds of the frame to render.
	    localTime = frameToRenderHQ;
        // This line will motion-blur the renders
        localTime += Hash11(v21(fragCoord + seed)) * motionBlurLengthInSeconds;
        // Jitter the pixel position so we get antialiasing when we do multiple passes.
        vec2 jittered = fragCoord.xy + vec2(
            Hash21(fragCoord + seed),
            Hash21(fragCoord*7.234567 + seed)
            );
        // don't antialias if only 1 sample.
        if (antialiasingSamples == 1.0) jittered = fragCoord;
        // Accumulate one pass of raytracing into our pixel value
	    finalColor += RayTrace(jittered);
        // Change the random seed for each pass.
	    seed *= 1.01234567;
    }
    // Average all accumulated pixel intensities
    finalColor /= antialiasingSamples;
#else
    // Regular real-time rendering
    localTime = iTime;
    finalColor = RayTrace(fragCoord);
#endif

    fragColor = vec4(sqrt(clamp(finalColor, 0.0, 1.0)),1.0);
}


