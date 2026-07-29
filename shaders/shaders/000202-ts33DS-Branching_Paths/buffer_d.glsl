// Buffer D (buffer) — Branching Paths by wyatt
// https://www.shadertoy.com/view/ts33DS

#define R iResolution.xy
#define A(U) texture(iChannel0,(U)/R)
vec4 X (inout vec2 c,inout float m, vec2 u, vec2 r) {
    vec4 n = A(u+r);
    m += n.z;
	if (length(u+r-n.xy)<length(u-c)) c = n.xy;
    return n;
} 
void mainImage( out vec4 Q, vec2 U )
{
    Q = A(U);
    vec2 c = Q.xy;
    float m=0.;
    vec4 
        n = X(c,m,U,+vec2(0,1)),
        e = X(c,m,U,+vec2(1,0)),
        s = X(c,m,U,-vec2(0,1)),
        w = X(c,m,U,-vec2(1,0));
    X(c,m,U,vec2(1,1));
    X(c,m,U,vec2(1,-1));
    X(c,m,U,vec2(-1,1));
    X(c,m,U,vec2(-1,-1));
    vec2 g = vec2(e.z-w.z,n.z-s.z);
    Q.xy = c;
    Q.z += (m/8.-Q).z+.05*Q.w - .0001*Q.z;
    Q.w -= 0.001*Q.w;
    Q.zw = max(Q.zw,vec2(2,1)*smoothstep(4.,0.0,length(U-c)));
    Q.xy -= 0.25*g;
    if (length(U-iMouse.xy)<.3*R.y&&iMouse.z>0.) Q = vec4(-R,Q.z,0);
    if (iFrame < 1) Q = vec4(clamp(floor(U/2.)*2.,0.5*R-2.,0.5*R+2.),0,0);
    
}