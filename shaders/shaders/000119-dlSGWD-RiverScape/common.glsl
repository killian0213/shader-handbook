// Common (common) — RiverScape by XT95
// https://www.shadertoy.com/view/dlSGWD


#define RESOLUTION iResolution.xy
//#define RESOLUTION (vec2(1920.,1080.))



// ---------------------------------------------
// Hash & Random - From iq
// ---------------------------------------------
int   seed = 1;
int   rand(void) { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
float frand() { return float(rand())/32767.0; }
vec2 frand2() { return vec2(frand(), frand()); }
vec3 frand3() { return vec3(frand(), frand(), frand()); }
void  srand( ivec2 p, int frame )
{
    int n = frame;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589; // by Hugo Elias
    n += p.y;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589;
    n += p.x;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589;
    seed = n;
}
vec3 hash3(vec3 p) {
    uvec3 x = uvec3(floatBitsToUint(p));
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

float noise( vec3 p )
{
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f*f*(3.0-2.0*f);
	
    return mix(mix(mix( hash3(i+vec3(0,0,0)).x, 
                        hash3(i+vec3(1,0,0)).x,f.x),
                   mix( hash3(i+vec3(0,1,0)).x, 
                        hash3(i+vec3(1,1,0)).x,f.x),f.y),
               mix(mix( hash3(i+vec3(0,0,1)).x, 
                        hash3(i+vec3(1,0,1)).x,f.x),
                   mix( hash3(i+vec3(0,1,1)).x, 
                        hash3(i+vec3(1,1,1)).x,f.x),f.y),f.z);
}
vec4 noised( vec3 x )
{
	// https://iquilezles.org/articles/gradientnoise
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);

    float a = hash3( p+vec3(0,0,0) ).x;
    float b = hash3( p+vec3(1,0,0) ).x;
    float c = hash3( p+vec3(0,1,0) ).x;
    float d = hash3( p+vec3(1,1,0) ).x;
    float e = hash3( p+vec3(0,0,1) ).x;
    float f = hash3( p+vec3(1,0,1) ).x;
    float g = hash3( p+vec3(0,1,1) ).x;
    float h = hash3( p+vec3(1,1,1) ).x;

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z), 
                      2.0* du * vec3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                                      k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                                      k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) ).yzwx;
}


// ---------------------------------------------
// Maths
// ---------------------------------------------
#define saturate(x) clamp(x,0.,1.)
#define PI 3.141592653589

mat2 rot(float v) {
    float a = cos(v);
    float b = sin(v);
    return mat2(a,b,-b,a);
}

// From Fizzer - https://web.archive.org/web/20170610002747/http://amietia.com/lambertnotangent.html
vec3 cosineSampleHemisphere(vec3 n)
{
    vec2 rnd = frand2();

    float a = PI*2.*rnd.x;
    float b = 2.0*rnd.y-1.0;
    
    vec3 dir = vec3(sqrt(1.0-b*b)*vec2(cos(a),sin(a)),b);
    return normalize(n + dir);
}












// ---------------------------------------------
// Microfacet
// ---------------------------------------------
float Fresnel(float n1, float n2, float VoH, float f0, float f90)
{
    float r0 = (n1-n2) / (n1+n2);
    r0 *= r0;
    if (n1 > n2)
    {
        float n = n1/n2;
        float sinT2 = n*n*(1.0-VoH*VoH);
        if (sinT2 > 1.0)
            return f90;
        VoH = sqrt(1.0-sinT2);
    }
    float x = 1.0-VoH;
    float ret = r0+(1.0-r0)*pow(x, 5.);
    
    return mix(f0, f90, ret);
}


// ---------------------------------------------
// SDF Utils
// ---------------------------------------------
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}
float smax( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }


float hash( float p ) 
{
    return fract(sin(p)*43758.5453123);
}