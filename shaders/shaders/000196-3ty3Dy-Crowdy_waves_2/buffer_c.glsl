// Buffer C (buffer) — Crowdy waves 2 by FabriceNeyret2
// https://www.shadertoy.com/view/3ty3Dy

// === draw + blend with fading past

void mainImage( out vec4 O, vec2 I )
{
    O = vec4(0);
    vec4 a = T1(I), P;         // 4 particule id (supposed to be particles closest to I)
    
    for(int i = 0; i < 4; i++) // draw Gaussian blobs
        P = A(a[i]),
        O += .4* exp( -.5* l2( I - P.xy ) ) 
               * ( keyFlip(64+3) ? hue( length(P.zw) ) : vec4(1));

    O = mix(O, T2(I), .9);     // blend with fading past
  //O = mix(O, texture(iChannel2,-.01+1.02*I/R), .9); // false-3D variant
}