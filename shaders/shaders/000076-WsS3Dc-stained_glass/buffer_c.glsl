// Buffer C (buffer) — stained glass by flockaroo
// https://www.shadertoy.com/view/WsS3Dc

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// multi scale subdivision

// find voronoi cells

// the effect is fast enough for realtime, but the video framerate is reduced due 
// to "emulated passes" (1 pass per frame - unfortunetely there's no passes in shadertoy)

#define iPassIndex (iFrame%NumPasses)

//#define ResMap (vec2(512,256))
#define ResMap min(pow(vec2(2.),floor(log2(iResolution.xy))),vec2(512,256))

#define Res iResolution.xy
#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 ResMap
#define Res2 vec2(textureSize(iChannel2,0))

vec2 getLevelCoords(vec2 coord, int level, inout vec2 frameCoord)
{

    ivec2 dir = ivec2(1,0);
    ivec2 s = ivec2(Res1)/(dir+1);
    ivec2 sp = s;
    ivec2 o = ivec2(0);
    ivec2 op = o;
    for(int i=0;i<level;i++) {
        op=o; o+=s*dir;
        dir=(dir+1)&1;
        sp=s; s/=dir+1;
    }

    vec2 c = coord*vec2(s)+vec2(o);
    frameCoord=fract(c);
    return (floor(c)+.5)/Res1;
}


vec4 getCol(vec2 uv)
{
    return texture(iChannel0,uv);
}

float colDist(vec4 c1, vec4 c2)
{
    return dot(c1.xyz-c2.xyz,vec3(.3333));
}

void getCenterScaleColor( vec2 fragCoord, inout vec2 c, inout vec2 s, inout vec4 col )
{
    vec2 frameCoord;
    vec2 fact=ResMap/vec2(512,256);
    s=iResolution.xy*vec2(.25,.25)/fact;
    c=(floor(fragCoord/s)+.5)*s;
    for(int i=11;i>=0;i--)
    {
        vec4 coordMinMax=textureLod(iChannel1,getLevelCoords(fragCoord/iResolution.xy,i,frameCoord)*Res1/Res,0.);
        vec4 mi = getCol(coordMinMax.xy/Res1);
        vec4 ma = getCol(coordMinMax.zw/Res1);
        col=mix(mi,ma,1.);
        //fragColor.xyz=vec3(0)+dot(fragColor.xyz,vec3(.3333));
        float detail=(iMouse.x>=1.)?1./(1.+25.*iMouse.x/iResolution.x):.3/sqrt(Res.x/600.);
        vec2 dir=((i&1)==1)?vec2(1,0):vec2(0,1);
        s *= ((i&1)==0)?vec2(1,.5):vec2(.5,1);
        c+=s*(step(vec2(0),fragCoord-c)*2.-vec2(1))*dir*.5;
        if( abs(colDist(mi,ma))<detail /**float(i+10)/30.*/ ) break;
    }
}

vec4 getPixRandS(vec2 pos)
{
    //return textureLod(iChannel2,(pos)/Res2,0.)-.5;
    return textureLod(iChannel2,(floor(pos)+.5)/Res2,0.)-.5;
}

float randness = 0.5;

vec4 getRand(vec2 pos)
{
    return textureLod(iChannel2,pos/Res2,0.);
}

void mainImageOld( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor=texture(iChannel0,fragCoord/iResolution.xy);
    //fragColor=texture(iChannel1,fragCoord/iResolution.xy);
    //fragColor=texture(iChannel2,fragColor.xy/Res1);
}

#define sc (iResolution.x/600.)

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // just render a new frame every NumPasses'th fame, otherwise copy old frame
    if (iPassIndex!=NumPasses-1) 
    {
    	fragColor=texture(iChannel3,fragCoord/Res);
        return;
    }
    
    vec4 r = getRand(fragCoord*1.2/sqrt(sc))-getRand(fragCoord*1.2/sqrt(sc)+vec2(1,-1)*1.5);
    fragCoord+=1.5*sqrt(sc)*(getRand(fragCoord*.135).xy-.5+.5*(getRand(fragCoord*.3).xy-.5));
    vec4 coords=texelFetch(iChannel1,ivec2(fragCoord.xy),0);
    fragColor = vec4(0);
    float sum=0.;
    
    vec2 c,s,c2,s2;
    vec4 color=vec4(0);
    getCenterScaleColor(fragCoord,c,s,color);
    vec2 p1,p2,p3;
    p1 = c+getPixRandS(c).xy*s*randness;
    float d=length(fragCoord-p1);
    vec2 cellScale=s;
    p2 = vec2(0);
    float d2=1000.;
    p3 = vec2(0);
    float d3=1000.;

    vec2 dir = vec2(1,0);
    vec2 edge = vec2(-1,-1);
    for(int j=0;j<4;j++)
    {
        dir =dir.yx *vec2(1,-1);
        edge=edge.yx*vec2(1,-1);
        vec2 pos=c+(s*.5+.5)*edge;
        for(int i=0;i<32;i++)
        {
            getCenterScaleColor(pos,c2,s2,color);
            vec2 point=c2+getPixRandS(c2).xy*s2*randness;
            float dact=length(fragCoord-point);
            if (dact<d) {
                p3=p2; d3=d2; p2=p1; d2=d; d=dact; cellScale=s2; p1=point;
            }
            else if (dact<d2) {
                d3=d2; p3=p2; d2=dact; p2=point;
            }
            else if (dact<d3) {
                d3=dact; p3=point;
            }
            pos+=(dot(c2-pos,dir)+abs(dot(s2*.5,dir))+1.)*dir;
            if (dot(pos-c,dir)>abs(dot(s,dir)*.5)) break;
        }
    }
    d=100.;
    d=min(d,abs(dot(fragCoord-(p1+p2)*.5,normalize(p1-p2))));
    d=min(d,abs(dot(fragCoord-(p1+p3)*.5,normalize(p1-p3))));
    
    fragColor.xy = p1/Res; 
    fragColor.z = d;
    fragColor.w = length(cellScale);
    
    #if 0
    float SC=Res.x/700.;
    float SSC=sqrt(SC);
    //fragColor.xyz = (cellColor.xyz*1.+.0)*(1.-pow(d/50./SC,1.));
    fragColor.xyz = getCol(p1/Res).xyz*1.+.0;
    //fragColor.xyz *= 1.2;
    fragColor.xyz *= (1.05-.1*smoothstep(0.,16.,10.*d/sqrt(length(cellScale))));
    fragColor.xyz *= (1.1-.2*smoothstep(0.,8.,10.*d/sqrt(length(cellScale))));
    fragColor.xyz *= mix(1.,smoothstep(1.,3.,10.*d/sqrt(length(cellScale))),.8-.5*sqrt(length(cellScale)/100.));
    //fragColor.xyz *= .6+.4*smoothstep(1.,3.,10.*d/sqrt(length(cellScale)));
    //fragColor.xyz = vec3(d/50.);
    #endif
    // vignetting
    /*if(true)
    {
        vec2 scc=(fragCoord-.5*iResolution.xy)/iResolution.x;
        float vign = 1.1-.5*dot(scc,scc);
        vign*=1.-.7*exp(-sin(fragCoord.x/iResolution.x*3.1416)*20.);
        vign*=1.-.7*exp(-sin(fragCoord.y/iResolution.y*3.1416)*10.);
        fragColor.xyz *= vign;
    }*/
    //fragColor/=sum;
    //fragColor.w=1.;
    //coordMinMax=texelFetch(iChannel1,ivec2(fragCoord/Res*Res1),0);
    
    //vec2 co=(iMouse.y<Res.y*.5)?coordMinMax.xy:coordMinMax.zw;
    //fragColor.xyz=vec3(0)+dot(texture(iChannel0,co/Res1).xyz,vec3(.3333));
    
    //fragColor=vec4(coordMinMax.xy/256.,0,1);
}

