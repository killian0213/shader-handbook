// Common (common) — Fast voronoi interpolation by michael0884
// https://www.shadertoy.com/view/ts3XWf

#define size iResolution.xy
#define SAMPLE(a, p, s) texture((a), (p)/s)

float gauss(vec2 x, float r)
{
    return exp(-pow(length(x)/r,2.));
}
#define SPEED
#define BLASTER
   
#define PI 3.14159265

#ifdef SPEED
//high speed
    #define dt 8.5
    #define P 0.007
#else
//high precision
 	#define dt 2.
    #define P 0.05
#endif

//how many particles per pixel, 1 is max
#define particle_density 1.
#define minimal_density 0.02

const float radius = 2.0;
