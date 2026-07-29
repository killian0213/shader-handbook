// Buffer B (buffer) — What! Are you Kidding me? 1234 by wyatt
// https://www.shadertoy.com/view/wllSRr

void mainImage( out vec4 Q, in vec2 U )
{
    Q = B(U);
    vec4 a = A(U);
    vec4 c = C(U);
    vec4 dm = 1./4.*(
    	A(U+vec2(1,0))+
        A(U+vec2(0,1))+
        A(U-vec2(1,0))+
        A(U-vec2(0,1))
    )-a;
    vec4 dmb = 1./4.*(
    	B(U+vec2(1,0))+
        B(U+vec2(0,1))+
        B(U-vec2(1,0))+
        B(U-vec2(0,1))
    )-Q;
    Q += dm + k/36.*dmb;
    float mag = sqrt(a.w*a.w+dot(c.xy,c.xy)+dot(a.xyz,a.xyz));
    if (length(a.xyz)>0.) Q.xyz -= 3./6.*k*a.xyz/length(a.xyz);
	if (abs(a.w)>0.) Q.w-= k/6.*a.w/abs(a.w);
    if (mag > 0.) Q += k/6.*a/mag;
}