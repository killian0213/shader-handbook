// Common (common) — Underwater Boids by michael0884
// https://www.shadertoy.com/view/WdSfzD

#define texel(a, p) texelFetch(a, ivec2(p), 0)
#define ch0 iChannel0
#define ch1 iChannel1
#define ch2 iChannel2
#define ch3 iChannel3
#define R iResolution.xy
#define PI 3.14159265

#define dt 3.
#define loop(i,x) for(int i = min(0, iFrame); i < x; i++)

//rendering scale
#define SC 3.

#define smoothR 2.5
#define density 0.01


#define fog_depth 0.003
//from 0 to 1
#define god_ray_step 0.15
#define wcol vec3(33,98,227)/255.

//render range
#define range 500.
#define FOV 2.
#define camd 300.

//sim stuff
struct obj
{
    int id; //ID
    vec3 X; //position
    float Rho; //neighbor density
    vec3 V; //velocity
    float Pressure; //pressure
    vec3 Color;
    float Scale;
};
    
float Force(float d)
{
    return 0.2*exp(-0.05*d)-2.*exp(-0.5*d);
}

struct mat
{
    vec3 albedo;
    vec3 emiss;
    float rough;
    float metal;
};

//60% of the buffer used for particles
#define P 0.6
#define SN ivec2(6, 2)

ivec2 N; //buffer size
ivec2 sN; //buffer single element size
int TN; //buffer length

ivec2 i2xy(ivec3 sid)
{
    return sN*ivec2(sid.x%N.x, sid.x/N.x) + sid.yz;
}

ivec3 xy2i(ivec2 p)
{
    ivec2 pi = p/sN;
    return ivec3(pi.x + pi.y*N.x, p.x%sN.x, p.y%sN.y);
}

ivec2 cross_distribution(int i)
{
    return (1<<(2*(i/4))) * ivec2( ((i&2)/2)^1, (i&2)/2 ) * ( 2*(i%2) - 1 );
}

float sqr(float x)
{
return x*x + 1e-2;
}

//hash funcs
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash32(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}


const float PHI = 0.5*(sqrt(5.) + 1.);

vec2 inverseSF( vec3 p, float n ) 
{
    float m = 1.0 - 1.0/n;
    
    float phi = min(atan(p.y, p.x), PI), cosTheta = p.z;
    
    float k  = max(2.0, floor( log(n * PI * sqrt(5.0) * (1.0 - cosTheta*cosTheta))/ log(PHI+1.0)));
    float Fk = pow(PHI, k)/sqrt(5.0);
    vec2  F  = vec2( round(Fk), round(Fk * PHI) ); // k, k+1

    vec2 ka = 2.0*F/n;
    vec2 kb = 2.0*PI*( fract((F+1.0)*PHI) - (PHI-1.0) );    
    
    mat2 iB = mat2( ka.y, -ka.x, 
                    kb.y, -kb.x ) / (ka.y*kb.x - ka.x*kb.y);
    
    vec2 c = floor( iB * vec2(phi, cosTheta - m));
    float d = 8.0;
    float j = 0.0;
    for( int s=0; s<4; s++ ) 
    {
        vec2 uv = vec2( float(s-2*(s/2)), float(s/2) );
        
        float i = round(dot(F, uv + c)); // all quantities are ingeters (can take a round() for extra safety)
        
        float phi = 2.0*PI*fract(i*PHI);
        float cosTheta = m - 2.0*i/n;
        float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
        
        vec3 q = vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, cosTheta );
        float squaredDistance = dot(q-p, q-p);
        if (squaredDistance < d) 
        {
            d = squaredDistance;
            j = i;
        }
    }
    return vec2( j, sqrt(d) );
}


mat4 getPerspective(float fov, float aspect, float n, float f)
{   
    float scale = tan(fov * PI / 360.) * n; 
    float r = aspect * scale, l = -r; 
    float t = scale, b = -t; 

	
    return mat4(2. * n / (r - l), 0, 0, 0,
                0, 2. * n / (t - b), 0, 0,
                (r + l) / (r - l), (t + b) / (t - b), -(f + n) / (f - n), -1,
                0, 0, -2. * f * n / (f - n), 0);
}

mat3 getRot(vec2 a)
{
    
   mat3 theta_rot = mat3(1,     0,        0,
                         0,  cos(a.y), sin(a.y), 
                         0, -sin(a.y), cos(a.y)); 
        
   mat3 phi_rot = mat3(cos(a.x),  sin(a.x), 0,
        		       -sin(a.x), cos(a.x), 0,
        		        0,            0,    1); 
   return phi_rot*theta_rot;
}


float NGGX(vec3 n, vec3 h, float a)
{
    float a2 = sqr(a);
    return a2/(PI*sqr( sqr( max(dot(n,h),0.) )*(a2-1.) + 1.));
}

float GGX(vec3 n, vec3 o, float a)
{
    float ndoto = max(dot(n,o),0.);
    return ndoto/mix(1., ndoto, sqr(a+1.)*0.125);
}

float GS(vec3 n, vec3 i, vec3 o, float a)
{
    return GGX(n,i,a)*GGX(n,o,a);
}

vec3 IR(float D, float k0, vec3 k1)
{
    //interference effect here ->
    return (0.25/D + k0*( 1. - cos(2.*PI*pow(vec3(D), -k1)) )) ;
}

vec3 BRDF(vec3 i, vec3 o, vec3 n, mat m)
{
    vec3 h = normalize(i + o);
    vec3 F0 = mix(vec3(0.04), m.albedo, m.metal);
    vec3 FS = F0 + (1.0 - F0) * pow(1.0 - max(dot(h, i), 0.0), 5.0);
    vec3 DFG = NGGX(n,h,m.rough)*GS(n,i,o,m.rough)*FS;
    float denom = max(dot(n, i), 0.001) * max(dot(n, o), 0.001);
    return (m.albedo*(1.-FS)/PI +
            DFG*IR(denom, 0.1, vec3(1.,1.1,1.2)))*max(0., dot(n,o));
}


