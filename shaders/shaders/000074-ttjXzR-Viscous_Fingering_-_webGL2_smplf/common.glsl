// Common (common) — Viscous Fingering - webGL2 smplf by FabriceNeyret2
// https://www.shadertoy.com/view/ttjXzR

#define R    iResolution.xy//
#define T(d) texelFetch(iChannel0, ivec2(d+U)%ivec2(R),0)