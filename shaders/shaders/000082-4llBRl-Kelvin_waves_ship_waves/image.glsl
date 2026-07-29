// Image (image) — Kelvin waves / ship waves by FabriceNeyret2
// https://www.shadertoy.com/view/4llBRl

void mainImage( out vec4 O, vec2 U )
{
	vec2 R = iResolution.xy, 
         M = length(iMouse.xy) > 10. ? iMouse.xy / R : vec2(.55,.7);
    O = vec4(0);
    U = ( 2.*U - R ) / R.y;  U.x += 1.2;
 
    float  S = 1.,                                // invariant scaling factor
           V = 10./sqrt(S),                       // [m/s] boat spead
           L = 2500./S,                           // [m] screen->world scaling
          l0 = 2.*L*M.x,                          // boat scale - peak of emission spectrum
           W =  128./S*exp2(5.*M.y),              // width of spectrum of emission
           dx = 2./R.y;                           // pixel size. Multiply for more FPS
    if ( U.x< 0. ) { O += .5; return;}            // 2 optimizations
    if ( R.y>200. && abs(U.y*R.y)>100.) dx *= 8.*abs(U.y);
    
    for (float x = 0.; x<=5.; x += dx ) {         // sum pulse emitted at each past location
        vec2 P = U  - vec2(x,.2*sin(2.*x-iTime)); // pixel position in past boat frame
        float l = length(P)*L, 
              k = 6.283/(2.*l),                   // k=2pi/L, energy at l=L/2 since Cg = 1/2 Cphi
              t = x*L/V,                          // time where boat was at x (approx)
              a = 3.1416 - sqrt(9.81*k) *t,       // cos(kl-wt), kl=pi, w=sqrt(gk)  
              v = (l-l0)/W;                       // ( Dispersion relations: https://en.wikipedia.org/wiki/Dispersion_(water_waves)
        O +=  cos(a) / l  * exp(-.5*v*v);         // spectrum of wave emission by the boat
    }
    O = .5 + .5* O*dx *1.7e3/S;
}