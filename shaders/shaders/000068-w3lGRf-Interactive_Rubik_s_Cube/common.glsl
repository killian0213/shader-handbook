// Common (common) — Interactive Rubik's Cube by kishimisu
// https://www.shadertoy.com/view/w3lGRf

//////  SETTINGS  ///////

// Antialiasing level
#define AA 2.

// Rotation duration
#define ANIM_DURATION .45

/////////////////////////

// Color function (color index between 0-5)
vec3 palette(float index) {
    return 1. + cos((index+3.)/6.*6.283185 + vec3(0,1,2)*1.5);
}

// Camera
mat4 proj = mat4(2.6,0,0,0,0,2.6,0,0,0,0,-1,-1,0,0,-1,0); // Perspective matrix with ~45° fov
mat4 lookAt(vec3 eye) {
    vec3 f = normalize(-eye);
    vec3 r = normalize(cross(vec3(0,1,0), f));
    vec3 u = cross(f, r);
    return mat4(
        r.x, u.x, -f.x, 0,
        r.y, u.y, -f.y, 0,
        r.z, u.z, -f.z, 0,
        -dot(r, eye), -dot(u, eye), dot(f, eye), 1
    );
}
// clip space pos => world space dir
vec3 computeRayDirection(vec2 uv, mat4 view) {
    vec4 clipPos = vec4(uv, -1, 1);
    vec4 viewPos = inverse(proj) * clipPos;
    vec3 viewDir = viewPos.xyz / viewPos.w;
    vec4 worldDir = inverse(view) * vec4(viewDir, 0);
    return normalize(worldDir.xyz);
}
// world space => clip space
vec2 project(vec3 p, mat4 viewproj) {
    vec4 clipSpace = viewproj * vec4(p, 1);
    return clipSpace.xy / clipSpace.w;
}

// 3D rotation matrices
mat3 rotateX(float a) {
    float s = sin(a); 
    float c = cos(a);
    return mat3(1,0,0,0,c,-s,0,s,c);
}
mat3 rotateY(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat3(c,0,-s,0,1,0,s,0,c);
}
mat3 rotateZ(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

// ID [0,26] to ID 3x3 [0,2]
ivec3 getID(int index) {
    int x = index % 3;
    int y = (index / 3) % 3;
    int z = index / 9;
    return ivec3(x, y, z);
}

// Random noise (https://www.shadertoy.com/view/4djSRW)
vec2 hash21(float p) {
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

// Box intersection functions (https://iquilezles.org/articles/boxfunctions)
vec4 boxIntersectOpti(vec3 ro, vec3 m, vec3 k) {
    vec3 n = -m * ro;
    vec3 t1 = n - k;
    vec3 t2 = n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    return tN > tF ? vec4(1e9) : vec4(t1, tN);
}
vec4 boxIntersect(vec3 ro, vec3 rd, float rad) {
    vec3 m = 1./rd;
    vec3 n = -m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = n - k;
    vec3 t2 = n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if(tN > tF) return vec4(-1);
    vec3 nor = -sign(rd)*step(t1.yzx, t1.xyz)*step(t1.zxy, t1.xyz);
    return vec4(nor, tN);
}