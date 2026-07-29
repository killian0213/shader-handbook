// Common (common) — Random Number Generator Library by paniq
// https://www.shadertoy.com/view/ssGXDd

// random number generator library (https://www.shadertoy.com/view/ssGXDd)
// by Leonard Ritter (@leonard_ritter)

// based on https://www.shadertoy.com/view/MdcfDj
// license: https://unlicense.org/

// 2022/11/27: added support for hexagon sampling

// comment out for faster but lower quality hashing
#define RNGL_HIGH_QUALITY

struct Random { uint s0; uint s1; };

// constructors; note that constructors are wilfully unique,
// i.e. calling a different constructor with the same arguments will not
// necessarily produce the same state.
uint uhash(uint a, uint b);
Random seed(uint s) { return Random(s, uhash(0x1ef7c663u, s)); }
Random seed(uvec2 s) { return Random(s.y, uhash(s.x, s.y)); }
Random seed(Random a, uint b) { return Random(b, uhash(a.s1, b)); }
Random seed(Random a, uvec2 b) { return seed(a, uhash(b.x, b.y)); }
Random seed(Random a, uvec3 b) { return seed(a, uhash(uhash(b.x, b.y), b.z)); }
Random seed(Random a, uvec4 b) { return seed(a, uhash(uhash(b.x, b.y), uhash(b.z, b.w))); }
Random seed(uvec3 s) { return seed(seed(s.xy), s.z); }
Random seed(uvec4 s) { return seed(seed(s.xy), s.zw); }
Random seed(int s) { return seed(uint(s)); }
Random seed(ivec2 s) { return seed(uvec2(s)); }
Random seed(ivec3 s) { return seed(uvec3(s)); }
Random seed(ivec4 s) { return seed(uvec4(s)); }
Random seed(Random a, int b) { return seed(a, uint(b)); }
Random seed(Random a, ivec2 b) { return seed(a, uvec2(b)); }
Random seed(Random a, ivec3 b) { return seed(a, uvec3(b)); }
Random seed(Random a, ivec4 b) { return seed(a, uvec4(b)); }
Random seed(float s) { return seed(floatBitsToUint(s)); }
Random seed(vec2 s) { return seed(floatBitsToUint(s)); }
Random seed(vec3 s) { return seed(floatBitsToUint(s)); }
Random seed(vec4 s) { return seed(floatBitsToUint(s)); }
Random seed(Random a, float b) { return seed(a, floatBitsToUint(b)); }
Random seed(Random a, vec2 b) { return seed(a, floatBitsToUint(b)); }
Random seed(Random a, vec3 b) { return seed(a, floatBitsToUint(b)); }
Random seed(Random a, vec4 b) { return seed(a, floatBitsToUint(b)); }

// fundamental functions to fetch a new random number
// the last static call to the rng will be optimized out
uint urandom(inout Random rng) {
    uint last = rng.s1;
    uint next = uhash(rng.s0, rng.s1);
    rng.s0 = rng.s1; rng.s1 = next;
    return last;
}
uvec2 urandom2(inout Random rng) { return uvec2(urandom(rng),urandom(rng)); }
uvec3 urandom3(inout Random rng) { return uvec3(urandom2(rng),urandom(rng)); }
uvec4 urandom4(inout Random rng) { return uvec4(urandom2(rng),urandom2(rng)); }
int irandom(inout Random rng) { return int(urandom(rng)); }
ivec2 irandom2(inout Random rng) { return ivec2(urandom2(rng)); }
ivec3 irandom3(inout Random rng) { return ivec3(urandom3(rng)); }
ivec4 irandom4(inout Random rng) { return ivec4(urandom4(rng)); }

float unorm(uint n);
float random(inout Random rng) { return unorm(urandom(rng)); }
vec2 random2(inout Random rng) { return vec2(random(rng),random(rng)); }
vec3 random3(inout Random rng) { return vec3(random2(rng),random(rng)); }
vec4 random4(inout Random rng) { return vec4(random2(rng),random2(rng)); }

// ranged random value < maximum value
int range(inout Random rng, int mn, int mx) { return mn + (irandom(rng) % (mx - mn)); }
ivec2 range(inout Random rng, ivec2 mn, ivec2 mx) { return mn + (irandom2(rng) % (mx - mn)); }
ivec3 range(inout Random rng, ivec3 mn, ivec3 mx) { return mn + (irandom3(rng) % (mx - mn)); }
ivec4 range(inout Random rng, ivec4 mn, ivec4 mx) { return mn + (irandom4(rng) % (mx - mn)); }
uint range(inout Random rng, uint mn, uint mx) { return mn + (urandom(rng) % (mx - mn)); }
uvec2 range(inout Random rng, uvec2 mn, uvec2 mx) { return mn + (urandom2(rng) % (mx - mn)); }
uvec3 range(inout Random rng, uvec3 mn, uvec3 mx) { return mn + (urandom3(rng) % (mx - mn)); }
uvec4 range(inout Random rng, uvec4 mn, uvec4 mx) { return mn + (urandom4(rng) % (mx - mn)); }
float range(inout Random rng, float mn, float mx) { float x=random(rng); return mn*(1.0-x) + mx*x; }
vec2 range(inout Random rng, vec2 mn, vec2 mx) { vec2 x=random2(rng); return mn*(1.0-x) + mx*x; }
vec3 range(inout Random rng, vec3 mn, vec3 mx) { vec3 x=random3(rng); return mn*(1.0-x) + mx*x; }
vec4 range(inout Random rng, vec4 mn, vec4 mx) { vec4 x=random4(rng); return mn*(1.0-x) + mx*x; }

// marshalling functions for storage in image buffer and rng replay
vec2 marshal(Random a) { return uintBitsToFloat(uvec2(a.s0,a.s1)); }
Random unmarshal(vec2 a) { uvec2 u = floatBitsToUint(a); return Random(u.x, u.y); }

//// specific distributions

// normal/gaussian distribution
// see https://en.wikipedia.org/wiki/Normal_distribution
float gaussian(inout Random rng, float mu, float sigma) {
    vec2 q = random2(rng);
    float g2rad = sqrt(-2.0 * (log(1.0 - q.y)));
    float z = cos(q.x*6.28318530718) * g2rad;
    return mu + z * sigma;
}

// triangular distribution
// see https://en.wikipedia.org/wiki/Triangular_distribution
// mode is a mixing argument in the range 0..1
float triangular(inout Random rng, float low, float high, float mode) {
    float u = random(rng);
    if (u > mode) {
        return high + (low - high) * (sqrt ((1.0 - u) * (1.0 - mode)));
    } else {
        return low + (high - low) * (sqrt (u * mode));
    }
}
float triangular(inout Random rng, float low, float high) { return triangular(rng, low, high, 0.5); }

// after https://www.shadertoy.com/view/4t2SDh
// triangle distribution in the range -0.5 .. 1.5
float triangle(inout Random rng) {
    float u = random(rng);
    float o = u * 2.0 - 1.0;
    return max(-1.0, o / sqrt(abs(o))) - sign(o) + 0.5;
}

//// geometric & euclidean distributions

// uniformly random point on the edge of a unit circle
// produces 2d normal vector as well
vec2 uniform_circle_edge (inout Random rng) {
    float u = random(rng);
    float phi = 6.28318530718*u;
    return vec2(cos(phi),sin(phi));
}

// uniformly random point in unit circle
vec2 uniform_circle_area (inout Random rng) {
    return uniform_circle_edge(rng)*sqrt(random(rng));
}

// gaussian random point in unit circle
vec2 gaussian_circle_area (inout Random rng, float k) {
    return uniform_circle_edge(rng)*sqrt(-k*log(random(rng)));
}
vec2 gaussian_circle_area (inout Random rng) { return gaussian_circle_area(rng, 0.5); }

// cartesian coordinates of a uniformly random point within a hexagon
vec2 uniform_hexagon_area (inout Random rng, float phase) {
    vec2 u = random2(rng);
    float phi = 6.28318530718*u.x;
    
    const float sqrt3div4 = sqrt(3.0 / 4.0);
    const float pidiv6 = 0.5235987755982988;
    float r = sqrt3div4 / cos(mod(phi + phase, 2.0 * pidiv6) - pidiv6);

    return vec2(cos(phi), sin(phi)) * r * sqrt(u.y);
}

vec2 uniform_hexagon_area (inout Random rng) {
    return uniform_hexagon_area(rng, 1.5707963267948966);
}

// barycentric coordinates of a uniformly random point within a triangle
vec3 uniform_triangle_area (inout Random rng) {
    vec2 u = random2(rng);
    if (u.x + u.y > 1.0) {
        u = 1.0 - u;
    }
    return vec3(u.x, u.y, 1.0-u.x-u.y);
}

// uniformly random on the surface of a sphere
// produces normal vectors as well
vec3 uniform_sphere_area (inout Random rng) {
    vec2 u = random2(rng);
    float phi = 6.28318530718*u.x;
    float rho_c = 2.0 * u.y - 1.0;
    float rho_s = sqrt(1.0 - (rho_c * rho_c));
    return vec3(rho_s * cos(phi), rho_s * sin(phi), rho_c);
}

// uniformly random within the volume of a sphere
vec3 uniform_sphere_volume (inout Random rng) {
    return uniform_sphere_area(rng) * pow(random(rng), 1.0/3.0);
}

// barycentric coordinates of a uniformly random point within a 3-simplex
// based on "Generating Random Points in a Tetrahedron" by Rocchini et al
vec4 uniform_simplex_volume (inout Random rng) {
    vec3 u = random3(rng);
    if(u.x + u.y > 1.0) {
        u = 1.0 - u;
    }
    if(u.y + u.z > 1.0) {
        u.yz = vec2(1.0 - u.z, 1.0 - u.x - u.y);
    } else if(u.x + u.y + u.z > 1.0) {
        u.xz = vec2(1.0 - u.y - u.z, u.x + u.y + u.z - 1.0);
    }
    return vec4(1.0 - u.x - u.y - u.z, u); 
}

// for differential evolution, in addition to index K, we need to draw three more
// indices a,b,c for a list of N items, without any collisions between k,a,b,c.
// this is the O(1) hardcoded fisher-yates shuffle for this situation.
ivec3 sample_k_3(inout Random rng, int N, int K) {
    ivec3 t = range(rng, ivec3(1,2,3), ivec3(N));
    int db = (t.y == t.x)?1:t.y;
    int dc = (t.z == t.y)?((t.x != 2)?2:1):((t.z == t.x)?1:t.z);
    return (K + ivec3(t.x, db, dc)) % N;
}

/////////////////////////////////////////////////////////////////////////

// auxiliary functions from http://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
// The Unreasonable Effectiveness of Quasirandom Sequences, by Martin Roberts
float r1(float o, int i) {
    return fract(o + float(i * 10368889)/exp2(24.0));
}
vec2 r2(vec2 o, int i) {
    return fract(o + vec2(i * ivec2(12664745, 9560333))/exp2(24.0));
}
vec3 r3(vec3 o, int i) {
    return fract(o + vec3(i * ivec3(13743434, 11258243, 9222443))/exp2(24.0));
}
vec4 r4(vec4 o, int i) {
    return fract(o + vec4(i * ivec4(14372619, 12312662, 10547948, 9036162))/exp2(24.0));
}

float r1(int i) { return r1(0.5, i); }
vec2 r2(int i) { return r2(vec2(0.5), i); }
vec3 r3(int i) { return r3(vec3(0.5), i); }
vec4 r4(int i) { return r4(vec4(0.5), i); }

/////////////////////////////////////////////////////////////////////////

// if it turns out that you are unhappy with the distribution or performance
// it is possible to exchange this function without changing the interface
uint uhash(uint a, uint b) { 
    uint x = ((a * 1597334673U) ^ (b * 3812015801U));
#ifdef RNGL_HIGH_QUALITY
    // from https://nullprogram.com/blog/2018/07/31/
    x = x ^ (x >> 16u);
    x = x * 0x7feb352du;
    x = x ^ (x >> 15u);
    x = x * 0x846ca68bu;
    x = x ^ (x >> 16u);
#else
    x = x * 0x7feb352du;
    x = x ^ (x >> 15u);
    x = x * 0x846ca68bu;
#endif
    return x;
}
float unorm(uint n) { return float(n) * (1.0 / float(0xffffffffU)); }