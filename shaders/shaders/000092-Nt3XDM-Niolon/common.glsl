// Common (common) — Niolon by XT95
// https://www.shadertoy.com/view/Nt3XDM

// ---------------------------------------------------------------------------------
// Switch to high quality if you have no fear!
// ---------------------------------------------------------------------------------
//#define HIGH_QUALITY
#define MEDIUM_QUALITY
//#define LOW_QUALITY

#ifdef HIGH_QUALITY
    #define SCALE_FACTOR 1. 
    #define RAYTRACED_WATER 1 
#endif

#ifdef MEDIUM_QUALITY
    #define SCALE_FACTOR 1. 
    #define RAYTRACED_WATER 0
#endif

#ifdef LOW_QUALITY
    #define SCALE_FACTOR 2. 
    #define RAYTRACED_WATER 0 
#endif




#define saturate(x) clamp(x,0.,1.)
#define PI 3.141592653589
#define GOLDEN_RATIO 0.61803398875
#define time iTime
#define frame iFrame

vec3 sundir = normalize( vec3(.5,1.,-2.) );



// ---------------------------------------------------------------------------------
// Maths toolbox
// ---------------------------------------------------------------------------------
float seed = 0.;
float rand() { return fract(sin(seed++)*43758.5453123); }

vec3 hash3(vec3 p) {
    uvec3 x = uvec3(p*100000.+1000.);
    const uint k = 1103515245U; 
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    
    return vec3(x)*(1.0/float(0xffffffffU));
}

vec3 cosineDirection( vec3 p, in vec3 n)
{
    vec3 rnd = hash3(p+11.);

    float a = 6.2831853 * rnd.y;
    rnd.x = 2.0*rnd.x - 1.0;
    return normalize( n + vec3(sqrt(1.0-rnd.x*rnd.x) * vec2(cos(a), sin(a)), rnd.x) );

}

// Still the same noise function from "La calanque"
//Thx to Las^Mercury
float noise(vec3 p)
{
    vec3 i = floor(p);
    vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
    vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
    a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
    a.xy = mix(a.xz, a.yw, f.y);
    return mix(a.x, a.y, f.z)*.5+.5;
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