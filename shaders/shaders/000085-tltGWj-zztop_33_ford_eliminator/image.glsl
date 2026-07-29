// Image (image) — zztop '33 ford eliminator by flockaroo
// https://www.shadertoy.com/view/tltGWj

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// zztop ford eliminator

//#define RENDERED_REFECTIONS
#define SHADOW
#define SCRATCHES
//#define STREET
#define RENDER_GLASS
//#define WET_ASPHALT
//#define RENDER_BBOX
#define RUMPFW 1.3
#define ALLW (RUMPFW*1.3)

#define Res  (iResolution.xy)

#define RandTex iChannel0

#ifdef SHADEROO
#include Include_A.glsl
#endif

#define BG 0.
#define CARBODY 1.
#define TIRE 2.
#define RIM 3.
#define HEADLIGHTS 4.
#define FLOOR 5.
#define GRILL 6.
#define RUMPF 7.
#define INTERIOR 8.
#define GLASS 9.
#define WATER 10.
#define CHASSIS 11.
#define GUMMI 12.
#define DESERT 13.

//#define SET_PREV_MAT(x) mat=(abs(d-d_mat)>.0001)?(x):mat; d_mat=d;
//#define SET_PREV_MAT(x) mat=mix(mat,x,step(.0001,abs(d-d_mat))); d_mat=d;
//#define SET_PREV_MAT(x) mat+=step(.0001,abs(d-d_mat))*(-mat+x); d_mat=d;
#define SET_PREV_MAT(x) if(abs(d-d_mat)>.0001) mat=(x); d_mat=d;

struct Material{
    vec3 col;
    float refl;
    float scratchy;
    vec2  scratchScale;
};

#define MAT_BG         Material(vec3(-1,-1,-1),       -1.,   0.0, vec2(1,.01))
#define MAT_CARBODY    Material(vec3(.8, .05, .1),    -1.,   0.6, vec2(1,.01))
#define MAT_TIRE       Material(vec3(.15,.15,.15),    -0.35, 1.0, vec2(1,.1)*.3)
#define MAT_RIM        Material(vec3(1,1,1),           1.,   0.2, vec2(1,.01))
#define MAT_HEADLIGHTS Material(vec3(.8),              1.,   0.2, vec2(1,.01))
#ifdef WET_ASPHALT
#define MAT_FLOOR      Material(vec3(.35),            -0.05, 0.0, vec2(1,.01))
#else
#define MAT_FLOOR      Material(vec3(.36,.35,.34)*1.2,            -0.2, 0.0, vec2(1,.01))
#endif
#define MAT_GRILL      Material(vec3(.8),              1.,   0.1, vec2(1,.1))
#define MAT_RUMPF      Material(vec3(.8, .05, .1),    -1.,   0.6, vec2(1,.01))
#define MAT_INTERIOR   Material(vec3(.9,.7,.5)*.3,    -0.0,  0.0, vec2(1,.01))
#define MAT_GLASS      Material(vec3(1),              -1.,   0.6, vec2(1,.01))
#define MAT_WATER      Material(vec3(.1),             -1.,   0.0, vec2(1,.01))
#define MAT_CHASSIS    Material(vec3(.4),              0.5,  1.0, vec2(1,.01)*.5)
#define MAT_GUMMI      Material(vec3(.3),             -0.1,  1.0, vec2(1,.01))
#define MAT_DESERT     Material(vec3(.58,.55,.53)*.85,-0.2,  0.0, vec2(1,.01))

#define USE_MTL_ARRAY 
#ifdef USE_MTL_ARRAY
const Material mat[14] = Material[] (
MAT_BG        ,
MAT_CARBODY   ,
MAT_TIRE      ,
MAT_RIM       ,
MAT_HEADLIGHTS,
MAT_FLOOR     ,
MAT_GRILL     ,
MAT_RUMPF     ,
MAT_INTERIOR  ,
MAT_GLASS     ,
MAT_WATER     ,
MAT_CHASSIS   ,
MAT_GUMMI     ,
MAT_DESERT
);
Material getMaterial(float mtl) { return mat[int(mtl)]; }
#else
Material getMaterial(float mtl)
{
    if(mtl==BG)           return MAT_BG        ;
    if(mtl==CARBODY)      return MAT_CARBODY   ;
    if(mtl==TIRE)         return MAT_TIRE      ;
    if(mtl==RIM)          return MAT_RIM       ;
    if(mtl==HEADLIGHTS)   return MAT_HEADLIGHTS;
    if(mtl==FLOOR)        return MAT_FLOOR     ;
    if(mtl==GRILL)        return MAT_GRILL     ;
    if(mtl==RUMPF)        return MAT_RUMPF     ;
    if(mtl==INTERIOR)     return MAT_INTERIOR  ;
    if(mtl==GLASS)        return MAT_GLASS     ;
    if(mtl==WATER)        return MAT_WATER     ;
    if(mtl==CHASSIS)      return MAT_CHASSIS   ;
    if(mtl==GUMMI)        return MAT_GUMMI     ;
    if(mtl==DESERT)       return MAT_DESERT    ;
}
#endif

bool enable_glass=true;

#ifndef RandTex 
#define RandTex iChannel1
#endif

vec4 getRand(vec2 coord)
{
    vec4 c=vec4(0);
    c+=texture(RandTex,coord+.003*iTime);
    c+=texture(RandTex,coord/2.+.003*iTime)*2.;
    c+=texture(RandTex,coord/4.+.003*iTime)*4.;
    c+=texture(RandTex,coord/8.+.003*iTime)*8.;
    return c/(1.+2.+4.+8.);
}

#define FloorZ -.66
//#define HomePos vec3(0,0,-FloorZ*1.5)
//#define CamDist0 18.

// envoronment just a sky and some floor grid...
vec4 myenv(vec3 pos, vec3 dir, float period_)
{
    vec3 sun = normalize(getLightDir());
    vec3 skyPos=pos+dir/abs(dir.z)*(120.-pos.z);
    float cloudPat=(1.+.4*(getRand(skyPos.xy*.0002).x-.5));
    vec3 colHor=vec3(.3,.4,.5)+.4;
    float dirl=dot(dir,sun);
    vec3 clouds=mix(vec3(1.)*(1.-2.*dirl),vec3(.8,1.,1.2),cloudPat);
    vec3 colSky=mix(vec3(1.5,.75,0.)*3.,clouds,clamp(7.*dir.z,0.,1.));
    vec3 colFloor=vec3(.45);
    
    vec3 col=mix(colSky,colFloor,1.-smoothstep(-.01,.01,dir.z));
    col=mix(colHor,col,clamp(abs(dir.z*5.)-.1,0.,1.));
    
    col*=.9;
    
    //float sunang=acos(dot(dir,sun));
    float sunang=atan(length(cross(dir,sun)),dot(dir,sun));
    col+=15.*clamp(2.*exp(-sunang/.02),0.,1.);
    col+=2.*clamp(2.*exp(-sunang/.20),0.,1.);
    
    return vec4(col,1);
}


float distTire(vec3 p, float r)
{
    p=abs(p);
    float d=1000.;
    d=min(d,length(p)-r);
    d=max(d,distTorus(p.yzx,r*.75,r*.38));
    d=max(d,-length(p.yz)+r*.61);
    float dx=.07;
    float xfr=mod(p.x,dx);
    float x=p.x-xfr+dx*.5;
    d=max(d,-distTorus(p.yzx-vec3(0,0,x),sqrt(r*r-x*x),.015));
    return d;
}
float distRim(vec3 p, float r)
{
    r*=.6;
    p=abs(p);
    p=p.zxy;
    float d=1000.;
    d=min(d,sdRoundedCylinder(p,r,.01,1.1*r));
    p-=vec3(0,.6*r,0);
    d=-smin(-d,sdRoundedCylinder(p,.97*r,.01,.1*r),.005);
    d=-smin(-d,sdRoundedCylinder(p,.89*r,.01,.4*r),.005);
    d=-smin(-d,sdRoundedCylinder(p,.77*r,.01,.8*r),.005);
    d=min(d,sdCone(p.xzy-vec3(0,0,-.2*r),cos(1.1-vec2(0,1.57))));
    float mang,ang;
    float ang0 = atan(p.z,p.x);
    mang=mod(ang0,PI2/12.);
    ang=ang0-mang+PI2/12.*.5;
    d=-smin(-d,(length(p.xz-.58*r*cos(ang-vec2(0,1.57)))-.1*r),.005);
    mang=mod(ang0,PI2/24.);
    ang=ang0-mang+PI2/24.*.5;
    d=min(d,max(abs(p.y+.6*r)-.22*r,(length(p.xz-.73*r*cos(ang-vec2(0,1.57)))-.035*r)));
    return d;
}

const vec3 bbpos=vec3(0,-.06,.07);
const vec3 bbsize=vec3(ALLW*1.12,3.63,1.5);
const vec3 bbpos1=vec3(0,-.0,-.11);
const vec3 bbsize1=vec3(ALLW*1.12,3.73,1.13);
const vec3 bbpos2=vec3(0,.23,.47);
const vec3 bbsize2=vec3(ALLW*.83,1.25,.7);

float rille2(float d, float w)
{ 
    return w*exp2(-d*d*2./w/w);
}
float rille(float d, float w)
{
    ///// gauss
    //return w*exp2(-d*d*2./w/w);
    ///// exp
    return w*exp2(-abs(d)*1.44/w);
    ///// linear
    //return max(abs(d)-w,0.);
}

#define USE_SIMDATA
#ifdef USE_SIMDATA
#define SteerAng (texelFetch(iChannel1,ivec2(4,0),0).x)
#define WheelRot (texelFetch(iChannel1,ivec2(5,0),0))
#define CamDistFact (texelFetch(iChannel1,ivec2(4,0),0).y)
#else
uniform float SteerAng;
const vec4 WheelRot=vec4(0);
#define CamDistFact 1.0
#endif

vec2 distCar(vec3 p)
{
    vec3 p0rot=p;
    p=transformVecByQuat(p,axAng2Quat(vec3(1,0,0),-.023));
    float d=1000., d_mat=1001., mat=-1.;
    SET_PREV_MAT(BG);
    p*=2.;
    if(p.x<0.) p.x=-p.x;
    vec3 p0=p;
    //d=min(d,length(p)-.5);
    p=p0+vec3(0,.1,0);
    float drumpf=sdRoundBox( p, vec3(RUMPFW+p.y*.15-p.y*p.y*.04+p.z*p.y*.03, 
                                 3.2-p.z*.3+p.z*p.z*.1 - step(0.,-p.y)*p.x*.3-step(0.,p.y)*.4*p.z, 
                                 .8+p.y*.02-p.x*p.x*.05*(1.+.01*(p.y*p.y*p.y*p.y))),
                             max(p.y*.04,mix(.25+p.y*.05,.07,-p.z*1.5+.5)))*.7;
    p=p0-vec3(0,.5,.87);
    float dcabin = sdRoundBox( p, vec3(RUMPFW*1.05+p.y*.07-p.y*p.y*.08+p.z*.0, 
                                       1.2-p.z*.3,
                                       .7+p.y*.07-p.x*p.x*.05-p.y*p.y*.05),
                               .33+.15*p.y )*.7;
    d=min(d,dcabin);
    // rear front screen
    p=p0-vec3(0,.4,.88+.10-.06*p.x*p.x);
    //float dfrontscr=sdRoundBox( p, vec3(RUMPFW*.4-step(0.,p.y)*.2,2.,.1-step(0.,p.y)*.03)*2., .1 )*.7;
    // only 2d needed - not sure if rect is faster - maybe some compilers can optimize something out...
    float sy=step(0.,p.y);
    float dfrontscr=sdRoundRect( p.xz-vec2(0,sy*.1), vec2(RUMPFW*.4-sy*.2,.14-step(0.,p.y)*.07)*2., .14-sy*.04 )*.7;
    dfrontscr=max(dfrontscr,-(drumpf-.07));
    d=-smin(-d,dfrontscr,.03);
    //d+=rille(dfrontscr-.03,.007);
    // side screens
    p=p0-vec3(0,.23,.96);
    vec3 sidebox=vec3(2.,.35-p.z*.1,.105+p.y*.008-.05*p.y*p.y*step(0.,p.z))*2.;
    //float dsidescr=sdRoundBox( p-vec3(0,.1*p.z,.015*p.y), sidebox, .13+.04*p.y )*.7;
#if 0
    float dsidescr=sdRoundRect( p.yz-vec2(.1*p.z,.015*p.y), sidebox.yz, .13+.04*p.y )*.7;
    //p.z+=.25;
    //float ddoor   =sdRoundBox( p-vec3(0,.1*p.z,.015*p.y)+vec3(0,0,.59), sidebox+vec3(0,0,.59), .13+.04*p.y )*.7;
    float ddoor   =sdRoundRect( p.yz-vec2(.1*p.z,.015*p.y)+vec2(0,.59), sidebox.yz+vec2(0,.59), .13+.04*p.y )*.7;
#else
    // not sure if even making 2 rects at once is really faster...
    vec2 dssdoor=sdRoundRect2( (p.yz-vec2(.1*p.z,.015*p.y)).xyxy+vec4(0,0,0,.59), sidebox.yzyz+vec4(0,0,0,.59), vec2(.13+.04*p.y) )*.7;
    float dsidescr=dssdoor.x;
    float ddoor=dssdoor.y;
#endif
    ddoor-=.07;
    p=p0-vec3(0,-2.05,.77)*1.;
    p=transformVecByQuat(p-vec3(0,p.x*.25,0),axAng2Quat(vec3(1,0,0),.28));
    //float dhood   =sdRoundBox( p,vec3(ALLW,.9,1.),.18)*.7;
    float dhood   =sdRoundRect( p.yz,vec2(.9,1.),.18)*.7;
    d=-smin(-d,dsidescr,.05);
    //d=-smin(-d,abs(dsidescr-.03),.02);
    d-=clamp((abs(dsidescr-.03)-.016)*.2,-0.02,0.);
    p=p0;
    p-=vec3(0,0,-.77);
    float dz1=.5*(cos(p.x*4./ALLW)-1.)*(cos(p.y*1.5-2.-step(2.86,-p.y)*.8*(p.y+2.86)*(p.y+2.86))*.4+.4)*step(.766,-p.y);
    float dz2=.5*(cos(p.x*3.3/ALLW)-1.)*clamp((cos(p.y*.6-1.5)*2.5-2.)*1.7,0.,1.);
    p.z+=dz1+dz2;
    p-=vec3(0,-.07,0);
    //float dfender = sdHalfRoundBox( p, vec3(ALLW+p.y*.05,
    //                            3.5-.12*cos(p.x*p.x*3.3/ALLW*(.85+.15*step(0.,-p.y)))*(.3+.7*step(0.,-p.y)),.16),
    //                            .16 )*.7;
    float dfender = sdRoundBox( p-vec3(0,0,-.3), vec3(ALLW+p.y*.05,
                                3.5-.1*cos(p.x*p.x*3.3/ALLW*(.85+.15*step(0.,-p.y)))*(.3+.7*step(0.,-p.y)),.16+.3),
                                .16 )*.7;
    float ss=1.-smoothstep(-3.,-1.8,p.y);
    float fz0=p.z-dz1*(exp2(-ss*7.));
    dfender=min(dfender,(sqrt(dfender*dfender+fz0*fz0)-.01)*.7);
    dfender=max(dfender,-(fz0)*.7);
    d=min(d,dfender);
    SET_PREV_MAT(CARBODY);
    //drumpf-=clamp(abs(dhood)-.005,-0.02,0.);
    drumpf+=rille(dhood,.005);
    //side stripe
    p=p0+vec3(0,.1,0);
    drumpf-=.6*rille2(p.z-.4+.03*p.y-.1*p.x,.02)*(1.-smoothstep(2.4,2.6,abs(p0.y+.3)));
    //*clamp((abs(p.z-.55)-.02)*.5,-0.02,0.);
    d=smin(d,drumpf,.03);
    //d=-smin(-d,abs(ddoor),.01);
    //d-=clamp(abs(ddoor)-.005,-0.02,0.);
    d+=rille(ddoor,.005);
    SET_PREV_MAT(RUMPF);
    d=min(d,dfender+.01-.03*smoothstep(-1.45,-1.4,-p0.y)*smoothstep(-.95,-.9,p0.y));
    SET_PREV_MAT(TIRE);
    d=min(d,step(0.,p.y)+length(vec2(dfrontscr-.01,dcabin+.01))-.015);
    SET_PREV_MAT(GUMMI);
    d=min(d,step(0.,p.y)+length(vec2(dfrontscr-.02,dcabin+.01))-.02);
    SET_PREV_MAT(GRILL);
    float z=p.z+.2;
    float dgrillhole=sdRoundBox( p-vec3(0,-3.,-.02), vec3(.18*.9*RUMPFW-step(0.,-z)*z*z*.58*RUMPFW,.5,.33)*2., .1 );
    d=-smin(-d,dgrillhole,.04);
    SET_PREV_MAT(CARBODY);
    //SET_PREV_MAT(TIRE);

    p=p0-vec3( 0, -3.26+.3*p.z+.35*p.x-.1*p.z*p.z, 0);
    p.x=mod(p.x+.005,.025)-.0125;
    d=min(d,max(dgrillhole,(length(p.xy)-.007)*.8));
    SET_PREV_MAT(GRILL);

    p=p0-vec3(0,.7,.87-.2);
    d=max(d,-dcabin-.06);
    SET_PREV_MAT(INTERIOR);
    
#ifdef RENDER_GLASS
    // window glass
    //if(enable_glass)
    {
        d=min(d,dcabin+.035+(enable_glass?0.:1000.));
        SET_PREV_MAT(GLASS);
    }
#endif
    
    #define PF (vec3(ALLW*.39,-1.43,-.33)*2.)
    #define PR (vec3(ALLW*.48,1.23,-.35)*2.)
    vec3 pf=p0-PF;
    vec3 pr=p0-PR;
    
    // check tire only once
    //bool rear = (dot(pr,pr)<dot(pf,pf));
    float rear = step(0.,p0rot.y);
    float left = step(0.,p0rot.x);
    float leftSgn=sign(p0rot.x);
    p=mix(pf,pr,rear); float siz=mix(.62,.7,rear);
    
    // steering rotation of front wheels
    vec4 q=axAng2Quat(vec3(0,0,1),leftSgn*(1.-.1*leftSgn*sign(SteerAng))*SteerAng*(1.-rear));
#if 0
    p+=vec3(.07,0,0);
    p = (p + 2.0 * cross( q.xyz, cross( q.xyz, p ) + q.w*p ));
    p-=vec3(.07,0,0);
#else
    // the above is exactly this below... why is this not working... bug in nvidia pipeline?! or am i missing sth here??
    p=transformVecByQuat(p+vec3(.07,0,0),q)-vec3(.07,0,0);
#endif

#ifdef USE_SIMDATA
    float rot=WheelRot.x;
    p=transformVecByQuat(p,axAng2Quat(vec3(1,0,0),rot));
#endif

    d=min(d, distTire(p,siz));
    SET_PREV_MAT(TIRE);
    d=min(d, distRim(p,siz));
    SET_PREV_MAT(RIM);
    
    p=p0;
    float xx=p.x*p.x;
    p=pf+vec3(ALLW*.38,0,+.1-xx*.03-step(ALLW*.6,p.x)*(p.x-ALLW*.6)*.3)*2.;
    d=min(d,max(length(p.yz)-.05,p.x-ALLW*.7));
    d=min(d,dDirLine(pf,vec3(-.4,-.1,-.1),vec3(-1,0,1.5),.5)-.04);
    d=min(d,dDirLine(pf,vec3(-.3,.1,-.14),vec3(-.0,1,0.05),1.5)-.02);
    SET_PREV_MAT(CHASSIS);
    
    p=p0-vec3(.37,-1.57,0.1)*2.;
    float d1=1000.;
    d1=min(d1, length(p)-.11*2.1);
    d1=-smin(-d1, (length(p+vec3(0,.35,0))-.17*2.1),.02);
    d=min(d,d1);
    SET_PREV_MAT(HEADLIGHTS);
    
    #ifdef RENDER_BBOX
    //if(enable_glass)
    {
        p=p0;
        d=min(d,abs(sdRoundBox( p0rot-bbpos1, bbsize1*.5, .0))+(enable_glass?0.:1000.));
        d=min(d,abs(sdRoundBox( p0rot-bbpos2, bbsize2*.5, .0))+(enable_glass?0.:1000.));
        SET_PREV_MAT(GLASS);
    }
    #endif
    
    return vec2(d*.5,mat);
}

bool enable_car=true;

float lorentz(float x) { return 1./(1.+x*x); }

#define RND_SC 1.
float hTerr(vec3 p)
{
    vec4 rTerr=.8*textureLod(iChannel0,p.xy*.00006*RND_SC,0.)+.4*textureLod(iChannel0,p.xy*.00012*RND_SC,0.);
    float pp=dot(p.xy,p.xy)/(200.*200.);
    return rTerr.x*min(pp*pp,40.);
}

vec4 getTiltQuat(vec3 pos)
{
    float h0 =hTerr(pos);
    vec2  dh=vec2(hTerr(pos+vec3(2,0,0))-h0,
    			  hTerr(pos+vec3(0,2,0))-h0)*.5;
    
    //return axAng2Quat(normalize(vec3(dh.y,-dh.x,0)),atan(length(dh)));
    // same as above axAng2Quat(...) - but less angle back/forth conversions
    float ch = sqrt(.5+.5/sqrt(1.+dot(dh,dh)));      // cos(ang/2)
    return vec4(vec3(dh.y,-dh.x,0)*(ch-.5/ch),ch);  // (ch-.5/ch) == sin(ang/2)/tan(ang);
}

vec3 carTrafo(vec3 p, float translate)
{
#ifdef USE_SIMDATA
    vec4 q=texelFetch(iChannel1,ivec2(3,0),0);
    vec3 offs=texelFetch(iChannel1,ivec2(0,0),0).xyz;
    offs.z=-hTerr(-offs);
    q=multQuat(getTiltQuat(-offs),q);
    return transformVecByQuat(p+translate*offs,inverseQuat(q));
#else
    return p;
#endif
}

vec3 carTrafo(vec3 p)
{
    return carTrafo(p,1.0);
}

vec3 carTrafoInv(vec3 p, float translate)
{
#ifdef USE_SIMDATA
    vec4 q=texelFetch(iChannel1,ivec2(3,0),0);
    vec3 offs=texelFetch(iChannel1,ivec2(0,0),0).xyz;
    offs.z=-hTerr(-offs);
    q=multQuat(getTiltQuat(-offs),q);
    return transformVecByQuat(p,q)-offs*translate;
#else
    return p;
#endif
}

vec2 distM(vec3 p)
{
    float d=1000., mat=-1., d_mat=d;
    if(enable_car)
    {
        vec2 dm=distCar(carTrafo(p));
        d=dm.x; mat=dm.y; d_mat=d;
    }
    vec4 r=texture(iChannel0,p.xy*1.5*RND_SC,0.)-.5;
    vec4 r2=texture(iChannel0,(p.xy*.005*RND_SC),-.5)-.5;
    vec4 r3=texture(iChannel0,(p.xy*.015*RND_SC),-.0)-.5;
    vec4 r4=texture(iChannel0,(p.xy*.03*RND_SC),-.0)-.5;
    vec4 r5=texture(iChannel0,(p.xy*.06*RND_SC),-.0)-.5;
    float rm=r3.y*1.+r4.y*.5+r5.y*.25;
    float rm2=r3.z*.7+r4.z*.5;
    float pp=dot(p.xy,p.xy)/(200.*200.);
    #ifdef STREET
    float streetstep=smoothstep(4.5,5.5,abs(p.x-2.));
    #else
    float streetstep=0.;
    #endif
    d=min(d,p.z
    +.66
    #ifndef STREET
    -hTerr(p)
    #endif
    //+.015*(r3.y-.2)
    #ifdef WET_ASPHALT
    +lorentz(-rm/.06/r2.x)*.05*(r2.x+.3)
    #else
    -.02-min(-abs(rm)*.06,.04-exp(-abs(rm/(r2.x+.15)*.25)*3.)*.07)-r.x*.0035
    #endif
    );
    SET_PREV_MAT(FLOOR);
    
    #ifdef STREET
    d=min(d,p.z
    +.73
    +r2.z*.1+r.z*.01
    -streetstep*.2
    -hTerr(p)
    );
    SET_PREV_MAT(DESERT);
    #endif
    #ifdef WET_ASPHALT
    d=min(d,p.z+.665+pp*16./*-.02*/);
    SET_PREV_MAT(WATER);
    if(mat==FLOOR) d-=r.x*.0035;
    #endif
    
    return vec2(d,mat);
}

float dist(vec3 p) { return distM(p).x; }

vec3 getGradOld(vec3 p,float delta)
{
    float v=dist(p);
    vec2 d=vec2(delta,0); return vec3( dist(p+d.xyy)-v,
                                       dist(p+d.yxy)-v,
                                       dist(p+d.yyx)-v )/delta;
}

/// my own version of a looped getGrad()
vec3 getGrad(vec3 p,float delta)
{
    vec4 d=vec4(0,0,0,1); 
    vec3 s=vec3(0);
    // use a loop here keep compiler from inlining this in win (thanks iq for the hint!)
    for(int i=min(0,iFrame);i<4;i++)
    {
      	s+=(d.xyz-d.w)*dist(p+d.xyz*delta);
        d=d.wxyz;
    }
    return s/delta;
}

/// klems' getGrad - slightly modified to avoid div by 0
vec3 getGrad2(vec3 p,float delta)
{
    // use loop here to keep compiler from inlining this in win (thanks iq for the hint!)
    // btw very interesting function that...
    vec4 n = vec4(0.0);
    for( int i=min(iFrame,0); i<4; i++ )
    {
        vec4 s = vec4(p, 0.0);
        s[i] += delta;
        n[i] = dist(s.xyz);
    }
    n-=n.w;
    return n.xyz/(length(n.xyz)+.0001); // added some small epsilon to avoid division by 0
}

float march(inout vec3 p, vec3 dir)
{
    //if(!intersectBox(p-bbpos,dir,bbsize)) { enable_car=false; }
    vec3 pc=carTrafo(p);
    vec3 pdir=carTrafo(dir,0.);
    //enable_car=true;
    if(!(intersectBox(pc-bbpos1,pdir,bbsize1)||intersectBox(pc-bbpos2,pdir,bbsize2))) { enable_car=false; }
    vec3 p0=p;
    float eps=.001;
    float dmin=1000.;
    bool findmin=false;
    float d=dist(p);
    vec3 pmin=p;
    for(int i=0;i<150;i++)
    {
        float dp=d;
        d=dist(p);
        p+=dir*d*.8;
#ifdef SHADOW
        if (d<dp) findmin=true;
        if (findmin && d<dmin) { dmin=d; pmin=p; }
#endif
        if (d<eps) return 0.;
        if (d>300.) break;
    }
    return clamp(dmin/length(pmin-p0)/.05,0.,1.);
}

float wstep(float w, float thr, float x)
{
    return smoothstep(thr-w*.5,thr+w*.5,x);
}

float getAO(vec3 pos, vec3 n)
{    
    float ao=1.;
    float sc=.025;
    float amb=.3;
    // use loop here to keep compiler from inlining this in win (thanks iq for the hint!)
    for( int i=min(iFrame,0); i<5; i++ )
    {
    	ao*=mix(dist(pos+n*sc)/sc*1.4,1.,amb);
    	ao=clamp(ao,0.,1.);
        sc*=2.;
        amb=min(amb+.1,.5);
    }
    return ao;
   	/*
    ao*=dist(pos+n*.02)/.02*1.4*.7+.3;
   	ao=clamp(ao,0.,1.);
    ao*=dist(pos+n*.05)/.05*1.4*.6+.4;
    ao=clamp(ao,0.,1.);
    ao*=dist(pos+n*.1)/.1*1.4*.5+.5;
    ao=clamp(ao,0.,1.);
    ao*=dist(pos+n*.2)/.2*1.4*.5+.5;
    ao=clamp(ao,0.,1.);
    ao*=dist(pos+n*.4)/.4*1.4*.5+.5;
    ao=clamp(ao,0.,1.);*/
}

vec3 lighting(vec3 pos, vec3 dir, vec3 pos0, float reflections, inout float outfres, inout float outao)
{
    vec3 pc=carTrafo(pos);
    vec3 glasspos=vec3(1000.);
    vec3 glassn=vec3(0.);
    float mat=distM(pos).y;
    if(mat==GLASS)
    {
        glasspos=pos;
        glassn=normalize(getGrad(pos,.001));
        enable_glass=false;
        march(pos,dir);
    }
    mat=distM(pos).y;
    
    vec3 light=getLightDir();
    float sh=1.;
#ifdef SHADOW
    vec3 posS=pos+.017*light;
    enable_car=true;
    sh=march(posS,light);
#endif
    enable_car=true;
    vec3 n=getGrad(pos,.001);
    if (length(n)<.001) n=vec3(0,0,1);
    n=normalize(n);
    if(mat==BG) n=vec3(0,0,1);

    float ao=getAO(pos,n);
    ao=sqrt(ao);
    ao=ao*.7+.3;

    float diff=clamp(dot(n,light),0.,1.);

    diff=min(diff,sh);
    
    // no ao in lighted areas
    ao=mix(ao,1.,diff);
    ao=clamp(ao,0.,1.);
    //return vec3((diff*.6+.4)*(ao));
    

    Material mtrl=getMaterial(mat);

    // evironmental reflection
    n=normalize(n);
    vec3 R=reflect(dir,n);
    vec3 refl=myenv(pos,R.xyz,1.).xyz;
    //refl=refl*1.2+.3;
    float fres=abs(dot(R,n));
    fres=1.-fres;
    fres*=fres*fres;
    fres=fres*.9+.1;
    float fres0=fres;
    #ifdef SCRATCHES
    vec3 n0=n;
    int numscr=7;
    float dang=1.57*2./float(numscr);
    float ang=.5;
    refl*=1.;
    vec3 drefl=vec3(0);
    float sum=0.;
    vec3 pi=pc;
    vec3 heading=vec3(0,0,1);
    vec3 tan1=vec3(1,0,0);
    vec3 tan2=vec3(0,1,0);
    // ...trying to implement some micro scratches
    for(int i=0;i<numscr*3;i++)
    {
        n=n0;
        vec2 cs=cos(ang+vec2(0,-1.57));
        mat2 m=mat2(cs,cs.yx*vec2(-1,1));
        //dFdx()
        vec2 dn2d=(texture(iChannel0,(m*pi.xy)*vec2(6.,.1)*mtrl.scratchScale+vec2(0,.5/256.)).x-.5)*mtrl.scratchScale;
        dn2d=pow(abs(dn2d),vec2(.7))*sign(dn2d);
        dn2d=dn2d*m;
        //dn2d=dn2d.yx*vec2(1,-1);
        n+=abs(dot(n0,heading))*carTrafoInv(dn2d.x*tan1+dn2d.y*tan2,0.);
        n=normalize(n);
        R=reflect(dir,n);
        float fres=abs(dot(R,n));
        fres=1.-fres;
        fres*=fres*fres;
        fres=fres*.4+.6;
        float fact=(abs(dot(n0,-dir))*.8+.2)*fres;
        //fact=.2;
        drefl+=fact*myenv(pos,R.xyz,1.).xyz;
        sum+=fact;
        ang+=dang;
        pi=pi.zxy;
        heading=heading.yzx;
        tan1=tan1.yzx;
        tan2=tan2.yzx;
    }
    drefl/=float(numscr);
    refl=mix(refl,drefl,mtrl.scratchy);
    #endif
    
    #ifdef RENDER_GLASS
    vec3 Rg=reflect(dir,glassn);
    vec3 glassrefl=myenv(pos,Rg.xyz,1.).xyz;
    //glassrefl=glassrefl*1.2+.3;
    float glassfres=abs(dot(Rg,glassn));
    glassfres=1.-glassfres;
    glassfres*=glassfres*glassfres;
    glassfres=glassfres*.85+.15;
    if(glassn==vec3(0)) glassfres=0.;
    #endif

    vec3 rcol=vec3(1);
    fres=(mtrl.refl<0.)?fres*-mtrl.refl:mtrl.refl;
    rcol=(mtrl.refl<0.)?vec3(1):mtrl.col;
    vec3 col=mtrl.col;
    if(mat==FLOOR) {
        col+=(texture(iChannel0,pos.xy*2.,-1.2).x-.5)*.3;
        col*=.9+.2*texture(iChannel2,pos.xy*.2).xyz;
        #ifdef WET_ASPHALT
        col*=.35+.65*step(-.66,pos.z);
        fres=fres0*mix(-mtrl.refl,1.,(1.-smoothstep(-.661,-.659,pos.z))*exp(-length(pos.xy)/50.));
        #endif
    }

    vec4 zzt=vec4(0);
    {
        vec3 p=carTrafo(pos);
    #ifndef ZZT_AS_TEX
 	    float sp=sign(p.x); // windows not able to compile if i substitute this directly below... [rolleyes]
        zzt=zztop((p.yz*8.5*vec2(sp,1)-vec2(sp,.9))*vec2(1,1.-.15*p.y),sp);
    #else
        vec2 uv=(vec2(-1,1)*(p.yz*8.5-vec2(1,.9))*vec2(1,1.-.15*p.y)/11.+.75)*.5;
        uv=clamp(uv,0.,1.);
        zzt=texture(iChannel1,uv);
    #endif
    }
    if(mat==RUMPF) { 
        col=mix(col,zzt.xyz,zzt.w);
        if(zzt.xyz==vec3(1)) { fres=.6; col*=.0; }
    }
    //col-=n*.05;
    
    float zr=length(pos-pos0)/300.;
    //diff=sqrt(diff);

    outfres=fres;
    if(glassfres!=0.) outfres=glassfres;
    fres*=reflections;
    glassfres*=reflections;

    outao=ao;
    
	vec3 bg=myenv(pos0,dir,1.).xyz;
	// diff, ao, refl
	vec3 finalcol = mix(col,rcol*refl,fres)*mix(vec3(1.2,1.4,1.5)*.5,vec3(1.,1,.9),diff)*ao*1.3;
	//finalcol=col;
	// fog
	//finalcol = mix(finalcol,bg,1.-exp(-zr));
	finalcol = mix(finalcol,bg,1.-clamp(exp(-zr+.1),0.,1.));
	#ifdef RENDER_GLASS
	finalcol=mix(finalcol,glassrefl,glassfres);
	#endif
	return finalcol;
}

vec4 camAnim[8] = vec4[] (
    vec4( 1.5, -2.75,-0.25 ,1.), vec4(0,1.,.1, 0.),
    vec4(-1.5, -2.75,-0.25 ,1.), vec4(.5,1.,.1, 0.),
    //vec4(-2., -1.5,-0.25 ,1.), vec4(1.,0.,.1, 0.),
    vec4(-2., 3.,-0.35 ,1.), vec4(.5,-1,.1, 0.),
    vec4(-2., 3.,-0.35 ,1.), vec4(.5,-1,.1, 0.)
    );
    
vec3 getCamAnimPos(float t)
{
    t*=.1;
    int i_f=int(t); float fact=fract(t); int i_c=i_f+1;
    i_c=min(3,i_c);
    i_f=min(3,i_f);
    return mix(camAnim[i_f*2].xyz,camAnim[i_c*2].xyz,fact);
}

vec3 getCamAnimDir(float t)
{
    t*=.1;
    int i_f=int(t); float fact=fract(t); int i_c=i_f+1;
    i_c=min(3,i_c);
    i_f=min(3,i_f);
    return mix(camAnim[i_f*2+1].xyz,camAnim[i_c*2+1].xyz,fact);
}

float getCamAnimBr(float t)
{
    t*=.1;
    int i_f=int(t); float fact=fract(t); int i_c=i_f+1;
    i_c=min(3,i_c);
    i_f=min(3,i_f);
    return mix(camAnim[i_f*2].w,camAnim[i_c*2].w,fact);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 sc=(fragCoord-Res*.5)/Res.x;
    
    float zoom=1.;
    #ifdef SHADEROO
    zoom=exp(-iMouseData.z/5000.);
    #endif
    zoom*=CamDistFact;

    vec3 CarPos = carTrafoInv(vec3(0),1.);
    vec3 pos=vec3(0,0,4.5)*zoom;
    vec3 dir=normalize(vec3(sc,-.8));
    
    vec4 q=vec4(0,0,0,1);
    float th=-(iMouse.y-Res.y*.5)/Res.y*6.;
    float ph=-(iMouse.x-Res.x*.5)/Res.x*10.;
    if(iMouse.x<1.) { th=1.45; ph=-iTime*.25; }
    th=clamp(th,-1.65,1.65);
    q=multQuat(q,axAng2Quat(vec3(0,0,1),ph));
    q=multQuat(q,axAng2Quat(vec3(1,0,0),th));
    pos=transformVecByQuat(pos,q)-vec3(0,0,.2);
    dir=transformVecByQuat(dir,q);
    pos=carTrafoInv(pos,1.);
    dir=carTrafoInv(dir,0.);

    if(iMouse.x<1.)
    {
    pos=getCamAnimPos(iTime);
    dir=normalize(getCamAnimDir(iTime));
    vec3 right=normalize(cross(dir,vec3(0,0,1)));
    vec3 up=cross(right,dir);
    dir=normalize(dir+right*sc.x+up*sc.y);
    }
    
    vec3 pos0=pos;
    float m=march(pos,dir);
    
    float refl=1.;
    #ifdef RENDERED_REFECTIONS
    refl=0.;
    #endif
    float fres=0., ao=0.;
    fragColor.xyz=lighting(pos,dir,pos0,refl,fres,ao);
    #ifdef RENDERED_REFECTIONS
    enable_glass=true;
    vec3 n=getGrad(pos,.001);
    if (length(n)<.001) n=vec3(0,0,1);
    n=normalize(n);
    dir=reflect(dir,n);
    pos+=dir*.003;
    /*fres=abs(dot(dir,n));
    fres=1.-fres;
    fres*=fres*fres;
    fres=fres*.9+.1;*/
    float mat=distM(pos).y;
    march(pos,dir);
    float dummyfres,dummyao;
    vec3 lcol=lighting(pos,dir,pos0,1.,dummyfres,dummyao);
    fragColor.xyz=mix(fragColor.xyz,lcol,(m!=0.)?0.:fres);
    #endif
    
    fragColor*=1.-exp(-getCamAnimBr(iTime)*getCamAnimBr(iTime)/.01);
    
	fragColor.w=1.;
}

#if 0
void mainImageXX( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor=vec4(0);
    float snum=0.;
    for(int i=0;i<max(int(snum),1);i++)
    {
        enable_glass=true;
        vec4 col=vec4(0);
        vec2 r = (texelFetch(iChannel0,ivec2(mod(fragCoord+vec2(i*5+iFrame*13,0)+.1,256.0))&255,0).xy-.5)*1.;
        //vec2 r = getRand(i+int(fragCoord.x+fragCoord.y*iResolution.x)).xy-.5;
        mainImageS(col,fragCoord+r*((snum>0.)?1.:0.3));
        fragColor+=col;
        vec4 r2=texture(iChannel0,fragCoord/Res0*.707+iTime*4.5+float(i)*.1)-.5;
        fragColor+=.05*r2;
    }
    fragColor/=floor(max(snum,1.));
}
#endif

