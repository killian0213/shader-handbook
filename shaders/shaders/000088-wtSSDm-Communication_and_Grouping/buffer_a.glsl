// Buffer A (buffer) — Communication and Grouping by wyatt
// https://www.shadertoy.com/view/wtSSDm

void swap (inout vec4 Q, vec2 U, vec2 r) {
	vec4 n = A(U+r);
    if (length(U-n.xy)<length(U-Q.xy)) Q = n;
} 
void mainImage( out vec4 Q, in vec2 U )
{
   Q = A(U);
   swap(Q,U, vec2(0,1));
   swap(Q,U, vec2(1,0));
   swap(Q,U,-vec2(0,1));
   swap(Q,U,-vec2(1,0));
   swap(Q,U, vec2(1,1));
   swap(Q,U, vec2(1,-1));
   swap(Q,U,-vec2(1,1));
   swap(Q,U,-vec2(1,-1));
   swap(Q,U, vec2(0,2));
   swap(Q,U, vec2(2,0));
   swap(Q,U,-vec2(0,2));
   swap(Q,U,-vec2(2,0));
    
    vec2 u = mix(Q.xy,U,0.);
    vec4
        n = D(u+vec2(0,1)),
        e = D(u+vec2(1,0)),
        s = D(u-vec2(0,1)),
        w = D(u-vec2(1,0));
    Q.xy -= .5*Q.zw;
    vec2
        g = vec2(e.w-w.w,n.w-s.w);
    Q.zw = -g;
    if (length(Q.zw)>1.) Q.zw = normalize(Q.zw);
  	
    if (iFrame < 1||(iMouse.z>0.&&length(U-iMouse.xy)<10.)){
        vec2 u =floor(U/10.+0.5)*10.;
        Q = vec4(u,0,0);
    }
}