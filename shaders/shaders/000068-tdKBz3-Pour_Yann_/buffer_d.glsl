// Buffer D (buffer) — Pour Yann  by wyatt
// https://www.shadertoy.com/view/tdKBz3

vec4 T(vec2 U) {
	U -= .5*D(U).xy;
	U -= .5*D(U).xy;
    return D(U);
}
Main {
    Q = T(U);
    vec4 
        n = T(U+o.yx),
        e = T(U+o.xy),
        s = T(U+o.yz),
        w = T(U+o.zy),
        m = 0.25*(n+e+s+w);
    Q.xy = m.xy-0.25*vec2(e.z-w.z,n.z-s.z);
	Q.z = Q.z-0.25*(n.y+e.x-s.y-w.x);
    vec4 a = A(U);
    float l = ln(U,a.xy,a.zw);
    float v = smoothstep(1.,0.,l);
    Q.z += 0.01*v;
    Q.xy = mix(Q.xy,norm(a.xy-a.zw),.1*v);
    Q.xy *= .99-.5*v;
    if (U.x<1.||R.x-U.x<1.||U.y<1.||R.y-U.y<1.) Q.xy *= 0.;
	if (iFrame < 1) Q = vec4(0,0,0,0);
}