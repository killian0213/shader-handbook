// Buffer A (buffer) — Pour Yann  by wyatt
// https://www.shadertoy.com/view/tdKBz3

void X (inout vec4 Q, vec2 U, vec2 r) {
    vec4 n = A(U+r);
	if (ln(U,n.xy,n.zw)<ln(U,Q.xy,Q.zw)) Q = n;
}
Main {
    Q = A(U);
    for (int x = -2;x <=2; x++)
    for (int y = -2;y <=2; y++)
    X(Q,U,vec2(x,y));
    Q.xy = mix(Q.xy,A(Q.xy).xy,.3);
    Q.zw = mix(Q.zw,A(Q.zw).zw,.05);
    Q.xy += D(Q.xy).xy;
    Q.zw += D(Q.zw).xy;
    
    if (length(Q.xy-Q.zw) > 2.5) {
        vec2 m = 0.5*(Q.xy+Q.zw);
        if (length(U-Q.xy) > length(U-Q.zw)) 
        	Q.xy = m;
        else Q.zw = m;
    }
    if (iMouse.z>0.) {
        vec4 n = B(vec2(0));
    	if (ln(U,n.xy,n.zw)<ln(U,Q.xy,Q.zw)) Q = n;
    }
    if (iFrame<1) {
        Q = vec4(0.7*R,0.3*R);
        vec4 a =vec4(vec2(0.3,.7)*R,vec2(.7,.3)*R);
        if (ln(U,a.xy,a.zw)<ln(U,Q.xy,Q.zw))
            Q = a;
    }

}