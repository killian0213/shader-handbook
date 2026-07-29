// Image (image) — giant clockwork by flockaroo
// https://www.shadertoy.com/view/WddXWB

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// giant clockwork

#define MIST

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv=fragCoord/iResolution.xy;
    #ifdef MIST
    fragColor=1.5*texture(iChannel0,uv,.5);
    fragColor+=1.*texture(iChannel0,uv,2.5);
    fragColor+=.75*texture(iChannel0,uv,4.5);
    
    fragColor.xyz/=3.25;
    #else
    fragColor=1.*texture(iChannel0,uv,0.);
    #endif
        
    fragColor.w=1.;
}

