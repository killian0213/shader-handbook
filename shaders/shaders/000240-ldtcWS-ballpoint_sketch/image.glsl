// Image (image) — ballpoint sketch by flockaroo
// https://www.shadertoy.com/view/ldtcWS

// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// ballpoint line drawing

// realtime version on shaderoo: https://shaderoo.org/?shader=yMP3J7

// final mixing and some paper-ish noise

vec4 getRand(vec2 pos)
{
    vec2 tres = vec2(textureSize(iChannel1,0));
    vec4 r=texture(iChannel1,pos/tres/sqrt(iResolution.x/600.));
    return r;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 r = getRand(fragCoord*1.1)-getRand(fragCoord*1.1+vec2(1,-1)*1.);
    vec4 c = 1.-.3*texture(iChannel0,fragCoord/iResolution.xy);
    fragColor = c*(.95+.06*r.xxxx+.06*r);
    //fragColor = c;
    vec2 sc=(fragCoord-.5*iResolution.xy)/iResolution.x;
    float vign = 1.0-.5*dot(sc,sc);
    vign*=1.-.7*exp(-sin(fragCoord.x/iResolution.x*3.1416)*20.);
    vign*=1.-.7*exp(-sin(fragCoord.y/iResolution.y*3.1416)*10.);
    fragColor *= vign;
    fragColor.w=1.;
}


