// Common (common) — Ecosystem by wyatt
// https://www.shadertoy.com/view/3tjGDh

#define R iResolution.xy
#define A(U) texture(iChannel0, (U)/R)
#define B(U) texture(iChannel1, (U)/R)
#define C(U) texture(iChannel2, (U)/R)
#define D(U) texture(iChannel3, (U)/R)


#define S vec4(2,4,6,8)
#define M .5*vec4(4,3,2,1)
#define O .5/S/S
#define I 12.

vec4 hash (float p) // Dave (Hash)kins
{
	vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx)*2.-1.;
    
}