// Common (common) — pencil_drawn_crystal by skaplun
// https://www.shadertoy.com/view/styGDw

#define MIN_FLOAT 1e-6
#define MAX_FLOAT 1e6
#define EPSILON 1e-2
#define rx(a) mat3(cos(a), -sin(a), 0., sin(a), cos(a), 0., 0., 0., 1.)
#define ry(a) mat3(cos(a), 0., sin(a), 0., 1., 0., -sin(a), 0., cos(a))
#define rz(a) mat3(1., 0., 0., 0., cos(a), -sin(a), -sin(a), 0., cos(a))
#define rotate(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define saturate(x) clamp(x, 0., 1.)
#define SIDE  vec3(1., 0., 0.);
const float PI = acos(-1.);
const float PI2 = 2. * PI;

struct Ray{vec3 origin, direction;};
struct Box{ vec3 o; vec3 size;};
struct HitRecord{float dist[2];vec3 ptnt[2];vec3 nrm[2];};
 
bool plane_hit(in vec3 ro, in vec3 rd, in vec3 po, in vec3 pn, out float dist) {
    float denom = dot(pn, rd);
    if (denom > MIN_FLOAT) {
        vec3 p0l0 = po - ro;
        float t = dot(p0l0, pn) / denom;
        if(t >= MIN_FLOAT && t < MAX_FLOAT){
			dist = t;
            return true;
        }
    }
    return false;
}

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))
vec3 hash33(vec3 p)
{
	uvec3 q = uvec3(ivec3(p)) * UI3;
	q = (q.x ^ q.y ^ q.z)*UI3;
	return vec3(q) * UIF;
}

float sdPlane(vec3 p, vec3 n, float h){
    return dot(p,n) + h;
}

#define MIN x
#define MAX y
bool box_hit(const in Box inbox, in Ray inray, out vec2 dst){
    vec2 tx, ty, tz;
    vec3 maxbounds = inbox.o + vec3( inbox.size);
    vec3 minbounds = inbox.o + vec3(-inbox.size);
    tx = ((inray.direction.x >= 0.?vec2(minbounds.x, maxbounds.x):vec2(maxbounds.x, minbounds.x)) - inray.origin.x) / inray.direction.x;
	ty = ((inray.direction.y >= 0.?vec2(minbounds.y, maxbounds.y):vec2(maxbounds.y, minbounds.y)) - inray.origin.y) / inray.direction.y;
    if ((tx.MIN > ty.MAX) || (ty.MIN > tx.MAX))
        return false;
    tx = vec2(max(tx.MIN, ty.MIN), min(tx.MAX, ty.MAX));
	tz = ((inray.direction.z >= 0.?vec2(minbounds.z, maxbounds.z):vec2(maxbounds.z, minbounds.z)) - inray.origin.z) / inray.direction.z;
    if ((tx.MIN > tz.MAX) || (tz.MIN > tx.MAX))
        return false;
    tx = vec2(max(tx.MIN, tz.MIN), min(tx.MAX, tz.MAX));
    
    if(tx.MIN >= 0. || tx.MAX >= 0.){
        dst = vec2(tx.MIN, tx.MAX);
        return true;
    }
        
    return false;
}