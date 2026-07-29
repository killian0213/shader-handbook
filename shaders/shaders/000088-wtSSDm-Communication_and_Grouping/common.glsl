// Common (common) — Communication and Grouping by wyatt
// https://www.shadertoy.com/view/wtSSDm

#define R iResolution.xy
#define A(U) texture(iChannel0,(U)/R)
#define B(U) texture(iChannel1,(U)/R)
#define C(U) texture(iChannel2,(U)/R)
#define D(U) texture(iChannel3,(U)/R)

#define O vec4(.01,.2,.5,.01)
#define I 20