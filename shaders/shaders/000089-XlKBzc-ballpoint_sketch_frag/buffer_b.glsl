// Buffer B (buffer) — ballpoint sketch frag by flockaroo
// https://www.shadertoy.com/view/XlKBzc

// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// ballpoint line drawing

// calculating and drawing drawing line segments

#define XNUM 100
#define YNUM 70
#define Res (iResolution.xy)
#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 vec2(textureSize(iChannel1,0))
#define SC (Res.x/800.)

#define LNUM 8
#define ImageTex iChannel0

#define PI 3.1415927

#define N(v) (v.yx*vec2(1,-1))

struct Particle {
    vec2 pos;
    vec2 vel;
    int idx;
};

vec4 getRand(vec2 pos)
{
    vec2 rres=vec2(textureSize(iChannel1,0));
    return textureLod(iChannel1,pos/rres,0.);
}

vec4 getRand(int idx)
{
    ivec2 rres=textureSize(iChannel1,0);
    idx=idx%(rres.x*rres.y);
    return texelFetch(iChannel1,ivec2(idx%rres.x,idx/rres.x),0);
}

void initParticle(inout Particle p, int xIdx, int yIdx)
{
    float xnum = float(XNUM);
    float ynum = float(YNUM);
    vec2 delta = vec2(Res.x/xnum,Res.y/ynum);
    p.pos.xy=vec2(xIdx,yIdx)*delta;
    // trigonal grid offs
    p.pos.x+=(float(yIdx%2)-.5)*delta.x*.5;
    p.vel = (getRand(p.pos).xy-.5)*0.;
}

vec4 getCol(vec2 pos, float lod)
{
    vec2 tres = vec2(textureSize(ImageTex,0));
    // use max(...) for fitting full image or min(...) for fitting only one dir
    vec2 tpos = (pos-.5*Res)*min(tres.y/Res.y,tres.x/Res.x);
    vec2 uv = (tpos+tres*.5)/tres/*-(iMouse.xy/iResolution.xy-.5)*/;
    return textureLod(ImageTex,uv,0.);
}

float getVal(vec2 pos)
{
    return getCol(pos,0.).z;
    return dot(getCol(pos,0.).xyz,vec3(1)/3.);
}

vec2 getGradLkp(vec2 pos, float eps)
{
    float d = getCol(pos,0.).z;
    vec2 g = .1*pow(2.,(1.-d)*4.)*getCol(pos,(1.-d)*4.).xy;
    //vec2 g=getCol(pos).xy;
    return g;
}
vec2 getGradDet(vec2 pos, float eps)
{
    vec2 d=vec2(eps,0);
    return vec2(
        getVal(pos+d.xy)-getVal(pos-d.xy),
        getVal(pos+d.yx)-getVal(pos-d.yx)
        )/eps/2.;
}
vec2 getGrad(vec2 pos, float eps)
{
    return -getGradDet(pos,eps);
}

void propagate(inout Particle p, float dt)
{
    //float dt=.02;
    p.pos+=p.vel*dt;
    float sc=SC;
    
    // gradient, its length, and unit vector
    vec2 g = 1.0*getGrad(p.pos,2.5*sc)*sc;
    // add some noise to gradient so plain areas get some texture
    //g += (getRand(p.pos/sc).xy-.5)*.003;  //getRand is pixel based so we divide arg by sc so that it looks the same on all scales
    //g+=normalize(p.pos-Res*.5)*.001;
    float gl=length(g);
    vec2 gu=normalize(g);
    
    // calculate velocity change
    vec2 dvel=vec2(0);
    
    float dir = (float(p.idx%2)*2.-1.); // every 2nd particle is bent left/right
    float dir2 = (float((p.idx/8)%2)*2.-1.);
    //dir2=1.;
    
    // apply some randomness to velocity
    //dvel += .7*(getRand(p.pos/sc).xy-.5)/(.03+gl*gl)*sc;

    // vel tends towards gradient
    dvel -= 10.*gu*(1.+sqrt(gl*2.))*sc;
    
    // vel tends towards/away from normal to gradient (every second particle)
    dvel += dir2*30.*N(gu)/(1.+1.*sqrt(gl*100.))*sc*dir;
    
    // vel bends right/left (every second particle)
    //dvel += p.vel.yx*vec2(1,-1)*.06;
    dvel += .06*N(p.vel)/(1.+gl*10.)*dir;
    
    p.vel += dvel;
    
    // minimum vel
    //p.vel = normalize(p.vel)*max(length(p.vel),40.*sc);
    
    // vel damping
    p.vel-=gu*dot(p.vel,gu)*(.05+5.*gl)*.75;
    //p.vel-=N(gu)*dot(p.vel,N(gu))*-.035;
    //p.vel*=.95;
}

float getDetail(vec2 pos)
{
    return getCol(pos, 0.).z;
}

float sdLine( vec2 pos, vec2 p1, vec2 p2, float crop, inout float f)
{
    pos-=p1; p2-=p1;
    float l=length(p2);
    vec2 t=p2/l;
  	float pp = dot(pos,t);
  	float pn = dot(pos,t.yx*vec2(1,-1));
    f=(l<.001)?0.:pp/l;
  	return (l<.001)?100000.:max(max(pp-l+crop,-pp+crop),abs(pn));
}

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    int xIdx0=int(fragCoord.x/(Res.x/float(XNUM))+.5);
    int yIdx0=int(fragCoord.y/(Res.y/float(YNUM))+.5);
    vec3 col=vec3(0);
    int idelta = 4;
    int iw=idelta*2+1;
    for(int dIdx=0;dIdx<iw*iw;dIdx++)
    {
        int dxIdx=(dIdx%iw)-iw/2;
        int dyIdx=(dIdx/iw)-iw/2;
        int xIdx=xIdx0+dxIdx;
        int yIdx=yIdx0+dyIdx;
        int pIdx=(xIdx+yIdx*XNUM);
    	Particle p;
    	p.idx=xIdx+yIdx*XNUM;
    	initParticle(p,xIdx,yIdx);
    	Particle pp;
    
    	// make a little pre propagation, so particles start already near a bigger gradient
    	p.pos -= .04*mix(1.,2.*getRand(pIdx).x,.8)/(getGrad(p.pos,2.5*SC));
        
    	// calc the actual stroke
    	// here every segment calculates its whole previous stroke points
    	// could be done more effctive by precomputing to a buffer i guess,
    	// but my gpu is eager for work anyway ;-)
    	for(int i=0;i<LNUM;i++)
    	{
	        pp=p;
	        for(int j=0;j<4;j++) propagate(p,.01);
	        //dist=min(dist,sdLine(fragCoord,p.pos,pp.pos,0.));
            float f=0.;
	        float dist=sdLine(fragCoord,p.pos,pp.pos,.75*sqrt(SC),f);
		    col+=(1.-vec3(.0,.2,.65))*clamp(1.2*sqrt(SC)-dist,0.,1.)
				 *clamp((float(i+1)-f)/4.,0.,1.)*clamp((float(LNUM-i)+f)/2.,0.,1.)
                 //* (.3+1.4*texture(iChannel1,fragCoord/Res1*.7).x)
	            ;
	    }
    }
    fragColor = vec4(col,1);
}

