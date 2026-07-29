// Common (common) — Malmousque by XT95
// https://www.shadertoy.com/view/fldSRB

#define ZERO (min(iFrame,0)) // skip unroll loop
#define saturate(x) clamp(x,0.,1.)
#define PI 3.141592653589
#define PI_2 1.5707963267948966192313216916398
#define PI_X_2 6.283185307179586476925286766559
#define GOLDEN_RATIO 0.61803398875
#define time iTime
#define frame iFrame

vec3 sundir = normalize( vec3(1.5,.8,2.) );



// ---------------------------------------------------------------------------------
// Maths toolbox
// ---------------------------------------------------------------------------------
float seed = 0.;
float rand() { return fract(sin(seed++)*43758.5453123); }
vec3 tri(vec3 x) {
    return abs(x-floor(x)-.5);
}
vec3 hash3(vec3 p) {
    uvec3 x = uvec3(p*100000.+1000.);
    const uint k = 1103515245U; 
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    
    return vec3(x)*(1.0/float(0xffffffffU));
}


float hash( vec2 p )
{
    return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);
}
float hash( float p )
{
    vec3 p3  = fract(vec3(p) * .1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 randomSphereDir(vec2 rnd)
{
    float s = rnd.x*PI*2.;
    float t = rnd.y*2.-1.;
    return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}
vec3 randomHemisphereDir(vec3 dir, float i)
{
    vec3 v = randomSphereDir( vec2(hash(i+1.), hash(i+2.)) );
    return v * sign(dot(v, dir));
}

float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

float noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

float fbm( vec2 p) {
    float d = noise(p) * .5;
    d += noise(p*2.) * .25;
    d += noise(p*4.) * .125;
    
    return d;
}
float capsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}
vec3 equi2cube (vec2 uv) {
    vec2 thetaphi = (uv*2.-1.) * vec2(PI, PI_2); 
    return vec3(cos(thetaphi.y) * cos(thetaphi.x), sin(thetaphi.y), cos(thetaphi.y) * sin(thetaphi.x));
}

vec2 cube2equi (vec3 p) {
    return vec2((atan(p.z, p.x) / PI_X_2) + 0.5, acos(-p.y) / PI);    
}

// ---------------------------------------------------------------------------------
// Triplanar mapping + bump mapping! 
// clever code taken from Shane
// https://www.shadertoy.com/view/MscSDB
// ---------------------------------------------------------------------------------
vec3 tex3D( sampler2D tex, vec3 p, vec3 n )
{
    n = abs(n);
    vec4 col = texture(tex, p.yz)*n.x + texture(tex, p.xz)*n.y + texture(tex, p.xy)*n.z;
    return pow(col.rgb,vec3(2.2));
}

vec3 bumpMapping( sampler2D tex, vec3 p, vec3 n, float bf )
{
    const vec2 e = vec2(0.001, 0);
    
    mat3 m = mat3( tex3D(tex, p - e.xyy, n).rgb,
                   tex3D(tex, p - e.yxy, n).rgb,
                   tex3D(tex, p - e.yyx, n).rgb);
    
    vec3 g = vec3(0.299, 0.587, 0.114) * m;
    g = (g - dot( tex3D(tex,  p , n).rgb, vec3(0.299, 0.587, 0.114)) )/e.x;
    g -= n * dot(n, g);
                      
    return normalize( n + g*bf );
    
}