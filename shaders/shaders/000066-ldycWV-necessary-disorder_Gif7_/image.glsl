// Image (image) — necessary-disorder "Gif7" by FabriceNeyret2
// https://www.shadertoy.com/view/ldycWV

// #4b: https://shadertoy.com/view/MsGcWK
// #4: https://shadertoy.com/view/lsGcWK
// #3: https://shadertoy.com/view/MdGcWK
// shaking grid: https://www.shadertoy.com/view/MdyyWK
// #2: https://shadertoy.com/view/lsGyWK
// #1: https://shadertoy.com/view/MdGyWK

// http://www.thisiscolossal.com/2018/04/animation-of-sinusoidal-waves-in-gifs-by-etienne-jacob
// EJ's tutos: https://necessarydisorder.wordpress.com/

#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))          // rotation
#define S(D,e) smoothstep( 3., 0., length(D)*R.y -e )      // for antialiasing
vec2 A,B,R; float l;
#define line(p,a,b) ( l = dot(B=b-a, A=p-a)/dot(B,B), clamp(l,0.,1.) == l ? S(A-B*l,0.) : 0.)
//float line(vec2 p, vec2 a, vec2 b) {                     // draw a segment without round ends
//    b -= a; p -= a;
//    float l = dot(b,p)/dot(b,b);
//    return clamp(l, 0., 1.) == l ? S( p - b * l ,0.) : 0.;
//}

void mainImage( out vec4 O, vec2 U )
{
    R = iResolution.xy;
    U = ( U+U - R ) / R.y;
    O -= O;
    
    float v,f, t = 2.*iTime, T = 12., S=1.6, K = .05;
    mat2 M  = rot(6.283/8.), M2 = rot(6.283/48.);
    vec2 _P, P, Ui, Uj = U;
    
#define  P0(t) vec2(-.9,.4) + K* vec2(2.*cos(t+1.) ,sin(t+1.)  )
#define  P1(t) vec2(  0,.4) + K* vec2(2.*cos(t1(t)),-sin(t1(t)))
#define  t1(t)  S*(t) + .5*cos( S*(t) )

    // 48 curves = 8 angular copies (4+sym) of 6 dephased-curves 
    for (float j=0.; j<6.; j++, Uj*=M2 ) {         // 6 phases
        f  = t + 6.283*j/6.;
        _P= P0(f);
        for (float s=0.; s<1.; s+=.01) {           // draw delayed-interpolation P0 -> P1
            P = mix( P0(f-T*s) , P1(f-T*(1.-s)) , s ); 
            v =  1. + 1e2* length(P-_P);           // thicker when slow
            Ui = Uj;
            for (int i = 0; i < 4; i++, Ui*= M )   // 4 angular copies
                O += line(Ui*sign(Ui.y),_P,P) / v; // + central symmetry
            _P = P;                                // NB: doable to use 2ble symmetry
        }
        for (int i = 0; i < 8; i++, Ui*= M )       // draw dots
            O += S(P0(f)-Ui, 2.),
            O += S(P1(f)-Ui, 2.);
   }
}