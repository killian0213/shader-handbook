// Common (common) — What! Are you Kidding me? 1234 by wyatt
// https://www.shadertoy.com/view/wllSRr

#define R iResolution.xy

#define A(U) texture(iChannel0, (U)/R)
#define B(U) texture(iChannel1, (U)/R)
#define C(U) texture(iChannel2, (U)/R)
#define D(U) texture(iChannel3, (U)/R)


// Affects scale  :
#define k .5