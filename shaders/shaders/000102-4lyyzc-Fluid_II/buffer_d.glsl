// Buffer D (buffer) — Fluid II by wyatt
// https://www.shadertoy.com/view/4lyyzc

vec2 R;
vec4 T ( vec2 U ) {return texture(iChannel0,U/R);}
void mainImage( out vec4 Q, in vec2 U )
{   R = iResolution.xy;
 	
 	vec2 O = U,A = U+vec2(1,0),B = U+vec2(0,1),C = U+vec2(-1,0),D = U+vec2(0,-1);
 	vec4 u,a,b,c,d;
 	float p = 0.;
 	vec2 g = vec2(0);
 	#define I 2
 	for (int i = 0; i < I; i++) {
        u = T(U); U -= u.xy;
 		a = T(A); b = T(B); c = T(C); d = T(D);
        A -=a.xy; B -=b.xy; C -=c.xy; D -=d.xy; 
        p += length(U-A)+length(U-B)+length(U-C)+length(U-D)-4.;
        g += vec2(a.z-c.z,b.z-d.z);
 	}
 	u = T(U); a = T(A); b = T(B); c = T(C); d = T(D);
 	Q = T(U);
 	vec4 N = 0.25*(a+b+c+d);
 	Q = mix(Q,N, vec4(0,0,1,0));
 	Q.xy -= g/8./float(I);
 	Q.z += p/8.;
 	Q.z *= 0.9999;
 	if (iFrame < 1) Q = vec4(0,0,0,0);
 	if (length(U-vec2(0.925,0.5)*R) < 2.) Q.xyw = vec3(Q.xy*0.5+0.5*vec2(-0.2,0),1.);
 	if (U.x<1.||U.y<1.||R.x-U.x<1.||R.y-U.y<1.) Q.xy*=0.;
}