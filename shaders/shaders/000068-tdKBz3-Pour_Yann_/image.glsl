// Image (image) — Pour Yann  by wyatt
// https://www.shadertoy.com/view/tdKBz3

// Fork of "Line Tracking Fluid" by wyatt. https://shadertoy.com/view/tsKXzd
// 2020-12-10 19:40:02

void mainImage( out vec4 Q, in vec2 U )
{
    vec4 a = A(U);
    vec4 d = D(U);
    float l = ln(U,a.xy,a.zw);
    Q = (.8+.2*d.xxxx)*smoothstep(0.,1.,l);
    
}