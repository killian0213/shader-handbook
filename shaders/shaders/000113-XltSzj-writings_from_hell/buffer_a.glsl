// Buf A (buffer) — writings from hell by flockaroo
// https://www.shadertoy.com/view/XltSzj

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// writing random endless scribbles
// by summing up low band noised curvature

// fragColor: red = writing, blue = burn mask

#define PI2 6.28318530717959
#define PNUM 40

vec2 filterUV1(vec2 uv) 
{
    // iq's improved texture filtering (https://www.shadertoy.com/view/XsfGDn)
	vec2 x=uv*iChannelResolution[1].xy;
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    return (p+f)/iChannelResolution[1].xy;
}

vec4 getPixel(int x, int y)
{
    return texture(iChannel0,vec2(float(x)+.5,float(y)+.5)/iChannelResolution[0].xy);
}

bool isPixel(int x, int y, vec2 fragCoord)
{
    vec2 c=fragCoord/iResolution.xy*iChannelResolution[0].xy;
    return ( int(c.x)==x && int(c.y)==y );
}

vec2 readPos(int i)
{
    return getPixel(i,0).xy;
}

bool writePos(vec2 pos, int i, inout vec4 fragColor, vec2 fragCoord)
{
    if (isPixel(i,0,fragCoord)) { fragColor.xy=pos; return true; }
    return false;
}

vec4 getRand(vec2 pos)
{
    return texture(iChannel1,filterUV1(pos/vec2(400,300)));
}

float dotDist(vec2 pos,vec2 fragCoord)
{
    return length(pos-fragCoord);
}

// iq: https://iquilezles.org/articles/distfunctions
float lineDist(vec2 a,vec2 b,vec2 p)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

vec4 drawDot(vec2 pos,float r, vec2 fragCoord)
{
    return vec4(clamp(r-length(pos-fragCoord),0.,1.)/r*3.);
}

#define N(x) (x.yx*vec2(1,-1))

// gives a parametric position on a pentagram with radius 1 within t=0..5
// (maybe there's more elegant ways to do this...)
vec2 pentaPos(float t)
{
    float w=sqrt((5.+sqrt(5.))*.5);
    float s=sqrt(1.-w*w*.25);
    float ang=-floor(t)*PI2*2./5.;
    vec2 x=vec2(cos(ang),sin(ang));
    return -N(x)*s+x*w*(fract(t)-.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time=float(iFrame)*1./60.;
    vec2 uv=fragCoord/iResolution.xy;
    float v=0.;
    for(int i=0;i<50;i++) v+=texture(iChannel0,getRand(vec2(i,0)).xy).x/50.;
    fragColor = texture(iChannel0,uv);
    int pnum = int(min(iResolution.y/50.0,float(PNUM-1)));
    bool write=false;
    for(int i=0;i<PNUM;i++)
    {
        bool isMouse = (i==pnum);
        // breaking here if i>pnum didnt work in windows (failed to unloll loop)
        if(i<=pnum) {
        vec2 pos;
            
	    pos=readPos(i);
        vec2 oldpos=pos;
        
    	float ang = (getRand(pos)+getRand(pos+vec2(1,3)*time)).x*PI2;
    	pos+=vec2(.7,0)
            +vec2(4,5)*vec2(cos(15.*time+float(i)),
                            .5*sin(15.*time+float(i)+.5)+
                            .5*sin(21.*time+float(i)+.5))*getRand(pos).x;
            //+vec2(.2,2)*vec2(cos(ang),sin(ang));
    	//vec4 c = drawDot(mod(pos,iResolution.xy),2.5,fragCoord);

        if(isMouse) 
        {
            pos=iMouse.xy;
            if(iMouse.xy==vec2(0) && mod(iTime+5.,37.7)>18.)
            {
                pos=pentaPos(iTime*.5)*.45*iResolution.y+iResolution.xy*.5;
                pos+=(getRand(pos*.6+iTime*vec2(.1,1.)).xy-.5)*7./500.*iResolution.y;
            }
        	if(length(oldpos-pos)>40.) oldpos=pos;
        }
                
        vec2 mpos=mod(pos,iResolution.xy);
        //float dd = dotDist(mpos,fragCoord);
        float dd = lineDist(mpos,oldpos-(pos-mpos),fragCoord);
    	vec4 c = vec4(clamp((isMouse?5.:3.)-dd,0.,1.9),0,max(0.,1.-dd/40.),0);
        if(mpos==oldpos-(pos-mpos)) c=vec4(0.); // ignore 0-length segments
        if(getRand(pos*.3+time).z>.8 && !isMouse) 
            pos+=vec2(10,0);
        else
    		fragColor = max(fragColor,c);        

        if(writePos(pos, i, fragColor,fragCoord)) write=true;
        }
    }

    if(!write)
    {
       fragColor.z=max(-1.,fragColor.z-.002);
       fragColor.x=max(0.,fragColor.x-.003);
    }
        
    if(iTime<2.) 
    {
        fragColor=vec4(0,0,.6,0);
	    for(int i=0;i<PNUM;i++)
    	{
            if(i<=pnum){
                vec4 rnd=texture(iChannel1,vec2(float(i)+.5,.5)/iChannelResolution[1].xy);
        	    writePos(vec2(20.+rnd.x*40.,iResolution.y/float(pnum)*float(i+1)),i,fragColor,fragCoord);     
            }
        }
    }
}