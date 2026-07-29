// Buffer A (buffer) — polka pixels by flockaroo
// https://www.shadertoy.com/view/Mt3XW8

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// record video histroy in Xnum*Ynum grid

#define Xnum 10
#define Ynum 10

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv0=fragCoord/iResolution.xy;
    int fr=int(uv0.x*float(Xnum))+int(uv0.y*float(Xnum))*Ynum;
    if(fr!=int(mod(float(iFrame),float(Xnum*Ynum)))) 
        fragColor = texture(iChannel1,uv0);
    else
        fragColor = texture(iChannel0,fract(uv0*vec2(Xnum,Ynum)));
    if(iFrame<5)
        fragColor = texture(iChannel0,fract(uv0*vec2(Xnum,Ynum)));
}