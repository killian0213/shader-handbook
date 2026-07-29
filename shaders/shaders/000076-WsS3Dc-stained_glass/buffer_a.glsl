// Buffer A (buffer) — stained glass by flockaroo
// https://www.shadertoy.com/view/WsS3Dc

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// multi scale subdivision

// copy every NumPasses'th frame of video to Buffer
// (emulating multiple passes by dedicating each frame to a different pass)

#define iPassIndex (iFrame%NumPasses)

#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 vec2(textureSize(iChannel1,0))
#define Res2 vec2(textureSize(iChannel2,0))

vec4 getCol(vec2 pos)
{
    vec2 tres = Res0;
    // use max(...) for fitting full image or min(...) for fitting only one dir
    vec2 tpos = (pos-.5*Res1)*min(tres.y/Res1.y,tres.x/Res1.x);
    vec2 uv = (tpos+tres*.5)/tres;
	vec4 col=texture(iChannel0,uv);
	vec4 bg=texture(iChannel2,((uv-.5)*.9+.5)+.05*sin(.1*iTime*vec2(2,3)),3.7+log2(Res1.x/600.));
    col=mix(col,bg,dot(col.xyz,vec3(-.8,1.6,-.8)));
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (iPassIndex==0)
        fragColor=getCol(fragCoord);
    else
        fragColor=texture(iChannel1,fragCoord/iResolution.xy);
}
