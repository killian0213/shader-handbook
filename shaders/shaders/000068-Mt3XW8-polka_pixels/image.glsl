// Image (image) — polka pixels by flockaroo
// https://www.shadertoy.com/view/Mt3XW8

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// flip pixels randomly from old frame to new frame

// tiles of the video history (as in BufA)
#define Xnum 10
#define Ynum 10

// tile size in pixels (proportional sqrt(Res), otherwise pixels get too small in preview)
#define TileSize (20.*sqrt(iResolution.y/1080.))
// take every DFrame'th frame
#define DFrame 30


#define Res1 iChannelResolution[1].xy

float rectMask(float b, float w, vec2 uv)
{
	vec4 e=smoothstep(vec4(-b-.5*w),vec4(-b+.5*w),vec4(uv,vec2(1)-uv));
    return e.x*e.y*e.z*e.w;
}

vec2 frameUV(int frame, vec2 uv)
{
    frame = int(mod(float(frame+Xnum*Ynum),float(Xnum*Ynum)));
    return (uv+vec2(mod(float(frame),float(Xnum)),frame/Xnum))/vec2(Xnum,Ynum);
}

vec4 getColor(float frame, vec2 uv)
{
    vec4 c1=texture(iChannel0,frameUV(int(floor(frame)),uv));
    return c1;
    vec4 c2=texture(iChannel0,frameUV(int(ceil(frame)),uv));
    return mix(c1,c2,fract(frame));
}

float getFrameSpec(vec2 duv, vec2 fragCoord)
{
    vec2 uvS=.85*duv*pow(abs(.85*duv),vec2(20.))*530.;
    vec3 n=normalize(vec3(uvS,1.1));
    vec3 v=normalize(vec3((fragCoord-iResolution.xy*.5)/iResolution.x*.25,-1));
    vec3 light=vec3(3.5,2.3,-2.6);
    vec3 halfVec=normalize(normalize(-v)+normalize(light));
    return pow(clamp(dot(n,halfVec),0.,1.),10.);
}

float getVign(vec2 fragCoord)
{
	float rs=length(fragCoord-iResolution.xy*.5)/iResolution.x;
    return 1.-rs*rs*rs;
}

float circle(vec2 uv, float r)
{
    float l=length(uv-.5);
    return 1.-smoothstep(r-.05,r+.05,l);
}

float circleMask(vec2 uv,float y, float i1, float i2)
{
    float r1=.45;
    float r2=.45;
    r1*=i1;
    r2*=i2;
    return circle(uv+vec2(0,y-1.),r1)+circle(uv+vec2(0,y),r2);
}

    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int actFrame=(iFrame/DFrame)*DFrame;
    int prevFrame=(iFrame/DFrame-1)*DFrame;
    vec4 rand = texture(iChannel1,(floor(fragCoord/TileSize+float(iFrame/DFrame)*1.*13.)+.5)/Res1);
    
    vec2 uvQ = (floor(fragCoord/TileSize)*TileSize)/iResolution.xy;
    vec2 uv = fragCoord/iResolution.xy;
    vec2 duv = (uv-uvQ)*iResolution.xy/TileSize;
    
    vec4 c1=getColor(float(actFrame),uvQ);
    vec4 c2=getColor(float(prevFrame),uvQ);
    
    // let the pixels flip at a randomly
    float y=-rand.x*2.+3.*float(iFrame-actFrame)/float(DFrame);
    y=clamp(y,0.,1.);
    y*=y;
    float r = fract(rand.y+float(actFrame/DFrame)*.25);
    float thr=1.-duv.y;
    
    // some tests flipping in different directions
    //if (r>.25) thr=1.-duv.x;
    //if (r>.50) thr=duv.x;
    //if (r>.75) thr=duv.y;
    
    // some tests playing with different circle sizes prop to color intensity
    //float i1=dot(vec3(.333),c1.xyz);
    //float i2=dot(vec3(.333),c2.xyz);    
    float i1=1.;
    float i2=1.;
    
	fragColor = mix(c1,c2,smoothstep(y-.1,y+.1,thr));
    fragColor = mix(fragColor,vec4(.2,.3,.4,1),.15-.15*circleMask(duv,y,i1,i2));
    
    // some rectangular ambient around every macro-pixel
    fragColor *= .5+.5*rectMask(.2*(dot(fragColor.xyz,vec3(.333))),.7,duv);
    
    float spec = 0.0
        //+getFrameSpec(duv,fragCoord)
        //+getFrameSpec(fract(duv+vec2(0,y)),fragCoord)
        //+getCricleSpec(fract(duv+vec2(0,y)),fragCoord)
        +clamp((circleMask(duv-.02,y,i1,i2)-circleMask(duv+.02,y,i1,i2)),-.4,1.)
        ;
    
    fragColor.xyz += .5*spec;
    fragColor *= 1.2*getVign(fragCoord);
    //fragColor = texture(iChannel0,uv);
}