// Common (common) — Emergence of life by michael0884
// https://www.shadertoy.com/view/Wt2BR1

#define T(p) texelFetch(iChannel0, ivec2(mod(p,R)), 0)
#define P(p) texture(iChannel0, mod(p,R)/R)
#define C(p) texture(iChannel1, mod(p,R)/R)
#define D(p) texture(iChannel2, mod(p,R)/R)

#define PI 3.14159265
#define dt 1.
#define R iResolution.xy

const vec2 dx = vec2(0, 1);

float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

#define rand_interval 250
#define random_gen(a, b, seed) ((a) + ((b)-(a))*hash11(seed + float(iFrame/rand_interval)))

//i.e. diffusion 
#define distribution_size 1.7

//slime mold sensors
#define sense_num 12
#define sense_ang 0.2
#define sense_dis 40.
//weird oscillation force
#define sense_oscil 0.0 
#define oscil_scale 1.
#define oscil_pow 1.
#define sense_force 0.11
//slime mold sensor distance power law dist = sense_dispow(rho, pw)
#define distance_scale 0.
#define force_scale 2.
#define acceleration 0.

#define density_normalization_speed 0.25
#define density_target 0.24
#define vorticity_confinement 0.0

//useful functions
#define GS(x) exp(-dot(x,x))
#define GSS(x) exp(-dot(x,x))
#define GS0(x) exp(-length(x))
#define Dir(ang) vec2(cos(ang), sin(ang))
#define Rot(ang) mat2(cos(ang), sin(ang), -sin(ang), cos(ang))
#define loop(i,x) for(int i = 0; i < x; i++)
#define range(i,a,b) for(int i = a; i <= b; i++)

//SPH pressure
   
//density*temp = pressure - i.e. ideal gas law
#define Pressure(rho) 0.9*rho.z
#define fluid_rho 0.2


//data packing
#define PACK(X) ( uint(round(65534.0*clamp(0.5*X.x+0.5, 0., 1.))) + \
           65535u*uint(round(65534.0*clamp(0.5*X.y+0.5, 0., 1.))) )   
               
#define UNPACK(X) (clamp(vec2(X%65535u, X/65535u)/65534.0, 0.,1.)*2.0 - 1.0)              

#define DECODE(X) UNPACK(floatBitsToUint(X))
#define ENCODE(X) uintBitsToFloat(PACK(X))