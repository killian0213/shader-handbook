// Buf B (buffer) — writings from hell by flockaroo
// https://www.shadertoy.com/view/XltSzj

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// single pass CFD
// ---------------
// this is some "computational flockarooid dynamics" ;)
// the self-advection is done purely rotational on all scales. 
// therefore i dont need any divergence-free velocity field. 
// with stochastic sampling i get the proper "mean values" of rotations 
// over time for higher order scales.
//
// try changing "RotNum" for different accuracies of rotation calculation
// for even RotNum uncomment the line #define SUPPORT_EVEN_ROTNUM

#define RotNum 5
//#define SUPPORT_EVEN_ROTNUM

#define Res  iChannelResolution[0]
#define Res1 iChannelResolution[1]

#define keyTex iChannel3
#define KEY_I texture(keyTex,vec2((105.5-32.0)/256.0,(0.5+0.0)/3.0)).x

const float ang = 2.0*3.1415926535/float(RotNum);
mat2 m = mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
mat2 mh = mat2(cos(ang*0.5),sin(ang*0.5),-sin(ang*0.5),cos(ang*0.5));

vec4 randS(vec2 uv)
{
    return texture(iChannel1,uv*Res.xy/Res1.xy)-vec4(0.5);
}

vec2 getGradBlue(vec2 pos)
{
    float eps=1.4;
    vec2 d=vec2(eps,0);
    return vec2(
		 texture(iChannel0,fract((pos+d.xy)/Res.xy)).z
        -texture(iChannel0,fract((pos-d.xy)/Res.xy)).z,
		 texture(iChannel0,fract((pos+d.yx)/Res.xy)).z
        -texture(iChannel0,fract((pos-d.yx)/Res.xy)).z
    )/(eps*2.);
}

float getRot(vec2 pos, vec2 b)
{
    vec2 p = b;
    float rot=0.0;
    for(int i=0;i<RotNum;i++)
    {
        vec2 v=texture(iChannel0,fract((pos+p)/Res.xy)).xy;

        rot+=dot(v,p.yx*vec2(1,-1));
        p = m*p;
    }
    return rot/float(RotNum)/dot(b,b);
}

vec4 getC2(vec2 uv) 
{
    // line 0 holds writer infos so take 1st line instead
    if(uv.y*iChannelResolution[2].y<1.) uv.y+=1./iChannelResolution[2].y;
	return texture(iChannel2,uv);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 pos = fragCoord.xy;
    float rnd = randS(vec2(float(iFrame)/Res.x,0.5/Res1.y)).x;
    
    vec2 b = vec2(cos(ang*rnd),sin(ang*rnd));
    vec2 v=vec2(0);
    float bbMax=0.7*Res.y*1.; bbMax*=bbMax;
    for(int l=0;l<8;l++)
    {
        if ( dot(b,b) > bbMax ) break;
        vec2 p = b;
        for(int i=0;i<RotNum;i++)
        {
#ifdef SUPPORT_EVEN_ROTNUM
            v+=p.yx*getRot(pos+p,-mh*b);
#else
            // this is faster but works only for odd RotNum
            v+=p.yx*getRot(pos+p,b);
#endif
            p = m*p;
        }
        b*=2.0;
    }
    vec4 c2=getC2(fract(uv));
    float strength = clamp(1.-1.*c2.z,0.,1.);
    fragColor=texture(iChannel0,fract((pos+v*strength*(2./*+2.*iMouse.y/Res.y*/)*vec2(-1,1)*1.0)/Res.xy));
    fragColor=mix(fragColor,c2.xxzw*vec4(1,-1,1,1),.3*clamp(1.-strength,0.,1.));
    
    // damping
    fragColor.xy=mix(fragColor.xy,vec2(.0),.02);
    
    // add a little "motor" in the center
    //vec2 scr=(fragCoord.xy/Res.xy)*2.0-vec2(1.0);
    //fragColor.xy += (0.01*scr.xy / (dot(scr,scr)/0.1+0.3));
    
    if(iFrame<=4 || KEY_I>0.5) fragColor=texture(iChannel2,fragCoord.xy/Res.xy);
}
