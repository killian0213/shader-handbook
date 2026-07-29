// Image (image) — Lattice Boltzmann  by wyatt
// https://www.shadertoy.com/view/WdyGzy

// LENS FLAIR EFFECT
#define R iResolution.xy
#define T(U) texture(iChannel0,(U)/R)
vec4 F (vec2 U,vec2 r) {
	vec4 t = T(U+r);
    return exp(-.01*dot(r,r))*(exp(2.*t)-1.);
}
void mainImage( out vec4 Q, vec2 U )
{
   
   Q = vec4(0);
    for (float i = 0.; i < 7.; i+=1.1) {
    	Q += F(U,+vec2(-i,i));
    	Q += F(U,+vec2(i,i));
    	Q += F(U,-vec2(-i,i));
    	Q += F(U,-vec2(i,i));
    }
    Q = T(U)*0.15+ 1e-5*Q;
    Q = atan(Q);
}