// Image (image) — SDF Ambient Occlusion  by mhnewman
// https://www.shadertoy.com/view/XlXyD4

// Approximate ambient occlusion using signed distance functions in a ray marched scene.
// My first attempt at SDF ray marching.
// Thanks to Jamie Wong for the great tutorial:
// http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/

const int marchIter = 256;
const float marchDist = 100.0;
const float epsilon = 0.0001;

const int aoIter = 8;
const float aoDist = 0.07;
const float aoPower = 2.0;

const vec3 aoDir[12] = vec3[12](
	vec3(0.357407, 0.357407, 0.862856),
	vec3(0.357407, 0.862856, 0.357407),
	vec3(0.862856, 0.357407, 0.357407),
	vec3(-0.357407, 0.357407, 0.862856),
	vec3(-0.357407, 0.862856, 0.357407),
	vec3(-0.862856, 0.357407, 0.357407),
	vec3(0.357407, -0.357407, 0.862856),
	vec3(0.357407, -0.862856, 0.357407),
	vec3(0.862856, -0.357407, 0.357407),
	vec3(-0.357407, -0.357407, 0.862856),
	vec3(-0.357407, -0.862856, 0.357407),
	vec3(-0.862856, -0.357407, 0.357407)
);

const float tau = 6.283185;

vec3 cubePos0;
mat3 cubeDir0;
vec3 cubePos1;
mat3 cubeDir1;
vec3 cubePos2;
mat3 cubeDir2;
vec3 cubePos3;
mat3 cubeDir3;
vec3 cubePos4;
mat3 cubeDir4;

float ground(vec3 p) {
    return p.z;
}

float cube(vec3 p) {
    return max(length(max(abs(p) - vec3(1.0), 0.0)), length(p) - 1.35);
}

void setCube(float index, out vec3 cubePos, out mat3 cubeDir) {
    float t = tau * mod(index / 5.0 + 0.02 * iTime + 0.12, 1.0);
    float a = 2.0 * t;
    float b = 3.0 * t;
    float c = 7.0 * t;
    cubePos = vec3(1.8 * cos(b), 1.8 * cos(c), 1.0 + sin(a));
    cubeDir = mat3(cos(a), -sin(a), 0.0, sin(a), cos(a), 0.0, 0.0, 0.0, 1.0);
    cubeDir *= mat3(cos(b), 0.0, -sin(b), 0.0, 1.0, 0.0, sin(b), 0.0, cos(b));
    cubeDir *= mat3(cos(c), -sin(c), 0.0, sin(c), cos(c), 0.0, 0.0, 0.0, 1.0);
}

void setScene() {
	setCube(0.0, cubePos0, cubeDir0);
	setCube(1.0, cubePos1, cubeDir1);
	setCube(2.0, cubePos2, cubeDir2);
	setCube(3.0, cubePos3, cubeDir3);
	setCube(4.0, cubePos4, cubeDir4);
}

float scene(vec3 p) {
    float s = ground(p);
    s = min(s, cube(cubeDir0 * (p - cubePos0)));
    s = min(s, cube(cubeDir1 * (p - cubePos1)));
    s = min(s, cube(cubeDir2 * (p - cubePos2)));
    s = min(s, cube(cubeDir3 * (p - cubePos3)));
    s = min(s, cube(cubeDir4 * (p - cubePos4)));
    return s;
}

float march(vec3 eye, vec3 dir) {
    float depth = 0.0;
    for (int i = 0; i < marchIter; ++i) {
        float dist = scene(eye + depth * dir);
        depth += dist;
        if (dist < epsilon || depth >= marchDist)
			break;
    }
    return depth;
}

float ao(vec3 p, vec3 n) {
    float dist = aoDist;
    float occ = 1.0;
    for (int i = 0; i < aoIter; ++i) {
        occ = min(occ, scene(p + dist * n) / dist);
        dist *= aoPower;
    }
    occ = max(occ, 0.0);
    return occ;
}

vec3 normal(vec3 p) {
    return normalize(vec3(
        scene(vec3(p.x + epsilon, p.y, p.z)) - scene(vec3(p.x - epsilon, p.y, p.z)),
        scene(vec3(p.x, p.y + epsilon, p.z)) - scene(vec3(p.x, p.y - epsilon, p.z)),
        scene(vec3(p.x, p.y, p.z + epsilon)) - scene(vec3(p.x, p.y, p.z - epsilon))
    ));
}

vec3 ray(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = fieldOfView * size.y;
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 dir, vec3 up) {
    vec3 f = normalize(dir);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

mat3 alignMatrix(vec3 dir) {
    vec3 f = normalize(dir);
    vec3 s = normalize(cross(f, vec3(0.48, 0.6, 0.64)));
    vec3 u = cross(s, f);
    return mat3(u, s, f);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec3 dir = ray(2.5, iResolution.xy, fragCoord);
    
    vec2 m = vec2(0.5, 0.75);
    if (iMouse.z > 0.0)
        m = iMouse.xy / iResolution.xy;
    m *= tau * vec2(1.0, 0.25);

    float dist = 15.0;
    vec3 center = vec3(0.0, 0.0, 1.0);
    vec3 eye = center;
    eye += vec3(dist * sin(m.x) * sin(m.y), dist * cos(m.x) * sin(m.y), dist * cos(m.y));
    mat3 mat = viewMatrix(center - eye, vec3(0.0, 0.0, 1.0));
    dir = mat * dir;
    
    setScene();
    float depth = march(eye, dir);
    if (depth >= marchDist - epsilon) {
        fragColor = vec4(1.0);
		return;
    }
    vec3 p = eye + depth * dir;
    vec3 n = normal(p);
 
    mat = alignMatrix(n);
    float col = 0.0;
    for (int i = 0; i < 12; ++i) {
        vec3 m = mat * aoDir[i];
        col += ao(p, m) * (0.5 + 0.5 * dot(m, vec3(0.0, 0.0, 1.0)));
    }

    fragColor = vec4(vec3(pow(0.2 * col, 0.7)), 1.0);
}