// Common (common) — Volumetric Fluid by wyatt
// https://www.shadertoy.com/view/ws2fDc

#define N 10.
#define R iResolution.xy
#define R3D vec3(R/N,N*N)
#define d2(U) ((U).xy+vec2(mod(floor((U).z),N),floor(floor((U).z)/N))*R/N)
#define d3(u) vec3(mod(u,R/N),floor(u/R*N).x+floor(u/R*N).y*N)
#define e(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define A(U) texture(iChannel0, d2(mod(U,R3D))/R)
#define B(U) texture(iChannel1,d2(mod(U,R3D))/R)
#define Sampler vec4 T(vec3 U) {return mix(texture(iChannel0,d2(vec3(U.xy,floor(U.z)))/R),texture(iChannel0,d2(vec3(U.xy, ceil(U.z)))/R),fract(U.z));}
#define Sampler1 vec4 T1(vec3 U) {return mix(texture(iChannel1,d2(vec3(U.xy,floor(U.z)))/R),texture(iChannel1,d2(vec3(U.xy, ceil(U.z)))/R),fract(U.z));}
#define Main void mainImage( out vec4 Q, in vec2 u )
#define _3D  vec3 U = d3(u)
#define Neighborhood vec4 n = A(U+vec3(0,1,0)), e = A(U+vec3(1,0,0)), f = A(U+vec3(0,0,1)), s = A(U-vec3(0,1,0)), w = A(U-vec3(1,0,0)), b = A(U-vec3(0,0,1));
#define Init  if (iFrame < 1) 