// Common (common) — Magic forest by Alpaga
// https://www.shadertoy.com/view/dtX3zl

// Hash function from Dave_Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p3) {
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}
vec3 hash32(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}
float noise12(vec2 p) {
    vec2 fl = floor(p);
    vec2 fr = fract(p);
    fr = fr*fr*(3.-2.*fr);
    return mix(
        mix(hash12(fl),hash12(fl+vec2(1,0)),fr.x),
        mix(hash12(fl+vec2(0,1)),hash12(fl+vec2(1,1)),fr.x),fr.y);
}
float noise13(vec3 p) {
    const vec2 u = vec2(1,0);
    vec3 q = floor(p);
    vec3 r = fract(p);
    return mix(
            mix(
                mix(hash13(q+u.yyy),hash13(q+u.xyy),r.x),
                mix(hash13(q+u.yxy),hash13(q+u.xxy),r.x),
                r.y),
            mix(mix(hash13(q+u.yyx),hash13(q+u.xyx),r.x),
                mix(hash13(q+u.yxx),hash13(q+u.xxx),r.x),
                r.y),r.z);
}
// Noise varying continuously with time
float noise12(vec2 id, float t) {
    vec2 h = hash22(id);
    t = 3.*h.y*t+h.x;
    
    vec3 q = vec3(id,t);
    return noise13(q);
}