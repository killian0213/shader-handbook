// Common (common) — Liquid Metalball by NoxWings
// https://www.shadertoy.com/view/7dtSDf

// Common / Framework stuff

// -----------------------------------------------------------------------------
// Basics / Math

#define S(x, y, z) smoothstep(x, y, z)
#define animTime (mod(iTime, 11.))
#define A(v1,v2,t1,t2) mix(v1,v2,S(t1,t2,animTime))

float invLerp(float a, float b, float x) {
    x = clamp(x, a, b);
    return (x - a) / (b - a);
}

const float PI = 3.14159;
const float TAU = PI * 2.0;
const float DEG2RAD = PI / 180.;

float saturate(in float x) { return clamp(x, 0.0, 1.0); }
vec2 saturate(in vec2 x) { return clamp(x, vec2(0.0), vec2(1.0)); }
vec3 saturate(in vec3 x) { return clamp(x, vec3(0.0), vec3(1.0)); }
vec4 saturate(in vec4 x) { return clamp(x, vec4(0.0), vec4(1.0)); }

mat2 rot2D(float angle) {
    float ca = cos(angle), sa = sin(angle);
    return mat2(ca, -sa, sa, ca);
}

mat3 lookAtMatrix(in vec3 lookAtDirection) {
	vec3 ww = normalize(lookAtDirection);
    vec3 uu = cross(ww, vec3(0.0, 1.0, 0.0));
    vec3 vv = cross(uu, ww);
    return mat3(uu, vv, -ww);
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}


// -----------------------------------------------------------------------------
// Colors

vec4 linearTosRGB(vec4 linearRGB)
{
    bvec4 cutoff = lessThan(linearRGB, vec4(0.0031308));
    vec4 higher = vec4(1.055)*pow(linearRGB, vec4(1.0/2.4)) - vec4(0.055);
    vec4 lower = linearRGB * vec4(12.92);

    return mix(higher, lower, cutoff);
}

vec4 sRGBToLinear(vec4 sRGB)
{
    bvec4 cutoff = lessThan(sRGB, vec4(0.04045));
    vec4 higher = pow((sRGB + vec4(0.055))/vec4(1.055), vec4(2.4));
    vec4 lower = sRGB/vec4(12.92);

    return mix(higher, lower, cutoff);
}
   
vec4 ACESFilm(vec4 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}
   
// -----------------------------------------------------------------------------
// Hits

float smin(float a, float b, float k) {
	float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}
float smax(float a, float b, float k) {
	float h = max(k-abs(a-b),0.0);
	return max(a, b) + h*h*0.25/k;
}


struct Hit {
    int id;
    float d; // means distance to surface
};

struct TraceResult {
    int id;
    float d; // means distance traveled
    vec3 ro;
    vec3 rd; 
};

Hit hmin(in Hit a, in Hit b) { if (a.d < b.d) return a; return b; }
Hit hmax(in Hit a, in Hit b) { if (a.d > b.d) return a; return b; }
Hit hsmin(in Hit a, in Hit b, in float k) {
    Hit h = hmin(a, b);
    h.d = smin(a.d, b.d, k);
    return h;
}
Hit hsmax(in Hit a, in Hit b, in float k) {
    Hit h = hmax(a, b);
    h.d = smin(a.d, b.d, k);
    return h;
}

// -----------------------------------------------------------------------------
// Materials

struct Light {
    vec3 direction;
    vec3 ambient;
    vec3 color;
};

struct Surface {
    int materialId;
    float dist;
    vec3 p;
    vec3 n;
    float ao;
    vec3 rd;
};
    
struct Material {
    vec3 albedo;
    float metallic;
    float roughness;
    vec3 emissive;
    float ao;
};

// -----------------------------------------------------------------------------
// SDFs

float sdSphere(in vec3 p, in float r) {
    return length(p) - r;
}

// -----------------------------------------------------------------------------
// Camera

struct Camera {
    vec3 position;
	vec3 direction;
};

Camera createOrbitCamera(vec2 uv, vec2 mouse, vec2 resolution, float fov, vec3 target, float height, float distanceToTarget) {
    vec2 r = mouse;
    float halfFov = fov * 0.5;
    float zoom = cos(halfFov) / sin(halfFov);
    
    vec3 position = target + vec3(0, height, 0) + vec3(sin(r.x), 0.0, cos(r.x)) * distanceToTarget ;
    vec3 direction = normalize(vec3(uv, -zoom));
    direction.yz = rot2D(-r.y) * direction.yz;
    direction = lookAtMatrix(target - position) * direction;
    
    return Camera(position, direction);
}

// -----------------------------------------------------------------------------
// PBR Implementation
// - Lambert or Burley diffuse    
// - Schlick Fresnel
// - GGX NDF
// - Smith-GGX height-correlated visibility function

// Sources
// 
// https://learnopengl.com/PBR/Lighting
// https://google.github.io/filament/Filament.html
// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#appendix-b-brdf-implementation
    
vec3 F_Schlick_full(float HoV, vec3 f0, vec3 f90) {
    return f0 + (f90 - f0) * pow(1.0 - HoV, 5.0);
} 

vec3 F_Schlick(float HoV, vec3 f0) {
    return F_Schlick_full(HoV, f0, vec3(1.0));
} 
    
float Diff_Lambert() {
    return 1.0 / PI;
}

vec3 Diff_Burley(float NoV, float NoL, float LoH, float roughness) {
    float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    vec3 lightScatter = F_Schlick_full(NoL, vec3(1.0), vec3(f90));
    vec3 viewScatter = F_Schlick_full(NoV, vec3(1.0), vec3(f90));
    return lightScatter * viewScatter * (1.0 / PI);
}

float D_GGX(float NoH, float a) {
    float a2 = a * a;
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * f * f);
}

float V_SmithGGXCorrelated(float NoV, float NoL, float a) {
    float a2 = a * a;
    float NoV2 = NoV*NoV;
    float NoL2 = NoL*NoL;
    float GGL = NoL * sqrt(NoV2 * (1.0 - a2) + a2);
    float GGV = NoV * sqrt(NoL2 * (1.0 - a2) + a2);
	return 0.5 / (GGL + GGV);
}

float GGX_Smith_Approx_Visibility(float NoV, float NoL, float a) {
    return 1.0 / (2.0 * mix(2.0*NoL*NoV, NoL+NoV, a));
}

vec3 BRDF(Light l, Surface surf, Material mat) {
    vec3 V = -surf.rd;
    vec3 N = surf.n;
    vec3 L = l.direction;
    vec3 H = normalize(V + L);
    
    float NoV = max(dot(N, V), 0.0);
    float NoL = max(dot(N, L), 0.0);
    float NoH = max(dot(N, H), 0.0);
    float HoV = max(dot(H, V), 0.0);
    
    vec3  albedo     = mat.albedo;
    float roughness  = mat.roughness;
    float a          = roughness * roughness;
    float metallic   = mat.metallic;
    float dielectric = 1.0 - metallic;
    
    // Constants
    vec3 dielectricSpecular = vec3(0.04);
    vec3 black = vec3(0);
    
    // Frenel term
    vec3 F0 = mix(dielectricSpecular, albedo, metallic);
    vec3 F  = F_Schlick(HoV, F0);
    
    // Normal distribution
    float D = D_GGX(NoH, a);
    
    // Visibility term
    //     should be equivalent to G / (4.0 * NoL * NoV)
    //     but it doesn't look the same as https://www.shadertoy.com/view/tdKXR3
    float Vis = V_SmithGGXCorrelated(NoV, NoL, a);
    
    // Specular BRDF Cook Torrance
    vec3 specular = F * (Vis * D);
    
    // Lambert Diffuse
    //     Should we scale by (1.0 - F) ?? gltf and learnopengl have it but filament doesn't
    //     Also what about lambert 1/PI ?? https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
    //     PI might not be used in IBL only?
    vec3 kD = vec3(1.0) - F;
    vec3 c = mix(albedo * (1.0-dielectricSpecular), black, metallic);
    vec3 diffuse = kD * (c / PI);
    // vec3 diffuse = (1.0 - F) * diffuseColor * Diff_Burley(NoV, NoL, NoH, a);
    
    // Final Color
    vec3 fakeGI = l.ambient * mat.albedo;
    vec3 emissive = mat.emissive;
    vec3 directLight = l.color * NoL * (diffuse + specular);
    
    //return vec3(Vis)*NoL;
    return fakeGI + emissive + directLight;
}
