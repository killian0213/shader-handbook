// Common (common) — Cube Castle by mhnewman
// https://www.shadertoy.com/view/DtBGzt

const float blockSize = 4.0;
const float blockHeight = 5.0;
const float maxFloor = 7.0;

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