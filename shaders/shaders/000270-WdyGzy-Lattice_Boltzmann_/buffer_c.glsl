// Buffer C (buffer) — Lattice Boltzmann  by wyatt
// https://www.shadertoy.com/view/WdyGzy

// Lighting on Buffer B
#define R iResolution.xy
#define T(U) texture(iChannel0,(U)/R)

void mainImage( out vec4 Q, vec2 U )
{
   Q =  1.2-2.2*T(U);
    Q.xyz = Q.xyz+.5*normalize(Q.xyz);
   float
       n = length(T(U+vec2(0,1))),
       e = length(T(U+vec2(1,0))),
       s = length(T(U-vec2(0,1))),
       w = length(T(U-vec2(1,0)));
    vec3 no = normalize(vec3(e-w,n-s,1));
    float d = dot(reflect(no,vec3(0,0,1)),normalize(vec3(1)));
    Q *= 8.*exp(-3.*d*d);
}