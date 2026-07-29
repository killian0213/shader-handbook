// Buf B (buffer) — tripney spears by flockaroo
// https://www.shadertoy.com/view/4ssBWS

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// smoothing in Y

#define Res  iResolution.xy

vec4 getVal(vec2 c) {
    vec2 uv=c/Res.xy;
    if(uv.x<.0 || uv.y<.0 || uv.x>1. || uv.y>1.) return vec4(.5);
    return texture(iChannel0,uv); 
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // no vid tex here so get its size on pixel 0,0 from previous pass
    vec2 Res0 = getVal(vec2(0.5,0.5)).xy;
    vec4 c=vec4(0);
    float n=0.;
#define W 2
    for(int i=-W;i<=W;i++)
    {
        float fact=1.-.0*float(i)/float(W+1);
        c+=fact*getVal(fragCoord+vec2(0,float(i))*Res.x/Res0.x);
        n+=fact;
    }
    fragColor = c/n;
    //fragColor = getVal(fragCoord);
}