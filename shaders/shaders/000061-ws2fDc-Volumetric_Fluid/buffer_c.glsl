// Buffer C (buffer) — Volumetric Fluid by wyatt
// https://www.shadertoy.com/view/ws2fDc

Sampler
void F (vec3 U, vec3 u, vec4 Q, inout vec3 f, inout float m, inout float w, inout float n) {
    // Advect
    vec4 a = T(U+u-A(U+u).xyz);
    u = normalize(u);
    // gradient of pressure
    f += u*(a.w-Q.w);
    // average pressure
    m += a.w;
    // divergence of velocity
    w += dot(u,a.xyz);
    // number of neighbors sampled
    n++;
}
Main {
	_3D;
    
    Q = T(U-A(U).xyz);
    vec3 f = vec3(0);
    float w = 0.;
    float m = 0., n = 0.;
    
    
    F(U,vec3(1,0,0),Q,f,m,w,n);
    F(U,vec3(0,1,0),Q,f,m,w,n);
    F(U,vec3(0,0,1),Q,f,m,w,n);
    F(U,vec3(-1,0,0),Q,f,m,w,n);
    F(U,vec3(0,-1,0),Q,f,m,w,n);
    F(U,vec3(0,0,-1),Q,f,m,w,n);
    
    
    f /= n;
    w /= n;
    m /= n;
    Q.w = m - w;
    Q.xyz -= f;
    
    if (length(U-vec3(0.5,.5,0.9)*R3D) < 5. ) {
		    	Q.xyz = vec3(0,0,-.2)*(0.5+0.8*sin(.5*iTime));
		    }
     if (length(U-vec3(0.51,.9,.5)*R3D) < 4. ) {
		    	Q.xyz = vec3(0,-.4,0)*(0.5+0.8*sin(.2*iTime));
		    }
    if (length(U-vec3(0.5,.1,.5)*R3D) < 4. ) {
		    	Q.xyz = vec3(0,.4,0)*(0.5+0.8*sin(.4*iTime));
		    }
    if (U.x<1.||U.y<1.||U.z<1.||R3D.x-U.x<1.||R3D.y-U.y<1.||R3D.z-U.z<2.) Q.xyz *= 0.;
    
    
}