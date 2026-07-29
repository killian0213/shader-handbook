// Common (common) — Pour Yann  by wyatt
// https://www.shadertoy.com/view/tdKBz3

#define R iResolution.xy
#define o vec3(1,0,-1)
#define A(U) texture(iChannel0,(U)/R)
#define B(U) texture(iChannel1,(U)/R)
#define C(U) texture(iChannel2,(U)/R)
#define D(U) texture(iChannel3,(U)/R)
#define Main void mainImage(out vec4 Q, vec2 U)
float ln (vec2 p, vec2 a, vec2 b) {
	return length(p-a-(b-a)*clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,.9));
}
#define norm(u) ((u)/(1e-9+length(u)))