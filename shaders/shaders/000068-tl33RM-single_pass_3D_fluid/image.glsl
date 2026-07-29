// Image (image) — single pass 3D fluid by flockaroo
// https://www.shadertoy.com/view/tl33RM

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// single pass 3D fluid dynamics

// same fluid as in "molten bismut" but generalized to 3 dimensions
// ...but with self-consistent-ish velocity field
// the previous method was just defined implicitely by the rotations on multiple scales
// here the calculated velocity field is put back into the stored field

// drawing the fluid

//#define RENDER_OBSTACLE
//#define VELOCITY_VAL 2.0
//#define REFRACT
#ifdef OBSTACLE
#define CUT_MIDDLE
#endif

#define Res  (iResolution.xy)

vec3 getVal(vec3 pos)
{
    vec4 coord=coord3to2(pos);
    vec3 v1=textureLod(iChannel0,vec3(coord.xy/Res0.xy-.5,.5),0.).xyz;
    vec3 v2=textureLod(iChannel0,vec3(coord.zw/Res0.xy-.5,.5),0.).xyz;
    return mix(v1,v2,fract(pos.z-.5));
}

#ifndef RandTex 
#define RandTex iChannel1
#endif

vec4 myenv(vec3 pos, vec3 dir, float period)
{
    #ifndef SHADEROO
    return texture(iChannel2,dir.xzy);
    #else
    float azim = atan(dir.y,dir.x);
    float th = asin(dir.z);
    float c=(sin(-azim*5.-1.5)*.15+.25);
    float thr  = .5*.5*(.7*sin(2.*azim*5.)+.3*sin(2.*azim*7.));
    float thr2 = .5*.125*(.7*sin(2.*azim*13.)+.3*sin(2.*azim*27.));
    float thr3 = .5*.05*(.7*sin(2.*azim*32.)+.3*sin(2.*azim*47.));
    float br  = smoothstep(thr-.2, thr+.2, dir.z+.25);
    float br2 = smoothstep(thr2-.2,thr2+.2,dir.z+.15);
    float br3 = smoothstep(thr3-.2,thr3+.2,dir.z);
    vec4 r1 = .5*(texture(RandTex,dir.xy*.01)-texture(RandTex,dir.xy*.017+.33));
    vec3 skyCol=vec3(.9,1,1.1)+.3*(r1.xxx*.5+r1.xyz*.5);
    //skyCol*=2.5;
    vec4 r2 = .5*(texture(RandTex,dir.xy*.1)-texture(RandTex,dir.xy*.07-.33));
    vec3 floorCol = vec3(.9,1.1,1.)*.8+.5*(r2.xxx*.7+r2.xyz*.3);
    vec3 col=mix(floorCol.zyx,skyCol,br3);
    col=mix(floorCol.yzx*.7,col,br2);
    col=mix(floorCol.xyz*.7*.7,col,br);
    vec3 r=texture(RandTex,vec2(azim/PI2*.125,.5)).xyz;
    col*= 1.-clamp(((r.xxx*.7+r.xzz*.3)*2.-1.)*clamp(1.-abs(dir.z*1.6),0.,1.),0.,1.);
    return vec4(col*col*vec3(1.1,1,.9)/**clamp(1.+dir.x*.3,.9,1.2)*/,1);
    #endif
}


float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

//float dist(vec3 p) { return sdBox(p,vec3(1.5)); }
bool box_enable=true;
bool box_neg=false;

float getAbsVel(vec3 p)
{
    return length(getVal(fluidPos(p)));
}

vec3 getVelGrad(vec3 p, float eps)
{
    float v=getAbsVel(p);
    vec3 d=vec3(1,0,0)*eps;
    return vec3(
            getAbsVel(p+d.xyy)-v,
            getAbsVel(p+d.yxy)-v,
            getAbsVel(p+d.yyx)-v
        )/eps;
}

float dist(vec3 p) { 
    float lmin=min(FRes.x,min(FRes.y,FRes.z));
    #ifdef CUT_MIDDLE
    float dbox=sdBox(p-distPos(FRes*.25)*vec3(1,0,0),FRes/lmin*.99*vec3(.5,1,1));
    #else
    float dbox=sdBox(p,FRes/lmin*.99);
    #endif
    float d=1000.;
    //if(box_enable) return dbox;
    if(box_enable) return box_neg?-dbox:dbox;
    //float v=length(getVal((p*.5+.5)*FRes));
    float v=length(getVal(fluidPos(p)));
    float v0=v;
    #ifdef VELOCITY_VAL
    v=abs(v-VELOCITY_VAL);
    d=min(d,v*.1/length(getVelGrad(p,1./dot(FRes,vec3(.333)))));
    #else
    v=abs(fract(v/.5)*.5-.25);
    //d=min(d,v/v0*.1);
    d=min(d,v*.1/length(getVelGrad(p,1./dot(FRes,vec3(.333)))));
    #endif
    //if(!box_enable) d=min(d,-dbox+.01);
#ifdef OBSTACLE
#ifdef RENDER_OBSTACLE
    d=min(d,obstacleDist(p));
#endif
#endif
    d=max(d,dbox);
    return d;
}

vec3 getGrad(vec3 p,float delta)
{
    float v=dist(p);
    vec2 d=vec2(delta,0); return vec3( dist(p+d.xyy)-v,
                                       dist(p+d.yxy)-v,
                                       dist(p+d.yyx)-v )/delta;
}

float march(inout vec3 p, vec3 dir)
{
    //if(!intersectBox(p-bbpos,dir,bbsize)) { enable_car=false; }
    //if(!(intersectBox(p-bbpos1,dir,bbsize1)||intersectBox(p-bbpos2,dir,bbsize2))) { enable_car=false; }
    vec3 p0=p;
    float eps=.0003;
    float dmin=1000.;
    bool findmin=false;
    float d=dist(p);
    vec3 pmin=p;
    for(int i=0;i<500;i++)
    {
        float dp=d;
        d=dist(p);
        p+=dir*d*1.;
#ifdef SHADOW
        if (d<dp) findmin=true;
        if (findmin && d<dmin) { dmin=d; pmin=p; }
#endif
        if (d<eps) return 0.;
    }
    return clamp(dmin/length(pmin-p0)/.05,0.,1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 sc=(fragCoord-Res*.5)/Res.x;
    float zoom=1.;
    #ifdef SHADEROO
    zoom=1.-iMouseData.z/1000.;
    #endif
    float eps = .5/dot(FRes,vec3(.333));
    
    vec3 pos=vec3(0,0,5.5)*zoom;
    vec3 dir=normalize(vec3(sc,-.8));
    vec4 q=vec4(0,0,0,1);
    float th=-(iMouse.y-Res.y*.5)/Res.y*6.;
    float ph=-(iMouse.x-Res.x*.5)/Res.x*10.;
    if(iMouse.x<1.) { th=1.2; ph=-iTime*.25; }
    q=multQuat(q,axAng2Quat(vec3(0,0,1),ph));
    q=multQuat(q,axAng2Quat(vec3(1,0,0),th));
    pos=transformVecByQuat(pos,q);
    dir=transformVecByQuat(dir,q);
    vec3 pos0=pos;

    float m=march(pos,dir);
    vec3 nb=normalize(getGrad(pos,eps));
    vec3 nb2=vec3(1,1,1);
    #ifdef REFRACT
    dir=refract(dir,nb,.7);
    #endif
    if (m!=0.) nb=vec3(1,1,1);
    if (m==0.)
    {
        box_neg=true;
        vec3 pos2=pos+dir*.1;
        m=march(pos2,dir);
        nb2=normalize(getGrad(pos2,eps));
        if (m!=0.) nb2=vec3(1,1,1);
        box_enable=false;
        m=march(pos,dir);
    }

    vec3 n=getGrad(pos,eps);
    if (length(n)<.001) n=vec3(0,0,1);
    n=normalize(n);
    float ao=1.;
    if(m==0.)
    {
    ao*=dist(pos+n*.2)/.1*4.+.5;
    ao*=dist(pos+n*.1)/.1*4.+.5;
    ao*=dist(pos+n*.05)/.1*4.+.5;
    ao*=dist(pos+n*.03)/.1*4.+.5;
    ao=clamp(ao,0.,1.);
    ao=ao*.5+.5;
    }

    fragColor.xyz=vec3(.8,.9,1.);
    fragColor.xyz=mix(fragColor.xyz,nb2*.5+.5,.2);
    if(m==0.)
    {
        vec3 n=normalize(getGrad(pos,eps));
        fragColor.xyz=(1.+.0*n);
        fragColor.xyz*=clamp(dot(n,normalize(vec3(1,1,1.5))),0.,1.)*.3+.7;
        fragColor.xyz*=getVal(fluidPos(pos))*.5+.5;
    }
    fragColor.xyz=mix(fragColor.xyz,nb*.7+.5,.2);
    fragColor=clamp(fragColor,0.,1.);
    fragColor*=ao;
    
    // add some reflection
    fragColor=fragColor+.3*myenv(vec3(0),reflect(dir,n),1.);
    
    // vignetting
    fragColor-=2.*dot(sc,sc);
    
    fragColor.w=1.;
}

