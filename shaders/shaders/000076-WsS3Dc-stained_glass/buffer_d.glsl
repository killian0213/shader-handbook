// Buffer D (buffer) — stained glass by flockaroo
// https://www.shadertoy.com/view/WsS3Dc

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// multi scale subdivision

// backup last vid frame, so we can do lighting in image tab in realtime

#define iPassIndex (iFrame%NumPasses)

#define Res (iResolution.xy)
#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 vec2(textureSize(iChannel1,0))
#define Res2 vec2(textureSize(iChannel2,0))
#define Res3 vec2(textureSize(iChannel3,0))
#define Res4 vec2(textureSize(iChannel4,0))

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (iPassIndex!=NumPasses-1) 
    {
    	fragColor=texture(iChannel3,fragCoord/Res);
        return;
    }
   	fragColor=texture(iChannel2,fragCoord/Res);
}

