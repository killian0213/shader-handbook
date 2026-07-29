// Common (common) — Volume Box by TDM
// https://www.shadertoy.com/view/XlBSDW

vec3 saturation(vec3 c, float t) {
    return mix(vec3(dot(c,vec3(0.2126,0.7152,0.0722))),c,t);
}
mat3 fromEuler(vec3 ang) {
	vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
	m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
	m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
	return m;
}
bool intersectionRayBox(vec3 o, vec3 d, vec3 ext, out vec3 r0, out vec3 r1) {
    vec3 t0 = (-o - ext) / d; 
    vec3 t1 = (-o + ext) / d;    
    vec3 n = min(t0,t1); n.x = max(max(n.x,n.y),n.z);
    vec3 f = max(t0,t1); f.x = min(min(f.x,f.y),f.z);
    r0 = o + d * n.x;
    r1 = o + d * f.x;
    return bool(step(n.x,f.x));
}