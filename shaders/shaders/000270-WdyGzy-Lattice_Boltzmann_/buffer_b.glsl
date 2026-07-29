// Buffer B (buffer) — Lattice Boltzmann  by wyatt
// https://www.shadertoy.com/view/WdyGzy

// LOOK UP PICTURE IN LOCATION FROM BUFFER D
#define R iResolution.xy
#define T(U) texture(iChannel0,(U)/R)
#define D(U) texture(iChannel1,(U)/R)
void mainImage( out vec4 Q, vec2 U )
{
    Q = texture(iChannel2,D(U).xy/R);
}