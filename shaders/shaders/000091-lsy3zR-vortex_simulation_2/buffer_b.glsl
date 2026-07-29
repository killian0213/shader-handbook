// Buffer B (buffer) — vortex simulation 2 by FabriceNeyret2
// https://www.shadertoy.com/view/lsy3zR

// semi-Newton integration of Biot-Savart velocity field induced by vortex particles
// inspired from http://evasion.imag.fr/~Fabrice.Neyret/demos/JS/Vort.html

#define N 20         // N*N partics. to be changed in all tabs !
#define Nf float(N)
#define MARKERS .90  // % of passive markers
#define BINARY 0     // are vorticities distributed or binaries ( -1 or 1 )
#define CYCLE 2      // evaluate forces through cycling world 0:no 1:full 2:cheap
float STRENGTH  = 1e3 * .25/(1.-MARKERS)*sqrt(30./Nf);

#define tex(i,j)    texture(iChannel1, (vec2(i,j)+.5)/iResolution.xy)
#define rand2(U)    fract(1e5*sin(mat2(17.1,191.7,-31.1,241.7)*U))
#define W(i,j)      tex(i,j+N).z

    
void mainImage( out vec4 O, vec2 U )
{
    vec2 T = floor(U/Nf); // several grids are mapped in the buffer
    // tile (0,0).xy , zw : pos, velocity of pass 1  (init from pass 2 output)
    // tile (0,1).z         vorticity
    // tile (0,2).xy , zw : backup of ref pos, velocity  ( UNUSED )
    
    if (iFrame < 10) {   // ----- initialization
        O = vec4( U + 3.*rand2(U),      // P0
                  2.*rand2(U+7.13)-1.);  // V0 (for gravity) or W (if tile(0,1) )
        O.xy *= iResolution.xy/Nf;

        if (T==vec2(0,1)) 
            if (.5+.5*O.w < MARKERS) O.z = 0.;   // W = 0 : passive markers
        	else if (BINARY==1) O.z = sign(O.z); // binary mode: all active |W|=1
        return; 
    }
    
    if (T==vec2(0,1))
        O = texture(iChannel0, U/iResolution.xy);  // for buffer persistency 
    
    U = mod(U,Nf);      // U = particle id ( N*N particles )
    
    //if ( T == vec2(0,2) )  // backup ref positions ( UNUSED )
    //    { O = refState(U); return; }
    
    int pass = 0;
    float dt = iTimeDelta; 
    
    if ( T == vec2(0,0) ) { // pass 1 : 1/2 time step from ref position (to get V)
        pass = 2; 
        O = texture(iChannel1, U/iResolution.xy);
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
    for (int j=0; j<N; j++)
        for (int i=0; i<N; i++) 
        {
            float w = W(i,j);
            // we could optimize by not considering markers, but the main cost is not there.
            vec2 d = tex(i,j).xy - O.xy;
#if CYCLE == 1
            d += iResolution.xy*vec2(cx,cy);
#elif CYCLE == 2     // cycling world : clipped to most contributive window
            d = ( fract(.5+d/iResolution.xy) -.5)*iResolution.xy;
#endif
            float l = dot(d,d);
         // if (l>1e-5) F += d /l;                   // Newton, for gravity 
            if (l>1e-5) F += vec2(-d.y,d.x) * w /l;  // Biot-Savart, for vorticity
            }
    
 // O.zw += 1e-1*F*dt;    // v += sum(F).dt   for Newton
    O.zw = STRENGTH*F;    // direct eval of V (stored as F) for Biot-Savart
    if (pass==2)   // increment from ref pos, not pass 1 pos
        O.xy = texture(iChannel0, U/iResolution.xy).xy;
    //  O.xy = texture(iChannel0, (U+vec2(0,2)*Nf)/iResolution.xy).xy; // from backup
    O.xy += O.zw*dt;      // x += v.dt
    O.xy = mod(O.xy, iResolution.xy);
  
}

