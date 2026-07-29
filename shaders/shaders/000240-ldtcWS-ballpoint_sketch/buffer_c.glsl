// Buf C (buffer) — ballpoint sketch by flockaroo
// https://www.shadertoy.com/view/ldtcWS

// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// ballpoint line drawing

// accumulating up the line segments
// slowly fading out older cotent


void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    //fragColor = max(texture(iChannel0,uv),clamp(texture(iChannel1,uv)-.003,0.,1.));
    //fragColor = clamp(texture(iChannel0,uv)+texture(iChannel1,uv)-.003,0.,1.);
    fragColor = (texture(iChannel0,uv)+texture(iChannel1,uv))*(1.-.006/2000.*float(PNUM));
    fragColor.w=1.;
    if(iFrame<10) fragColor=vec4(0,0,0,1);
}

