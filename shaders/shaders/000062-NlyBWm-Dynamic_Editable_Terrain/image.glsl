// Image (image) — Dynamic Editable Terrain by fenix
// https://www.shadertoy.com/view/NlyBWm

// ---------------------------------------------------------------------------------------
// Created by fenix in 2022
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// This is running the same kind of annealing algorithm as my shader a few days ago:
//
//   Metal Recrystalization https://www.shadertoy.com/view/flVBRw
//
// At the edge of the rendering range, the material is melted and randomized. You can
// see this sometimes when the camera swings up, there is a sort of rain where the
// annealing process takes places and the world is created.
//
// Closer to the camera, the mutation rate is slowed, but still remains reactive to
// edits from the player. The idea of the mouse input is that when you hold a number key,
// you create terrain at that height. Without a number key, you remove terrain.
//
// As the camera moves, the area within Buffer A that is melted moves with it, so that by
// the time you return, any edits will have been erased by the melting and crystalizing
// process. And return ye shall, since the buffer itself, rendering, etc are all set up
// to wrap when the camera reaches the edge.
//
// The fancy rendering effects are disabled automatically at very high resolutions,
// because my computer falls over trying to run them. You can click the shift key
// to toggle them to override my settings. You might want to disable them to push
// your FPS up to 60 at some resolutions.
//
// Buffer A computes the terrain
// Buffer B renders with ray march
// Buffer C renders xor's Nimbostratus for the sky: https://www.shadertoy.com/view/Xl
// Image applies tilt-shift lens effect
//
// --------------------------------------------------------------------------------------------

// based on gaussian blur from FabriceNeyret2's smart gaussian blur: https://www.shadertoy.com/view/WtKfD3

int           N =  7;                              // target sampling rate
float         w,                                   // filter width
              z;                                        // LOD MIPmap level to use for integration 
#define init  z = ceil(max(0.,log2(w*R.y/float(N))));   // N/w = res/2^z
#define R     iResolution.xy


vec4 convol2D(vec2 U) {                                                     
    vec4  O = vec4(0.0);  
    float r = float(N-1)/2., g, t=0.;                                       
    for( int k=0; k<N*N; k++ ) {                                            
        vec2 P = vec2(k%N,k/N) / r - 1.;                                    
        t += g = exp(-2.*dot(P,P) );                                        
        O += g * textureLod(iChannel0, (U+w*P) *R.y/R, z );  
    }                                                                       
    return O/t;                                                             
}      

void mainImage( out vec4 O, vec2 u )
{
    float centerDepth = texelFetch(iChannel0, ivec2(iResolution.xy*0.5), 0).w;
    float depth = texelFetch(iChannel0, ivec2(u), 0).w;
    
    // Blur based on depth, the farther from the depth of the center pixel, the more blur,
    // to create a tilt-shift lens effect.
    w = (abs(depth-centerDepth)) * 0.015;
    
    if (w > 0.002)
    {
        init
        vec2 p = (u - iResolution.xy * 0.5) / iResolution.y;
        {
            vec2 U = u / R.y;  
            O = convol2D(U);
        }
    }
    else
    {
        O = texture(iChannel0, u/iResolution.xy);
    }
}
