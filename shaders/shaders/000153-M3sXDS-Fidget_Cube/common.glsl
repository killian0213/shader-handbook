// Common (common) — Fidget Cube by TheBen27
// https://www.shadertoy.com/view/M3sXDS

#define PI 3.14159
#define MAT_METAL -1.0

vec3 Tonemap_ACES(vec3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

float fresnelFactor(float r0, vec3 dir, vec3 normal) {
    float f = 1.0 - dot(normal, dir);
    return r0 + (1.0 - r0) * (f * f * f * f * f);
}

vec3 skyLight(vec3 dir, vec3 col, vec3 center, float size, float smoothness) {
    float falloff = max(0.0, dot(dir, normalize(center)));
    float sizeMin = 1.0 - size;
    falloff = smoothstep(sizeMin, mix(sizeMin, 1.0, smoothness), falloff);
    // energy correction - smaller lamps should be brighter
    return col * falloff / size;
}

vec3 sky(vec3 dir) {
    vec3 top = vec3(0.4, 0.4, 0.6);
    vec3 bottom = vec3(0.3, 0.3, 0.5);
    vec3 ambient = mix(top, bottom, -dir.y);
    
    vec3 fill = skyLight(dir, vec3(1.0), vec3(-0.1, 1.0, 0.5), 0.5, 1.0);
    vec3 key = skyLight(dir, vec3(0.6), vec3(-0.2, 0.3, -0.2), 0.2, 1.0);
    return ambient + fill + key;
}

float rand(float p)
{
    p = fract(p * .1031);
    p += 0.1;
    p *= p + 33.33;
    p *= p + p;
    p -= 0.1;
    return fract(p);
}

float rand2(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec3 randomSphereDir(vec2 rnd)
{
    float s = rnd.x*PI*2.;
    float t = rnd.y*2.-1.;
    return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}

vec3 randomHemisphereDir(vec3 dir, float i)
{
    vec3 v = randomSphereDir( vec2(rand(i+1.), rand(i+2.)) );
    return v * sign(dot(v, dir));
}

mat2 rot(float t) {
    return mat2(cos(t), -sin(t), sin(t), cos(t));
}

const mat4 id = mat4(
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0
);

mat4 scale(vec3 p) {
    return mat4(
        p.x, 0.0, 0.0, 0.0,
        0.0, p.y, 0.0, 0.0,
        0.0, 0.0, p.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 translate(vec3 p) {
    return mat4(
        1.0, 0.0, 0.0, p.x,
        0.0, 1.0, 0.0, p.y,
        0.0, 0.0, 1.0, p.z,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotZ(float t) {
    float ct = cos(t);
    float st = sin(t);
    return mat4(
         ct, -st, 0.0, 0.0,
         st,  ct, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotY(float t) {
    float ct = cos(t);
    float st = sin(t);
    return mat4(
         ct, 0.0,  st, 0.0,
        0.0, 1.0, 0.0, 0.0,
        -st, 0.0,  ct, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotX(float t) {
    float ct = cos(t);
    float st = sin(t);
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0,  ct, -st, 0.0,
        0.0,  st,  ct, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCircleBox(vec3 p) {
    float smoothness = 0.01;
    float b = sdBox(p, vec3(0.25) - smoothness) - smoothness;
    
    float c = distance(p, vec3(-0.25, -0.25, 0.25)) - 0.5;
    return max(b, c);
}

float sdTriBox(vec3 p) {
    float smoothness = 0.01;
    float b = sdBox(p, vec3(0.25) - smoothness) - smoothness;
    
    float magic = 0.577;
    float cutter = dot(p, normalize(vec3(magic, magic, -magic))) - (0.15);
    return max(b, cutter);
}

vec2 sdfMin(vec2 s1, vec2 s2) {
    if (s1.x < s2.x) {
        return s1;
    }
    return s2;
}