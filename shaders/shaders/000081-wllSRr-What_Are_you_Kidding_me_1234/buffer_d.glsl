// Buffer D (buffer) — What! Are you Kidding me? 1234 by wyatt
// https://www.shadertoy.com/view/wllSRr

void mainImage( out vec4 Q, in vec2 U )
{
    Q = D(U);
    vec4 a = A(U);
    vec4 c = C(U);
    vec4 dm = 1./4.*(
    	C(U+vec2(1,0))+
        C(U+vec2(0,1))+
        C(U-vec2(1,0))+
        C(U-vec2(0,1))
    )-c;
    vec4 dmd = 1./4.*(
    	D(U+vec2(1,0))+
        D(U+vec2(0,1))+
        D(U-vec2(1,0))+
        D(U-vec2(0,1))
    )-Q;
    Q += dm + k/36.*dmd;
    float mag = sqrt(a.w*a.w+dot(c.xy,c.xy)+dot(a.xyz,a.xyz));
    if (length(c.xy)>0.) Q.xy -= 2./6.*k*c.xy/length(c.xy);
    if (mag > 0.) Q.xy += k/6.*c.xy/mag;
}