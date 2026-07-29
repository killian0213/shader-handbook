// Common (common) — Cube Falls by mhnewman
// https://www.shadertoy.com/view/dtSGWd

// Time in seconds between switching scenes
// Set to 0 for switching scenes on mouse clicks
#define SCENE_TIME 4

// Iterations per frame
// Set to 0 for accumulation over multiple frames
#define LIVE_ITER 0

//#define REDUCED_COLOR_PALETTE

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


float noise1(float p) {
    float i = floor(p);
    float f = fract(p);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash1(i), hash1(i + 1.0), u);
}

float noise1(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash1(i + vec2(0.0, 0.0)), 
                   hash1(i + vec2(1.0, 0.0)), u.x),
               mix(hash1(i + vec2(0.0, 1.0)), 
                   hash1(i + vec2(1.0, 1.0)), u.x), u.y);
}


float fbm1(float p) {
    float f = noise1(p) - 0.5; p = 2.0 * p;
    f += 0.5 * (noise1(p) - 0.5); p = 2.0 * p;
    f += 0.25 * (noise1(p) - 0.5); p = 2.0 * p;
    f += 0.125 * (noise1(p) - 0.5);
    return f / 1.875;
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



