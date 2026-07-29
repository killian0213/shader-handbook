// Buffer D (buffer) — Ecosystem by wyatt
// https://www.shadertoy.com/view/3tjGDh

//Diffusion on fluid
void mainImage( out vec4 Q, in vec2 U )
{
    vec4 b = B(U), a= A(U);
    U -= .5*a.xy;
    Q = C(U);
    vec4 
        n = C(U+vec2(0,1)),
        e = C(U+vec2(1,0)),
        s = C(U-vec2(0,1)),
        w = C(U-vec2(1,0));
    Q = mix(Q,0.25*(n+e+s+w),.2*vec4(2,3,4,5));
    vec4 h = hash(b.w);
    Q += .1*(h-Q)*smoothstep(1.,0.,length(b.xy-U));
    
    if (iFrame < 1) Q = vec4(0);
}