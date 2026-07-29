// Buffer D (buffer) — Lattice Boltzmann  by wyatt
// https://www.shadertoy.com/view/WdyGzy

// TRANSLATE LOCATION FIELD WITH v(A(coord)), INIT WITH FragCoord
#define R iResolution.xy
#define A(U) texture(iChannel0,(U)/R)
#define d(U) texture(iChannel1,(U)/R)
#define C(U) texture(iChannel2,(U)/R)
vec2 v (vec4 b) {
	return vec2(b.x-b.y,b.z-b.w);
}
vec4 D(vec2 U) {
    U-=.5*v(A(U));
    U-=.5*v(A(U));
	return d(U);
}
void mainImage( out vec4 Q, in vec2  U)
{
    Q = D(U);
    
    vec4 
        q = A(U),
        n = A(U+vec2(0,1)),
        e = A(U+vec2(1,0)),
        s = A(U-vec2(0,1)),
        w = A(U-vec2(1,0)),
        N = D(U+vec2(0,1)),
        E = D(U+vec2(1,0)),
        S = D(U-vec2(0,1)),
        W = D(U-vec2(1,0));
    Q += 0.25*((n.w-q.z)*(N-Q) + (e.y-q.x)*(E-Q) + (s.z-q.w)*(S-Q) + (w.x-q.y)*(W-Q));
    
    if (iFrame < 1||(iMouse.z>0.&&length(U-iMouse.xy)<R.y/5.)) Q = vec4(U,0,0);
}