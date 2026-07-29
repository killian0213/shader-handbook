// Buffer B (buffer) — vortex simulation+Voronoi track by FabriceNeyret2
// https://www.shadertoy.com/view/wtyGWc

// === semi-Newton (aka Verlet)  integration of Biot-Savart velocity field induced by vortex particles
// inspired from http://evasion.imag.fr/~Fabrice.Neyret/demos/JS/Vort.html
    
void mainImage( out vec4 O, vec2 U )
{
    O-=O;
    vec2 T = floor(U/Nf); // several grids are mapped in the buffer
    // tile (0,0).xy , zw : pos, velocity of pass 1  (init from pass 2 output)
    // tile (0,1).z         vorticity
    // tile (0,2).xy , zw : backup of ref pos, velocity  ( UNUSED )
    
    if (iFrame < 1) {   // ----- initialization
        O = vec4( R * rand2(U),         // P0
                  2.*rand2(U+7.13)-1.); // V0 (for gravity) or W (if tile(0,1) )

        if (T==vec2(0,1)) 
            if (int(U.x)+N*(int(U.y)%N) > Nvort)  O.z = 0.;  // W = 0 : passive markers
        	else if (BINARY==1) O.z = sign(O.z); // binary mode: all active |W|=1
        return; 
    }
    
    if (T==vec2(0,1))
        O = T1(U);          // for buffer persistency 
    
    U = mod(U,Nf);          // U = particle id ( N*N particles )
    
  //if ( T == vec2(0,2) )   // backup ref positions ( UNUSED )
  //    { O = refState(U); return; }
    
    int pass = 0;
    float dt = iFrame < 10 ? 1./60. : iTimeDelta; 
    
    if ( T == vec2(0,0) ) { // pass 1 : 1/2 time step from ref position (to get V)
        pass = 2; 
        O = T1(U);
    }
    else if (pass==0) return;
    
    // if pass 1: compute tmp pos(v) at half time-step
    // if pass 2: compute new pos using velocities(tmppos) and ref pos

    // ----- evaluate forces (Newton, for gravity) 
    //         or directly velocity (Biot-Savart, for vorticity)
    vec2 F = vec2(0);
 
#if CYCLE == 1         // forces through cycling world
    for (int cx=-1; cx<2; cx++)
      for (int cy=-1; cy<2; cy++)
#endif
    for (int k=0; k<Nvort; k++) {
            vec2 P = vec2(k%N,k/N), d = T1(P).xy - O.xy;
            float w = W(P);
            BINARY == 2 ? w = .5*sign(w) : w;
#if CYCLE == 1
            d += R*vec2(cx,cy);
#elif CYCLE == 2     // cycling world : clipped to most contributive window
            d = ( fract(.5+d/R) -.5)*R;
#endif
            float l = dot(d,d);
         // if (l>1e-5) F += d /l;                   // Newton, for gravity 
            if (l>1e-5) F += vec2(-d.y,d.x) * w /l;  // Biot-Savart, for vorticity
            }
    
 // O.zw += 1e-1*F*dt;    // v += sum(F).dt   for Newton
    O.zw = STRENGTH*F;    // direct eval of V (stored as F) for Biot-Savart
    if (pass==2)   // increment from ref pos, not pass 1 pos
        O.xy = T0(U).xy;
    O.xy += O.zw*dt;      // x += v.dt
    O.xy = mod(O.xy, R);
  
}

