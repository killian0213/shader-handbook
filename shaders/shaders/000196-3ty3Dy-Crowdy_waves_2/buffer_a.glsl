// Buffer A (buffer) — Crowdy waves 2 by FabriceNeyret2
// https://www.shadertoy.com/view/3ty3Dy

// === Physics: manage particles pos+V: advect & react
// see also: Boids physics https://www.shadertoy.com/results?query=boids

void mainImage( out vec4 O, vec2 I )
{
    O = T0(I);              // previous state
    
    O.xy = mod(O.xy,R);     // cyclical world
  //vec4 r = rand4( int(I.x) + int(I.y)*2048 + iFrame*2048*2048);   // deterministic
  //vec4 r = rand4( int(I.x) + int(I.y)*2048 + (int(iTime*2048.)+iFrame)*2048);
    vec4 r = rand4( int(I.x) + int(I.y)*2141 + (int(iTime*2141.)+iFrame)*2141); // without 2048 bias
    
    if(iFrame<3)            // init: random location, random V , |V|= 1/4
        O.xy = r.xy*R,
        O.zw = .25*cos(TAU*(vec2(0,.25)+r.z));

    
#if 1                       // --- emulate pressure & viscosity (is also boids/schoolfish coeherence)
    vec4 a = T1(O.xy);      // get the 4 ids in Voronoï buffer at particle location
    vec2 ns = vec2(0),      //         (should be the closest)
         df = vec2(0), D;
    for(int i = 0; i < 4; i++){ 
        vec4 n = A(a[i]);
        ns += n.zw/4.;      // average velocity
        D = O.xy - n.xy;
        D = mod( D + R/2., R ) - R/2.;
                            // repulsed by nearby particles  
        if( l2(D) > l2(.005) && l2(D) < l2(10.) )
        	df += normalize(D)/(length(D)+.03);
    }
    O.zw += df/25.;         // pressure: apply repulsion force
    O.zw = mix(O.zw,ns,.1); // visc: V = average Vpartic + relax(oldV+centering)
#endif
    
    if(l2(O.zw) > l2(.001)) // |V| = 1/4 + relax(oldV)
    	O.zw = mix(O.zw, normalize(O.zw)/4.,.05);
    
    O.zw += randn(r.xy)/1e2; // --- add a bit of random force [init/resized=superimposed]

    if(iMouse.z > 0.){         // --- mouse action on particles
        vec2 D = O.xy-iMouse.xy, F = D;           // default: repulse
        if keyDown(64+4 ) F = -D;                 // "D": drain
        if keyDown(64+19) F = vec2( -D.y, D.x);   // "S": swirl
        if keyDown(64+16) F = iMouse.xy-iMouse.zw;// "P": push
        O.zw += normalize(F+1e-5)/(length(D)+.03);
    }
    O.xy += O.zw;  // pos += V  (indeed V contains dx/dt )
    
}