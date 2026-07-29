// Buffer A (buffer) — Lattice Boltzmann  by wyatt
// https://www.shadertoy.com/view/WdyGzy

// FLUID EVOLUTION
#define R iResolution.xy
#define T(U) texture(iChannel0,(U)/R)
#define D(U) texture(iChannel1,(U)/R)
#define B(U) texture(iChannel2,(U)/R)
// Velocity
vec2 v (vec4 b) {
	return vec2(b.x-b.y,b.z-b.w);
}
// Pressure
float p (vec4 b) {
	return 0.25*(b.x+b.y+b.z+b.w);
}
// TRANSLATE COORD BY Velocity THEN LOOKUP STATE
vec4 A(vec2 U) {
    U-=.5*v(T(U));
    U-=.5*v(T(U));
	return T(U);
}
void mainImage( out vec4 Q, in vec2  U)
{
    // THIS PIXEL
    Q = A(U);
    // NEIGHBORHOOD
    vec4 
        n = A(U+vec2(0,1)),
        e = A(U+vec2(1,0)),
        s = A(U-vec2(0,1)),
        w = A(U-vec2(1,0));
    // GRADIENT of PRESSURE
    float px = 0.25*(p(e)-p(w));
    float py = 0.25*(p(n)-p(s)); 
    
    		// boundary Energy exchange in :   
    Q += 0.25*(n.w + e.y + s.z + w.x)
        	// boundary Energy exchange out :
        	-p(Q)
        	// dV/dt = dP/dx,  dEnergy In dTime = dEnergy in dSpace
        	-vec4(px,-px,py,-py);
    
    // get value from picture buffer
    float z = .8-length(B(U).xyz);
    // some kind of viscolsity thing 
    Q = mix(mix(Q,0.25*(n+e+s+w),.01),vec4(p(Q)),.01*(1.-z));
    // gravity polarizes energy! pretty cool imo
    Q.zw -= 0.001*z*vec2(1,-1);
    // Init with no velocity and some pressure
    if (iFrame < 1||(iMouse.z>0.&&length(U-iMouse.xy)<R.y/5.)) Q = vec4(.2);
    // At boundarys turn all kinetic energy into potential energy
    if(U.x<3.||R.x-U.x<3.||U.y<3.||R.y-U.y<3.)Q = vec4(p(Q));
}