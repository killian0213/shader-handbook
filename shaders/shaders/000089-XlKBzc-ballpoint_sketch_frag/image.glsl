// Image (image) — ballpoint sketch frag by flockaroo
// https://www.shadertoy.com/view/XlKBzc

// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// ballpoint line drawing

// old non realtime verison: https://www.shadertoy.com/view/ldtcWS
// realtime with geomtry version: https://www.shaderoo.org/?shader=yMP3J7
// this one is derived from the above, but includes some improvements 
// to work on different detail scalings in content

// some particles (the actual ballpoint tips)

#define Res (iResolution.xy)
#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 vec2(textureSize(iChannel1,0))
#define Res2 vec2(textureSize(iChannel2,0))
#define Res3 vec2(textureSize(iChannel3,0))

vec4 getRand(vec2 pos)
{
    vec2 tres = vec2(textureSize(iChannel1,0));
    vec4 r=texture(iChannel1,pos/tres/sqrt(iResolution.x/600.)*vec2(1,1));
    return r;
}

vec4 getCol(vec2 pos, float lod)
{
    vec2 tres = Res2;
    // use max(...) for fitting full image or min(...) for fitting only one dir
    vec2 tpos = (pos-.5*Res.xy)*min(tres.y/Res.y,tres.x/Res.x);
    vec2 uv = (tpos+tres*.5)/tres;
    //vec2 mask = step(vec2(-.5),-abs(uv-.5));
    return textureLod(iChannel2,uv,lod)/**mask.x*mask.y*/;
}

vec4 getCol2(vec2 pos, float lod)
{
    vec2 tres = Res2;
    // use max(...) for fitting full image or min(...) for fitting only one dir
    vec2 tpos = (pos-.5*Res.xy)*min(tres.y/Res.y,tres.x/Res.x);
    vec2 uv = (tpos+tres*.5)/tres;
    //vec2 mask = step(vec2(-.5),-abs(uv-.5));
    return textureLod(iChannel2,uv,lod)/**mask.x*mask.y*/;
}

float paperBump(vec2 c)
{
    return (texture(iChannel0,c/Res,.7).x
          	+ 4.*texture(iChannel0,c/Res,2.5).x
    		+16.*texture(iChannel0,c/Res,4.5).x
    		+64.*texture(iChannel0,c/Res,6.5).x)/20.;
}

vec2 paperBumpG(vec2 c)
{
    vec2 g=vec2(0);
    vec2 d=vec2(.8,0);
	g+=vec2( texture(iChannel0,(c-d.xy*1.)/Res,.8).x-texture(iChannel0,(c+d.xy*1.)/Res,.8).x,
       	     texture(iChannel0,(c-d.yx*1.)/Res,.8).x-texture(iChannel0,(c+d.yx*1.)/Res,.8).x );
	g+=vec2( texture(iChannel0,(c-d.xy*4.)/Res,2.8).x-texture(iChannel0,(c+d.xy*4.)/Res,2.8).x,
       	     texture(iChannel0,(c-d.yx*4.)/Res,2.8).x-texture(iChannel0,(c+d.yx*4.)/Res,2.8).x );
	g+=vec2( texture(iChannel0,(c-d.xy*16.)/Res,4.8).x-texture(iChannel0,(c+d.xy*16.)/Res,4.8).x,
       	     texture(iChannel0,(c-d.yx*16.)/Res,4.8).x-texture(iChannel0,(c+d.yx*16.)/Res,4.8).x );
	g+=vec2( texture(iChannel0,(c-d.xy*64.)/Res,6.8).x-texture(iChannel0,(c+d.xy*64.)/Res,6.8).x,
       	     texture(iChannel0,(c-d.yx*64.)/Res,6.8).x-texture(iChannel0,(c+d.yx*64.)/Res,6.8).x );
    return g/20.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //vec4 r = getRand(fragCoord*1.3)-.5;
    vec4 r = getRand(fragCoord*1.1)-getRand(fragCoord*1.1+vec2(1,-1)*1.5);
    vec4 r2 = getRand(fragCoord*.015)-.5+getRand(fragCoord*.008)-.5;
    vec4 c = 1.-.3*texture(iChannel0,fragCoord/iResolution.xy,0.);
    //float s=sin(fragCoord.y/iResolution.y*3.1416*15.);
    //c-=.15*exp(-s*s*300.);
	float paperbump = paperBump(fragCoord);
    //vec2 n = -vec2(dFdx(paperbump),dFdy(paperbump));
    vec2 n = paperBumpG(fragCoord);
    float paper = .95+2.*(dot(n,vec2(1,-1)));
    vec2 s=sin((fragCoord)*.1/sqrt(iResolution.y/400.));
    fragColor = c*paper*(.95+.06*r.x-.0*r2.x);
    //fragColor = c;
    vec2 sc=(fragCoord-.5*iResolution.xy)/iResolution.x;
    float vign = 1.-.3*dot(sc,sc);
    //vign-=dot(exp(-sin(fragCoord/iResolution.xy*3.14)*vec2(20,10)),vec2(1,1));
    vign*=1.-.7*exp(-sin(fragCoord.x/iResolution.x*3.1416)*40.);
    vign*=1.-.7*exp(-sin(fragCoord.y/iResolution.y*3.1416)*20.);
    fragColor *= vign;
    
    fragColor.w=1.;
}

