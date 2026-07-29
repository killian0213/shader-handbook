// Buffer D (buffer) — vortex simulation+Voronoi track by FabriceNeyret2
// https://www.shadertoy.com/view/wtyGWc

// === display with motion blur

void mainImage( out vec4 O,  vec2 U )
{
/* // --- test: display data tiles
    float n = 3.*Nf/iResolution.y,
        r = iResolution.x/iResolution.y;
    U /= iResolution.xy;
	O.xy =  U.x < .5 ? texture(iChannel0,U*n).xy
                     : texture(iChannel0,(U-vec2(2.*n,0))*n).zw;
    if (U.y < 1./3.) O /= iResolution.y;
    else if (U.x>.5 && max((U.x-.5)*r,U.y-1./3.)<1./3.) O = O.x==0. ? vec4(1) : O.x>0. ? vec4(O.x,0,0,1) : vec4(0,0,-O.x,1);
 // O = fract(O);
    return;
/**/    

 // --- Display partics using Voronoï tracking 

#if BLEND != 1    
  #define blend(d,s,w) d += (s)*(w)
#else
  #define blend(d,s,w) d = max(d,(s))
#endif
    
    O = vec4(0);
    vec4 a = T2(U), P;         // 4 particule id (supposed to be particles closest to I)
    float w,l;
    for(int i = 0; i < 4; i++){// draw blobs
        P = A(a[i],0); if (a[i]==0.) break;
        l = l2( U - P.xy );   
        w = A(a[i],ivec2(0,N)).z;            // particle vorticity             
        if   (w==0.) blend(O, smoothstep(Rm,Rm/4.,l)*.6,.3); // passiwe marker : white
        else { l = smoothstep(Rv,Rv/4.,l);                   // active vortices : red/blue
              if (w>0.) blend(O.r, w*l, Wv); 
              else      blend(O.b,-w*l, Wv);
             }
    }
    
#if BLEND != 2    
    blend( O, .95*T1(U),1.);     // blend with fading past
#else
    O = max(O/.5,.95*T1(U));     // blend with fading past
#endif
    
/* // --- old way: Display partics using usual NxN browsing & blending
    
    O = (1.-.05)*texture(iChannel1,U/iResolution.xy); // blur relaxation of past    
    for (int j=0; j<N; j++)
        for (int i=0; i<N; i++) 
        {
            vec2 d = tex(i,j).xy - U.xy;
            float l = dot(d,d),
                  w = W(i,j);    // particle vorticity
         // O += 2.*abs(w)/l;
            if (l<Rp)              
              if   (w==0.) O += smoothstep(Rm,Rm/2.,l) * .2; // passiwe marker : white
              else { l = smoothstep(Rp,Rp/2.,l) * .3;        // active vortices : red/blue
                     if (w>0.) O.r += w*l; else O.b += -w*l;
                   }
     }
/**/    
}
