// Buffer A (buffer) — maze worms / graffitis 3c by FabriceNeyret2
// https://www.shadertoy.com/view/Xs2cRD

#define CS(a)  vec2(cos(a),sin(a))
#define rnd(x) ( 2.* fract(456.68*sin(1e3*x+mod(iDate.w,100.))) -1.) // NB: mod(t,1.) for less packed pattern
#define T(U) textureLod(iChannel0, (U)/R, 0.)
const float r = 1.5, N = 100., da = .1; // width , number of worms , turn angle at hit

void mainImage( out vec4 O, vec2 U )
{
    vec2 R = iResolution.xy;
    
    if (T(R).x==0.) { U = abs(U/R*2.-1.); O  = vec4(max(U.x,U.y)>1.-r/R.y); O.w=0.; return; } // track window resize

      // 1st column store worms state.
    if (U.y==.5 && T(U).w==0.) {                           // initialize heads state: P, a, t
        O = vec4( R/2. + R/2.4* vec2(rnd(U.x),rnd(U.x+.1)) , 3.14 * rnd(U.x+.2), 1);
        if (T(O.xy).x>0.) O.w = 0.;                        // invalid start position
        return;
    } // Other columns do the drawing.
    
    O = T(U);
    
    for (float x=.5; x<N; x++) {                           // --- draw heads
        vec4 P = T(vec2(x,.5));                            // head state: P, a, t
        if (P.w>0.) O += smoothstep(r,0., length(P.xy-U))  // draw head if active
                         *(.5+.5*sin(6.3*x/N+vec4(0,-2.1,2.1,1)));   // coloring scheme
    }
    
    if (U.y==.5) {                                         // --- head programms: worm strategy
        vec4 P = T(U);                                     // head state: P, a, t
        if (P.w>0.) {                                      // if active
            float a = P.z-1.6, a0=a;  // why can't angle start more rear ?
#define next T(P.xy+(r+2.)*CS(a)).w
//#define next T(P.xy+((r+2.)*1.5)*CS(a)).w  // if rear angle = dir - 3pi/4
            while ( next == 0. && a < 13. )  a += da;      // seek for last angle before hit
            a = max(a0, a-4.*da);
            if ( next > 0.) { O.w = 0.; return; }          // stop head
            O = vec4(P.xy+CS(a),mod(a,6.2832),P.w+1.);     // move head
        }
    }
   
  //if (iMouse.w > 0. && distance(iMouse.xy, U) < 50.) O = vec4(0.); // painting
}