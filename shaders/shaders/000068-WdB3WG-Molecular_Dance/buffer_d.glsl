// Buffer D (buffer) — Molecular Dance by wyatt
// https://www.shadertoy.com/view/WdB3WG

//Gradient calculation for caustic
vec2 R;
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
vec4 D (vec2 U) {return texture(iChannel3,U/R);}
void mainImage( out vec4 Q, in vec2 U )
{	R = iResolution.xy;
 	vec4 a = A(U);
 	float r=smoothstep(4.,1.,length(U-a.xy));
	Q = r*vec4(a.w,abs(a.w),-a.w,1);
 	Q = max(Q,D(U));
 	float 
        n = C(U+vec2(0,1)).x,
        e = C(U+vec2(1,0)).x,
        s = C(U+vec2(0,-1)).x,
        w = C(U+vec2(-1,0)).x;
 	Q.zw = vec2(e-w,n-s);
}
