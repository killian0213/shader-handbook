// Image (image) — crossbars 2 by FabriceNeyret2
// https://www.shadertoy.com/view/mdKXWh

// variant of https://shadertoy.com/view/msGXW1

  #define S(v)     smoothstep(0.,1., v)                   // for AAdraw AND for arc shape 
  #define H(p)     fract(sin((p+.17) * 12.9898) * 43.5453)// hash
  #define N(s,x)  (s)* floor( 4.*H(d+T-7.7*(X+x)+x)/(s) ) // random node(time#, ball#, stage#)
  #define R       (floor(iResolution.xy/8.)*8.)           // to avoid fwidth artifact
//#define arc(t) mix(i,j, S(fract(t)) ) - U.y             // arc trajectory
  #define arc(t) mix( i+sin(i*iTime)*.2*s, j+sin(j*iTime)*.4*s, S(fract(t)) ) - U.y // animated variant
           
void mainImage( out vec4 O, vec2 U )
{
    U = 4.*U/R - 2.;                                    // normalize window in [-2,2]² = 4 stages
    float s = exp2(-floor(1.-U.x)), S=s, i,j,v,n;       // 2 / number of nodes at each stage
    
    O = vec4(1);                                        // start with a white page
    for( i = .5*s-2.; i < 2.; i += s )                  // === drawing the net (same as ref)
        for( j = s-2.; j < 2.; j += s+s )               // on each stage, loop on in/out pairs
            v = arc(U.x),      
            O *= .5+.5* S( abs(v)/fwidth(v) );          // blacken-draw curve arc()=0

    for ( n=0.; n<1.; n+=.1 )  {                        // === drawing the balls                                  
        float d = H(n),                                 // lauch 10 per second, at random time d
              X = floor(U.x), x = U.x-X,                // X = stage#, T = time#
              t = 2.-iTime+d, T = floor(t); t-=T;       // t = x coords ( fract(t) do each stage in // )                                                      
        s = S;
        if (t<.1 && x>.9 ) s*=2., X++;                  // manage ball at stage transition
        if (t>.9 && x<.1 ) s/=2., X--;
        i = .5*s-2. + N(s   ,0.);                       // select in/out nodes ( mimic draw curve above )
        j =    s-2. + N(2.*s,1.);                       // 1: offset for the input nodes 
        v = arc(t);                                         
        O = mix( vec4(1,0,0,1), O,                      // blend-draw ball
                 S( length( vec2( fract(U.x-t+.5)-.5, v )*R/4. ) -5. ) );
    }                                                   // fract: to draw all stages in parallel
  
    O = sqrt(O);                                        // to sRGB
}