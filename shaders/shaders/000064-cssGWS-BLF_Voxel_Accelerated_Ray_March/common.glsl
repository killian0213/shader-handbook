// Common (common) — BLF Voxel Accelerated Ray March by iY0Yi
// https://www.shadertoy.com/view/cssGWS

// "Hash without Sine" by Dave_Hoskins:
#define PI 3.1415926
#define MAX_DIST 100.0
#define MIN_DIST 0.001
#define MAX_RAY_STEPS 20
#define MAT_VOID vec3(-1)
#define R(p, a) p = cos(a) * p + sin(a) * vec2(p.y, -p.x)

// https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3) {
    p3 = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash21(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

// "Best" Integer Hash by FabriceNeyret2
// https://www.shadertoy.com/view/WttXWX
uint triple32(uint x){
    x ^= x >> 17;
    x *= 0xed5ad4bbU;
    x ^= x >> 11;
    x *= 0xac4c1b51U;
    x ^= x >> 15;
    x *= 0x31848babU;
    x ^= x >> 14;
    return x;
}

float hash(uint x){
    return float(triple32(x))/float(0xffffffffU);
}

uint uhash(uvec2 v){
    return triple32(v.x + triple32(v.y));
}

uint uhash(uvec3 v){
    return triple32(v.x + triple32(v.y + triple32(v.z)));
}

// https://iquilezles.org/articles/intersectors
vec2 iBox( in vec3 ro, in vec3 rd, vec3 boxSize){
    vec3 m = 1./rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return vec2(-1.);
    return vec2( tN, tF );
}

float sdSphere( vec3 p, float s ){
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b ){
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdBoxFrame( vec3 p, vec3 b, float e ){
    p = abs(p  )-b;
    vec3 q = abs(p+e)-e;
    return min(min(
    length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
    length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
    length(max(vec3(q.x,q.y,p.z) ,0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

// https://www.shadertoy.com/view/XdV3W3
vec2 bx_cos(vec2 a){return clamp(abs(mod(a,8.0)-4.0)-2.0,-1.0,1.0);}
vec2 bx_cossin(float a){return bx_cos(vec2(a,a-2.0));}

vec3 ro, rd;