// Buf B (buffer) — melting wax britney by flockaroo
// https://www.shadertoy.com/view/XtlfRl

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// melting wax

// take (interpolate) certain history-frame

#define Xnum 4
#define Ynum 4

float getVal(vec2 uv)
{
    return length(texture(iChannel0,uv).xyz);
}
    
vec2 getGrad(vec2 uv,float delta)
{
    vec2 d=vec2(delta,0);
    return vec2(
        getVal(uv+d.xy)-getVal(uv-d.xy),
        getVal(uv+d.yx)-getVal(uv-d.yx)
    )/delta;
}

vec2 getFrameUV(vec2 uv, float frameDelay)
{
    vec2 uv2 = uv+vec2(mod(frameDelay,float(Xnum)),floor(frameDelay/float(Xnum)));
    uv2/=vec2(Xnum,Ynum);
    return uv2;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   	vec2 uv = fragCoord.xy / iResolution.xy;
    float strength=clamp(iResolution.x/1900.,0.,.99);
    //float strength=clamp(.7+.3*cos(iTime*.5),0.,.99);
    if(iMouse.x>=2.) strength=iMouse.x/iResolution.x;
    float frameDelay = strength*float(Xnum*Ynum-1);
	fragColor = mix(
        texture(iChannel0,getFrameUV(uv,floor(frameDelay))),
        texture(iChannel0,getFrameUV(uv,ceil(frameDelay))),
                fract(frameDelay)
               );
}

