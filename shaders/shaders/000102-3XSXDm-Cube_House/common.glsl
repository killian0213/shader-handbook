// Common (common) — Cube House by mhnewman
// https://www.shadertoy.com/view/3XSXDm

// Time in seconds between switching scenes
// Set to 0 for switching scenes on mouse clicks
#define SCENE_TIME 4

// Iterations per frame
// Set to 0 for accumulation over multiple frames
#define LIVE_ITER 0

// Shading iterations per frame
// 0 will do one iteration but not reflect sunlight
// Setting greater than 0 allows reflected sunlight
#define REFLECT_SUN_ITER 0


const float floorLimit = 3.0;
const float maxGroundCube = 6.0;
const float chanceForDoubleWindow = 0.6;
const float chanceForChimney = 0.9;
const float chanceForPatio = 0.9;
const float chanceForPool = 0.4;
const float chanceForTree = 0.0;
const float maxHeight = 71.0;

const float sunSize = 0.1;
const vec3 sunDir = normalize(vec3(-5.0, 2.0, 3.0));
const vec3 sunColor = vec3(0.5, 0.35, 0.2);
const vec3 ambientColor = vec3(0.5, 0.65, 0.8);

#define range(a, b) mix(a, b, hash1(h += 0.001))
#define rangesq(a, b) mix(a, b, pow(hash1(h += 0.001), 2.0))
#define frange(a, b) floor(mix(a, b, hash1(h += 0.001)))
#define writeHSV(loc, hue, sat, val) \
    color = vec3(hue, sat, val); \
    if (fragCoord.y < loc) return vec4(color, 0.0);
#define writeOffsetHSV(loc, hue, sat, val) \
    color = baseColor + vec3(hue, sat, val); \
    if (fragCoord.y < loc) return vec4(color, 0.0);
#define readHSV(loc) \
    texture(iChannel0, (vec2(1.0, loc) - 0.5) / iResolution.xy).rgb
const float heightLoc = 2.0;
const float frameLoc = 3.0;
const float wallLoc = 4.0;
const float windowFrameLoc = 5.0;
const float windowLoc = 6.0;
const float roofLoc1 = 7.0;
const float roofLoc2 = 8.0;
const float chimneyLoc1 = 9.0;
const float chimneyLoc2 = 10.0;
const float capLoc = 11.0;
const float foundationLoc1 = 12.0;
const float foundationLoc2 = 13.0;
const float deckLoc1 = 14.0;
const float deckLoc2 = 15.0;
const float tileLoc1 = 16.0;
const float tileLoc2 = 17.0;
const float waterLoc = 18.0;
const float dirtLoc = 19.0;
const float groundLoc1 = 20.0;
const float groundLoc2 = 21.0;

const float foundationIndex = -1.0;
const float chimneyIndex = -2.0;
const float capIndex = -3.0;
const float tileIndex = -4.0;
const float waterIndex = -5.0;
const float dirtIndex = -6.0;


vec3 hsv2rgb(vec3 hsv) {
    vec3 rgb = clamp(abs(mod(hsv.x + vec3(6.0, 10.0, 8.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return hsv.z * mix(vec3(1.0), rgb, hsv.y);
}

float hash1(float p) {
	vec2 p2 = fract(p * vec2(5.3983, 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}

float hash1(vec2 p2) {
    p2 = fract(p2 * vec2(5.3983, 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
    return fract(p2.x * p2.y * 95.4337);
}

float hash1(vec3 p3) {
    p3 = fract(p3 * vec3(5.3983, 5.4427, 6.9371));
    p3 += dot(p3, p3.yxz + 19.19);
    return fract(p3.x * p3.y * p3.z);
}

float hash1(vec4 p4) {
    p4 = fract(p4 * vec4(5.3983, 5.4427, 6.9371, 5.8815));
    p4 += dot(p4.zwxy, p4.xyzw + vec4(21.5351, 14.3137, 15.3219, 19.6285));
	return fract(p4.x * p4.y + p4.z * p4.w);
}

vec2 hash2(float p) {
    vec3 p3 = fract(vec3(p) * vec3(5.3983, 5.4427, 6.9371));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec2 hash2(vec3 p3) {
	p3 = fract(p3 * vec3(5.3983, 5.4427, 6.9371));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec4 hash4(float p) {
    vec4 p4 = fract(vec4(p) * vec4(5.3983, 5.4427, 6.9371, 7.1283));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 hash4(vec2 p) {
    vec4 p4 = fract(vec4(p.xyxy) * vec4(5.3983, 5.4427, 6.9371, 7.1283));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 hash4(vec3 p) {
    vec4 p4 = fract(vec4(p.xyzx) * vec4(5.3983, 5.4427, 6.9371, 7.1283));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

float noise1(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash1(i + vec2(0.0, 0.0)), 
                   hash1(i + vec2(1.0, 0.0)), u.x),
               mix(hash1(i + vec2(0.0, 1.0)), 
                   hash1(i + vec2(1.0, 1.0)), u.x), u.y) * 2.0 - 1.0;
}

const mat2 m = mat2(1.616, 1.212, -1.212, 1.616);

float fbm1(vec2 p) {
    float f = noise1(p) - 0.5; p = m * p;
    f += 0.5 * (noise1(p) - 0.5); p = m * p;
    f += 0.25 * (noise1(p) - 0.5); p = m * p;
    f += 0.125 * (noise1(p) - 0.5); p = m * p;
    f += 0.0625 * (noise1(p) - 0.5);
    return f / 1.9375;
}
