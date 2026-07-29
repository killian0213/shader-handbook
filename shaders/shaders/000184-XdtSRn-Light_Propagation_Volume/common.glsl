// Common (common) — Light Propagation Volume by paniq
// https://www.shadertoy.com/view/XdtSRn

#define USE_LPV_OCCLUSION 1
#define USE_LPV_BOUNCE 1
#define USE_TRIQUADRATIC_INTERPOLATION 1

#define LIGHT_Z 9.0
const ivec3 lpvsizei = ivec3(32);
const vec3 lpvsize = vec3(lpvsizei);

float packfragcoord2 (vec2 p, vec2 s) {
    return floor(p.y) * s.x + p.x;
}
vec2 unpackfragcoord2 (float p, vec2 s) {
    float x = mod(p, s.x);
    float y = (p - x) / s.x + 0.5;
    return vec2(x,y);
}
ivec2 unpackfragcoord2 (int p, ivec2 s) {
    int x = p % s.x;
    int y = (p - x) / s.x;
    return ivec2(x,y);
}
float packfragcoord3 (vec3 p, vec3 s) {
    return floor(p.z) * s.x * s.y + floor(p.y) * s.x + p.x;
}
int packfragcoord3 (ivec3 p, ivec3 s) {
    return p.z * s.x * s.y + p.y * s.x + p.x;
}
vec3 unpackfragcoord3 (float p, vec3 s) {
    float x = mod(p, s.x);
    float y = mod((p - x) / s.x, s.y);
    float z = (p - x - floor(y) * s.x) / (s.x * s.y);
    return vec3(x,y+0.5,z+0.5);
}



vec2 min2(vec2 a, vec2 b) {
    return (a.x <= b.x)?a:b;
}

vec2 max2(vec2 a, vec2 b) {
    return (a.x > b.x)?a:b;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdCylinder( vec3 p, float s )
{
  return length(p.xz)-s;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

vec2 plane( vec3 p) {
    return vec2(p.y+1.0,4.0);
}

vec2 doModel( vec3 p, float iTime ) {
	
    vec2 d = plane(p);
    
    vec2 q = vec2(sdSphere(p - vec3(0.0,0.0,-0.8), 1.0),1.0);
    q = max2(q, vec2(-sdCylinder(p - vec3(0.0,0.0,-0.8), 0.5),2.0));
    d = min2(d, q);
    
    d = min2(d, vec2(sdBox(p - vec3(0.0,0.0,2.2), vec3(2.0,4.0,0.3)),2.0));
    d = min2(d, vec2(sdBox(p - vec3(0.0,0.0,-2.2), vec3(2.0,4.0,0.3)),3.0));
    d = min2(d, vec2(sdBox(p - vec3(-2.2,0.0,0.0), vec3(0.3,4.0,2.0)),1.0));
    
    q = vec2(sdBox(p - vec3(-1.0,0.0,1.0), vec3(0.5,1.0,0.5)),1.0);
    q = max2(q, vec2(-sdBox(p - vec3(-0.5,0.5,0.5), vec3(0.5,0.7,0.5)),3.0));
    
    d = min2(d, q);
    
    d = min2(d, vec2(sdTorus(p.yxz - vec3(-0.5 + sin(iTime*0.25),1.4,0.5), vec2(1.0, 0.3)),1.0));
    
    return d;
}
vec3 calcNormal( in vec3 pos, float iTime )
{
    const float eps = 0.002;             // precision of the normal computation

    const vec3 v1 = vec3( 1.0,-1.0,-1.0);
    const vec3 v2 = vec3(-1.0,-1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0,-1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);

	return normalize( v1*doModel( pos + v1*eps, iTime ).x + 
					  v2*doModel( pos + v2*eps, iTime ).x + 
					  v3*doModel( pos + v3*eps, iTime ).x + 
					  v4*doModel( pos + v4*eps, iTime ).x );
}
vec4 doMaterial( in vec3 pos, float iTime )
{
    float k = doModel(pos, iTime).y;
    
    vec3 c = vec3(0.0);
    
    c = mix(c, vec3(1.0,1.0,1.0), float(k == 1.0));
    c = mix(c, vec3(1.0,0.2,0.1), float(k == 2.0));
    c = mix(c, vec3(0.1,0.3,1.0), float(k == 3.0));
    c = mix(c, vec3(0.3,0.15,0.1), float(k == 4.0));
    c = mix(c, vec3(0.4,1.0,0.1), float(k == 5.0));
    
    return vec4(c,0.0);
}


vec4 sh_project(vec3 n) {
    return vec4(
        n,
        sqrt(1.0/3.0));
}

float sh_dot(vec4 a, vec4 b) {
    return max(dot(a,b),0.0);
}

#define PI 3.14159265359

// 3 / (4 * pi)
const float m3div4pi = 3.0 / (4.0 * PI);
float sh_flux(float d) {
	return d * m3div4pi;
}

float sh_shade(vec4 vL, vec4 vN) {
    return sh_flux(sh_dot(vL, vN));
}

#define SHSharpness 0.7 // 2.0
vec4 sh_irradiance_probe(vec4 v) {
    const float sh_c0 = (2.0 - SHSharpness) * 1.0;
    const float sh_c1 = SHSharpness * 2.0 / 3.0;
    return vec4(v.xyz * sh_c1, v.w * sh_c0);
}

float shade_probe(vec4 sh, vec4 shn) {
    return sh_shade(sh_irradiance_probe(sh), shn);
}

///////////////////////////////////////////////

// ACES fitted
// from https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl

const mat3 ACESInputMat = mat3(
    0.59719, 0.35458, 0.04823,
    0.07600, 0.90834, 0.01566,
    0.02840, 0.13383, 0.83777
);

// ODT_SAT => XYZ => D60_2_D65 => sRGB
const mat3 ACESOutputMat = mat3(
     1.60475, -0.53108, -0.07367,
    -0.10208,  1.10813, -0.00605,
    -0.00327, -0.07276,  1.07602
);

vec3 RRTAndODTFit(vec3 v)
{
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

vec3 ACESFitted(vec3 color)
{
    color = color * ACESInputMat;

    // Apply RRT and ODT
    color = RRTAndODTFit(color);

    color = color * ACESOutputMat;

    // Clamp to [0, 1]
    color = clamp(color, 0.0, 1.0);

    return color;
}

//---------------------------------------------------------------------------------

float linear_srgb(float x) {
    return mix(1.055*pow(x, 1./2.4) - 0.055, 12.92*x, step(x,0.0031308));
}
vec3 linear_srgb(vec3 x) {
    return mix(1.055*pow(x, vec3(1./2.4)) - 0.055, 12.92*x, step(x,vec3(0.0031308)));
}

float srgb_linear(float x) {
    return mix(pow((x + 0.055)/1.055,2.4), x / 12.92, step(x,0.04045));
}
vec3 srgb_linear(vec3 x) {
    return mix(pow((x + 0.055)/1.055,vec3(2.4)), x / 12.92, step(x,vec3(0.04045)));
}

