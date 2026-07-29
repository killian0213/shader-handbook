// Image (image) — when voxels wed pixels by flockaroo
// https://www.shadertoy.com/view/MsKfRw

// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// crosshatch effect

// wedding of voxels and SDF

// try to enable FAKE_VOXEL_AO (in Buf A) if its very slow on your machine

#define FLICKER 1.

#define PI2 6.28318530718
#define sc (iResolution.x/600.)
    
vec2 roffs;
float ramp;
float rsc;


vec2 uvSmooth(vec2 uv,vec2 res)
{
    return uv+.6*sin(uv*res*PI2)/PI2/res;
}

vec4 getRand(vec2 pos)
{
    vec2 tres=vec2(textureSize(iChannel1,0));
    //vec2 fr=fract(pos-.5);
    //vec2 uv=(pos-.7*sin(fr*PI2)/PI2)/tres.xy;
    vec2 uv=pos/tres.xy;
    uv=uvSmooth(uv,tres);
    return textureLod(iChannel1,uv,0.);
}

vec4 getCol(vec2 pos)
{
    vec4 r1 = (getRand((pos+roffs)*.05*rsc/sc+iTime*131.*FLICKER)-.5)*10.*ramp;
    vec2 res0=vec2(textureSize(iChannel0,0));
    vec2 uv=(pos+r1.xy*sc)/iResolution.xy;
    //uv=uvSmooth(uv,res0);
    vec4 c = texture(iChannel0,uv);
    vec4 bg= vec4(vec3(clamp(.3+pow(length(uv-.5),2.),0.,1.)),1);
    bg=vec4(1);
    //c = mix(c,bg,clamp(dot(c.xyz,vec3(-1,2,-1)*1.5),0.,1.));
    float vign=pow(clamp(-.5+length(uv-.5)*2.,0.,1.),3.);
    //c = mix(c,bg,vign);
    return c;
}

float getVal(vec2 pos)
{
    return clamp(dot(getCol(pos).xyz,vec3(.333)),0.,1.);
}

vec2 getGrad(vec2 pos, float eps)
{
    vec2 d=vec2(eps,0);
    return vec2(
        getVal(pos+d.xy)-getVal(pos-d.xy),
        getVal(pos+d.yx)-getVal(pos-d.yx)
        )/eps/2.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // subtraction of 2 rand values, so its [-1..1] and noise-wise not as white anymore
    vec4 r = getRand(fragCoord*1.2/sqrt(sc))-getRand(fragCoord*1.2/sqrt(sc)+vec2(1,-1)*1.5);
    // white noise
    vec4 r2 = getRand(fragCoord*1.2/sqrt(sc));
    
    // outlines
    float br=0.;
    roffs = vec2(0.);
    ramp = .7;
    rsc=.7;
    int num=3;
    for(int i=0;i<num;i++)
    {
        float fi=float(i)/float(num-1);
    	float t=.03+.25*fi, w=t*2.;
        // one closely matched edge-line
    	ramp=.15*pow(1.3,fi*5.); rsc=1.7*pow(1.3,-fi*5.);
    	br+=.6*(.5+fi)*smoothstep(t-w/2.,t+w/2.,length(getGrad(fragCoord,.4*sc))*sc);
        // another wildly varying edge-line
    	ramp=.3*pow(1.3,fi*5.); rsc=10.7*pow(1.3,-fi*5.);
    	br+=.4*(.2+fi)*smoothstep(t-w/2.,t+w/2.,length(getGrad(fragCoord,.4*sc))*sc);
    	//roffs += vec2(13.,37.);
    }
    fragColor.xyz=vec3(1)-.7*br*(.5+.5*r2.z)*3./float(num);
    fragColor.xyz=clamp(fragColor.xyz,0.,1.);
    
    
    // cross hatch
    ramp=0.;
    int hnum=5;
    #define N(v) (v.yx*vec2(-1,1))
    #define CS(ang) cos(ang-vec2(0,1.6))
    float hatch = 0.;
    float hatch2 = 0.;
    float sum=0.;
    for(int i=0;i<hnum;i++)
    {
 		float br=getVal(fragCoord+1.5*sc*(getRand(fragCoord*.02+iTime*1120.).xy-.5)*clamp(FLICKER,-1.,1.))*1.7;
        // chose the hatch angle to be prop to i*i
        // so the first 2 hatches are close to the same angle, 
        // and all the higher i's are fairly random in angle
    	float ang=-.5-.08*float(i)*float(i);
    	vec2 uvh=mat2(CS(ang),N(CS(ang)))*fragCoord/sqrt(sc)*vec2(.05,1)*1.3;
    	vec4 rh = pow(getRand(uvh+1003.123*iTime*FLICKER+vec2(sin(uvh.y),0)),vec4(1.));
    	hatch += 1.-smoothstep(.5,1.5,(rh.x)+br)-.3*abs(r.z);
    	hatch2 = max(hatch2, 1.-smoothstep(.5,1.5,(rh.x)+br)-.3*abs(r.z));
    	sum+=1.;
    	if( float(i)>(1.-br)*float(hnum) && i>=2 ) break;
    }
    
    fragColor.xyz*=1.-clamp(mix(hatch/sum,hatch2,.5),0.,1.);
    

    fragColor.xyz=1.-((1.-fragColor.xyz)*.7);
    // paper
    fragColor.xyz *= .95+.06*r.xxx+.06*r.xyz;
    fragColor.w = 1.;
    
    if(true)
    {
    	vec2 scc=(fragCoord-.5*iResolution.xy)/iResolution.x;
    	float vign = 1.-.3*dot(scc,scc);
    	vign*=1.-.7*exp(-sin(fragCoord.x/iResolution.x*3.1416)*40.);
    	vign*=1.-.7*exp(-sin(fragCoord.y/iResolution.y*3.1416)*20.);
    	fragColor.xyz *= vign;
    }
    
    //fragColor.xyz=getCol(fragCoord).xyz;
}

