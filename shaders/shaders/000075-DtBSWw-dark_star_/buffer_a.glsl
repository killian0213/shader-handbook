// Buffer A (buffer) — dark star  by FabriceNeyret2
// https://www.shadertoy.com/view/DtBSWw

void mainImage( out vec4 O, vec2 u )
{
    vec4 V; r = iResolution.xy; t = iTime;  // Complicated transmission of iResolution, iChannel0, iTime, because shadertoy :-(
    O = Image( V, u, iChannel0 );
    O = clamp(O, 0.,1.);
    
/*
    #define R(a) mat2(cos(a+vec4(0,11,33,0)))

    vec2  r = iResolution.xy,
          p = (u+u-r) / r.y, q, n=r-r;
    float S = 6.,a=0.,i=a, d = dot(p,p), e = 2e2, t = iTime, s=a;
    p = p/( .7-d ) + t/3.14;
    for( O *= 0. ; i++ < e ; O += texture( iChannel0, (u/r-.5)*i/e+.5 ) / e)
        p *= R(5.), n *= R(5.),
        a += dot( sin( q = p*S +i -abs(n)*R(t*.2) ) / S, r/r ),
        n += cos(q), 
        S *= 1.1;
    a = max( s, .9 -a*.2 -d );
    O = pow( a+ a*vec4(8,4,1,0)/e , O+40. );
*/
}