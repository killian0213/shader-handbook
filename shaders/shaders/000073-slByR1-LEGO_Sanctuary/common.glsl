// Common (common) — LEGO Sanctuary by Mathis
// https://www.shadertoy.com/view/slByR1

//CONTROLS
#define DOF
//#define CLAY

//CONSTANTS
const float C_MAX=32.;
const vec3 SunDir=normalize(vec3(1.,0.7,-0.4));
const vec2 eps=vec2(0.002,0.);
const float Sqrt05=sqrt(0.5);
const float Sqrt2=sqrt(2.);
const float I1024=1./1024.;
const float I512=1./512.;
const float I128=1./128.;
const float I64=1./64.;
const float I32=1./32.;
const float I16=1./16.;
const float I6=1./6.;
const float I3=1./3.;
const float I09=1./0.9;
const float PI=3.141592653;
const float IsoDistance=64.;
const float IsoWidth=32.;
const float IsoAngle=39.26;
const vec3 IsoCenter=vec3(1.,0.,1.)*72.+0.05;
const vec3 IsoDir=normalize(vec3(cos(radians(IsoAngle)),-sin(radians(IsoAngle)),cos(radians(IsoAngle))));
const vec3 IsoPos=IsoCenter-IsoDir*IsoDistance;
const vec3 IIsoDir=1./IsoDir;
const vec3 IsoTan=normalize(cross(IsoDir,vec3(0.,1.,0.)));
const vec3 IsoBit=normalize(cross(IsoTan,IsoDir));
const vec3 LEGOSlope=normalize(vec3(-1.,1.,0.));
const vec3 LEGOISlope=normalize(vec3(-1.,-1.,0.));
const vec3 LEGOOSlope=normalize(vec3(-3.5/6.,1.,0.));
const vec3 SPOT_DIR=normalize(vec3(0.,1.,0.75));
#define Aspect vec2(iChannelResolution[0].x/iChannelResolution[0].y,1.)
#define IRES 1./iChannelResolution[0].xy
#define HRES (iChannelResolution[0].xy*0.5)
#define QTFrames (ceil(log2(iChannelResolution[0].y))-1.)
#define InitialFrames 7
struct DF { float D; vec3 C; vec3 E; float R; };
struct HIT { float D; vec3 P; vec3 N; vec3 C; float M; };


//LIGHT
float Schlick(float R0, float COS) {
    //Schlick approximation
    return R0+(1.-R0)*pow(1.-COS,5.);
}

vec3 SampleSky(vec3 d) {
    //Samples the sky
    return vec3(0.2,0.6,1.)*(1.-0.5*d.y)*0.03+vec3(1.,0.3,0.1)*0.8*pow(dot(d,SunDir)*0.5+0.5,5.)+
            +vec3(1.,0.1,0.1)*0.2*pow(dot(d,vec3(-SunDir.x,SunDir.y,-SunDir.z))*0.5+0.5,8.); //Dark sky
}


//MATH
vec2 ABox(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin=(bmin-origin)*dir;
    vec3 tMax=(bmax-origin)*dir;
    vec3 t1=max(tMin,tMax);
    vec3 t2=min(tMin,tMax);
    return vec2(max(max(t2.x,t2.y),t2.z),min(min(t1.x,t1.y),t1.z));
}

vec2 ABox(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin=(bmin-origin)*dir;
    vec2 tMax=(bmax-origin)*dir;
    vec2 t1=max(tMin,tMax);
    vec2 t2=min(tMin,tMax);
    return vec2(max(t2.x,t2.y),min(t1.x,t1.y));
}

vec2 ABoxN(vec3 origin, vec3 idir, vec3 bmin, vec3 bmax, vec3 signdir, out vec3 N) {
    vec3 tMin=(bmin-origin)*idir;
    vec3 tMax=(bmax-origin)*idir;
    vec3 t1=max(tMin,tMax);
    vec3 t2=min(tMin,tMax);
    N = -((t2.x>max(t2.y,t2.z))?vec3(signdir.x,0.,0.):((t2.y>t2.z)?vec3(0.,signdir.y,0.):vec3(0.,0.,signdir.z)));
    return vec2(max(max(t2.x,t2.y),t2.z),min(min(t1.x,t1.y),t1.z));
}

vec2 ABoxNf(vec3 origin, vec3 idir, vec3 bmin, vec3 bmax, vec3 signdir, out vec3 N) {
    vec3 tMin=(bmin-origin)*idir;
    vec3 tMax=(bmax-origin)*idir;
    vec3 t1=max(tMin,tMax);
    vec3 t2=min(tMin,tMax);
    N = ((t1.x<min(t1.y,t1.z))?vec3(signdir.x,0.,0.):((t1.y<t1.z)?vec3(0.,signdir.y,0.):vec3(0.,0.,signdir.z)));
    return vec2(max(max(t2.x,t2.y),t2.z),min(min(t1.x,t1.y),t1.z));
}

float ABoxfar(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin=(bmin-origin)*dir;
    vec3 tMax=(bmax-origin)*dir;
    vec3 t2=max(tMin,tMax);
    return min(min(t2.x,t2.y),t2.z);
}

float ABoxfar(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin=(bmin-origin)*dir;
    vec2 tMax=(bmax-origin)*dir;
    vec2 t2=max(tMin,tMax);
    return min(t2.x,t2.y);
}

vec3 ggx(vec3 n, vec3 dir, vec3 rdir, float roughness, vec3 F0) {
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    float dotNL = clamp(dot(n, rdir), 0., 1.);
    float dotNV = clamp(dot(n, dir), 0., 1.);
    vec3 h = normalize(dir + rdir);
    float dotNH = clamp(dot(n, h), 0., 1.);
    float dotLH = clamp(dot(rdir, h), 0., 1.);
    // GGX microfacet distribution function
    float den = (alpha2 - 1.) * dotNH * dotNH + 1.;
    float D = alpha2 / (PI * den * den);
    // Fresnel with Schlick approximation
    vec3 F = F0 + (1.0 - F0) * pow(1. - dotLH, 5.);
    // Smith joint masking-shadowing function
    float k = .5 * alpha;
    float G = 1. / ((dotNL * (1.0 - k) + k) * (dotNV * (1. - k) + k));
    return D * F * G;
}

vec3 RandSample(vec2 v) {
    float theta=sqrt(v.x);
    float phi=2.*3.14159*v.y;
    float x=theta*cos(phi);
    float z=theta*sin(phi);
    return vec3(x,z,sqrt(max(0.,1.-v.x)));
}

mat3 TBN(vec3 N) {
    vec3 Nb,Nt;
    if (abs(N.y)>0.999) {
        Nb=vec3(1.,0.,0.);
        Nt=vec3(0.,0.,1.);
    } else {
    	Nb=normalize(cross(N,vec3(0.,1.,0.)));
    	Nt=normalize(cross(Nb,N));
    }
    return mat3(Nb.x,Nt.x,N.x,Nb.y,Nt.y,N.y,Nb.z,Nt.z,N.z);
}

vec3 TBN(vec3 N, out vec3 O) {
    O=normalize(cross(N,vec3(0.,1.,0.)));
    return normalize(cross(O,N));
}

float DFLine(vec3 p, vec3 a, vec3 b) {
    //Distance Field
    vec3 ba=b-a;
    float k=dot(p-a,ba)/dot(ba,ba);
    return length((a+clamp(k,0.,1.)*(b-a))-p);
}

float DFBox(vec3 p, vec3 b) {
    vec3 d=abs(p-b*0.5)-b*0.5;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float DFBoxC(vec3 p, vec3 b) {
    vec3 d=abs(p)-b;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float DFBox(vec2 p, vec2 b) {
    vec2 d=abs(p-b*0.5)-b*0.5;
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}

float smin(float a, float b, float k) {
    //https://iquilezles.org/articles/smin
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}
vec2 Rotate(vec2 p, float ang) {
    float c=cos(ang), s=sin(ang);
    return vec2(p.x*c-p.y*s,p.x*s+p.y*c);
}




/*
LEGO
    Stud,rund,
    111,211,2Slope,412,Rund131,
    Kon131,131,231,431,2Slope2,
    Slope,ISlope,OnlySlope,OnlySlope2,
    Headlight,ISlope2
*/
vec2 BrickOffset2[18]=vec2[18](vec2(256.,0.),vec2(384.,0.),
    vec2(512.,0.),vec2(640.,0.),vec2(0.,128.),vec2(256.,128.),vec2(768.,128.),
    vec2(896.,0.),vec2(896.,256.),vec2(0.,384.),vec2(256.,384.),vec2(768.,512.),
    vec2(0.,640.),vec2(256.,640.),vec2(512.,640.),vec2(640.,640.),
    vec2(0.,896.),vec2(256.,896.)
);
vec3 BrickDim[18]=vec3[18](vec3(1.,2.,1.),vec3(1.,2.,1.),
    vec3(1.,2.,1.),vec3(2.,2.,1.),vec3(2.,4.,2.),vec3(4.,2.,2.),vec3(1.,4.,1.),
    vec3(1.,4.,1.),vec3(1.,4.,1.),vec3(2.,4.,1.),vec3(4.,4.,1.),vec3(2.,4.,2.),
    vec3(2.,4.,1.),vec3(2.,4.,1.),vec3(1.,2.,1.),vec3(1.,2.,1.),
    vec3(1.,4.,1.),vec3(2.,4.,1.)
);
vec3 BrickOffset3[18]=vec3[18](vec3(1.,0.,1.),vec3(1.,0.,1.),
    vec3(1.,0.,1.),vec3(2.,0.,0.),vec3(1.5,0.,0.5),vec3(3.5,0.,-1.5),vec3(1.,0.,1.),
    vec3(1.,0.,1.),vec3(1.,0.,1.),vec3(1.5,0.,0.5),vec3(3.5,0.,-1.5),vec3(1.5,0.,0.5),
    vec3(1.5,0.,0.5),vec3(1.5,0.,0.5),vec3(1.,0.,1.),vec3(1.,0.,1.),
    vec3(1.,0.,1.),vec3(1.5,0.,0.5)
);

float DFStud(vec3 p) {
    float d=-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.3,-p.y+0.2,0.075);
    return d;
}

vec4 TraceStud(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        RP=pos+dir*dist;
        if (dist>FAR || RP.y<0.) break;
        t=DFStud(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFStud(RP+eps.xyy)-DFStud(RP-eps.xyy),
                        DFStud(RP+eps.yxy)-DFStud(RP-eps.yxy),
                        DFStud(RP+eps.yyx)-DFStud(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFRund(vec3 p) {
    float d=max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.5,-p.y+0.4,0.04),-p.y+0.3);
    d=min(d,max(max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))-0.397,-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.305)
    ,p.y-0.35),-p.y));
    return d;
}

vec4 TraceRund(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFRund(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFRund(RP+eps.xyy)-DFRund(RP-eps.xyy),
                        DFRund(RP+eps.yxy)-DFRund(RP-eps.yxy),
                        DFRund(RP+eps.yyx)-DFRund(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DF111(vec3 p) {
    float d=DFBox(p-vec3(0.02),vec3(0.96,0.36,0.96))-0.02;
    return d;
}

vec4 Trace111(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DF111(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DF111(RP+eps.xyy)-DF111(RP-eps.xyy),
                        DF111(RP+eps.yxy)-DF111(RP-eps.yxy),
                        DF111(RP+eps.yyx)-DF111(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DF211(vec3 p) {
    float d=DFBox(p-vec3(0.02,0.,0.02),vec3(1.96,0.4,0.96))-0.02;
    return d;
}

vec4 Trace211(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DF211(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DF211(RP+eps.xyy)-DF211(RP-eps.xyy),
                        DF211(RP+eps.yxy)-DF211(RP-eps.yxy),
                        DF211(RP+eps.yyx)-DF211(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DF2Slope(vec3 p) {
    float d=-smin(-DFBox(p-vec3(0.02,0.,0.02),vec3(1.96,1.2,1.96))-0.02,-dot(LEGOSlope,p-vec3(1.,1.2,0.)),0.05);
    return d;
}

vec4 Trace2Slope(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DF2Slope(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DF2Slope(RP+eps.xyy)-DF2Slope(RP-eps.xyy),
                        DF2Slope(RP+eps.yxy)-DF2Slope(RP-eps.yxy),
                        DF2Slope(RP+eps.yyx)-DF2Slope(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DF412(vec3 p) {
    float d=DFBox(p-vec3(0.02,0.,0.02),vec3(3.96,0.4,1.96))-0.02;
    return d;
}

vec4 Trace412(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DF412(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DF412(RP+eps.xyy)-DF412(RP-eps.xyy),
                        DF412(RP+eps.yxy)-DF412(RP-eps.yxy),
                        DF412(RP+eps.yyx)-DF412(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFRund131(vec3 p) {
    float d=max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))-0.397,p.y-0.35),-p.y);
    d=min(d,max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.48,-p.y+1.2,0.05),-p.y+0.2));
    //Stud
    d=smin(d,max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.3,-p.y+1.4,0.07),-p.y+1.2),0.07);
    d=-smin(-d,DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))-0.2,0.07);
    return d;
}

vec4 TraceRund131(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFRund131(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFRund131(RP+eps.xyy)-DFRund131(RP-eps.xyy),
                        DFRund131(RP+eps.yxy)-DFRund131(RP-eps.yxy),
                        DFRund131(RP+eps.yyx)-DFRund131(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFKon131(vec3 p) {
    float d=max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))-0.397,p.y-0.35),-p.y);
    d=min(d,max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+mix(0.48,0.33,p.y-0.2),-p.y+1.2,0.05),-p.y+0.2));
    //Stud
    d=smin(d,max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.3,-p.y+1.4,0.07),-p.y+1.2),0.04);
    d=-smin(-d,DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))-0.2,0.07);
    return d;
}

vec4 TraceKon131(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFKon131(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFKon131(RP+eps.xyy)-DFKon131(RP-eps.xyy),
                        DFKon131(RP+eps.yxy)-DFKon131(RP-eps.yxy),
                        DFKon131(RP+eps.yyx)-DFKon131(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DF131(vec3 p) {
    float d=DFBox(p-vec3(0.02,0.,0.02),vec3(0.96,1.2,0.96))-0.02;
    return d;
}

vec4 Trace131(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DF131(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DF131(RP+eps.xyy)-DF131(RP-eps.xyy),
                        DF131(RP+eps.yxy)-DF131(RP-eps.yxy),
                        DF131(RP+eps.yyx)-DF131(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DF231(vec3 p) {
    float d=DFBox(p-vec3(0.02,0.,0.02),vec3(1.96,1.2,0.96))-0.02;
    return d;
}

vec4 Trace231(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DF231(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DF231(RP+eps.xyy)-DF231(RP-eps.xyy),
                        DF231(RP+eps.yxy)-DF231(RP-eps.yxy),
                        DF231(RP+eps.yyx)-DF231(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DF431(vec3 p) {
    float d=DFBox(p-vec3(0.02,0.,0.02),vec3(3.96,1.2,0.96))-0.02;
    return d;
}

vec4 Trace431(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DF431(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DF431(RP+eps.xyy)-DF431(RP-eps.xyy),
                        DF431(RP+eps.yxy)-DF431(RP-eps.yxy),
                        DF431(RP+eps.yyx)-DF431(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DF2Slope2(vec3 p) {
    float d=-smin(-DFBox(p-vec3(0.02,0.,0.02),vec3(1.96,1.2,1.96))-0.02,-dot(vec3(-LEGOSlope.x,LEGOSlope.yz),p-vec3(1.,1.2,0.)),0.05);
    return d;
}

vec4 Trace2Slope2(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DF2Slope2(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DF2Slope2(RP+eps.xyy)-DF2Slope2(RP-eps.xyy),
                        DF2Slope2(RP+eps.yxy)-DF2Slope2(RP-eps.yxy),
                        DF2Slope2(RP+eps.yyx)-DF2Slope2(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFSlope(vec3 p) {
    float d=-smin(-DFBox(p-vec3(0.02,0.,0.02),vec3(1.96,1.2,0.96))+0.02,-dot(LEGOSlope,p-vec3(1.,1.2,0.)),0.05);
    return d;
}

vec4 TraceSlope(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFSlope(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFSlope(RP+eps.xyy)-DFSlope(RP-eps.xyy),
                        DFSlope(RP+eps.yxy)-DFSlope(RP-eps.yxy),
                        DFSlope(RP+eps.yyx)-DFSlope(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFISlope(vec3 p) {
    float d=-smin(-DFBox(p-vec3(0.02,0.,0.02),vec3(1.96,1.2,0.96))+0.02,-dot(LEGOISlope,p-vec3(1.,0.,0.)),0.03);
    d=-smin(-d,max(DFBox(p-vec3(0.25,0.2,0.15),vec3(0.75,2.,0.7)),dot(LEGOISlope,p-vec3(1.,0.2,0.))),0.05);
    //Stud
    d=smin(d,-smin(-max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.3,-p.y+1.4,0.07),-p.y+0.85),
    DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))-0.2,0.07),0.07);
    return d;
}

vec4 TraceISlope(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFISlope(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFISlope(RP+eps.xyy)-DFISlope(RP-eps.xyy),
                        DFISlope(RP+eps.yxy)-DFISlope(RP-eps.yxy),
                        DFISlope(RP+eps.yyx)-DFISlope(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFOnlySlope(vec3 p) {
    float d=-smin(-DFBox(p-vec3(0.1,0.1,0.1),vec3(0.8,1.,0.8))+0.1,-dot(LEGOOSlope,p-vec3(1.,0.8,0.)),0.06);
    return d;
}

vec4 TraceOnlySlope(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFOnlySlope(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFOnlySlope(RP+eps.xyy)-DFOnlySlope(RP-eps.xyy),
                        DFOnlySlope(RP+eps.yxy)-DFOnlySlope(RP-eps.yxy),
                        DFOnlySlope(RP+eps.yyx)-DFOnlySlope(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFOnlySlope2(vec3 p) {
    float d=-smin(-DFBox(p-vec3(0.1,0.1,0.1),vec3(0.8,1.,0.8))+0.1,-dot(vec3(-LEGOOSlope.x,LEGOOSlope.yz),p-vec3(0.,0.8,0.)),0.06);
    return d;
}

vec4 TraceOnlySlope2(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFOnlySlope2(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFOnlySlope2(RP+eps.xyy)-DFOnlySlope2(RP-eps.xyy),
                        DFOnlySlope2(RP+eps.yxy)-DFOnlySlope2(RP-eps.yxy),
                        DFOnlySlope2(RP+eps.yyx)-DFOnlySlope2(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFHeadLight(vec3 p) {
    float d=-smin(-DFBox(p-vec3(0.02),vec3(0.96,1.16,0.96))+0.02,DFBox(p-vec3(-1.,0.2,-1.),vec3(1.2,2.,3.)),0.05);
    //Stud
    d=smin(d,-smin(-DFLine(p,vec3(0.5,0.7,0.5),vec3(-2.,0.7,0.5))+0.3,p.x,0.07),0.05);
    d=-smin(-d,min(DFLine(p,vec3(0.5,0.7,0.5),vec3(-2.,0.7,0.5))-0.2,DFBox(p-vec3(0.22,0.04,0.04),vec3(0.92,1.12,0.92))),0.07);
    return d;
}

vec4 TraceHeadLight(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFHeadLight(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFHeadLight(RP+eps.xyy)-DFHeadLight(RP-eps.xyy),
                        DFHeadLight(RP+eps.yxy)-DFHeadLight(RP-eps.yxy),
                        DFHeadLight(RP+eps.yyx)-DFHeadLight(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

vec4 TraceISlope2(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFISlope(vec3(2.-RP.x,RP.yz));
        if (t<0.002) {
            RP=vec3(2.-RP.x,RP.yz);
            return vec4(normalize(vec3(
                        DFISlope(RP-eps.xyy)-DFISlope(RP+eps.xyy),
                        DFISlope(RP+eps.yxy)-DFISlope(RP-eps.yxy),
                        DFISlope(RP+eps.yyx)-DFISlope(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFDoor(vec3 p) {
    float d=min(DFBox(p-vec3(0.48,0.32,0.02),vec3(3.46,5.66,0.16))-0.02,
            max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,7.,0.5))-0.5,p.y-6.),-p.y));
    //Ornament
    d=-smin(-d,DFBox(p-vec3(0.75,0.6,-1.),vec3(2.5,1.6,1.15)),0.1);
    d=min(d,DFBox(p-vec3(1.15,1.,0.),vec3(1.7,0.8,0.15)));
    //Window
    d=-smin(-d,DFBox(p-vec3(0.75,3.,-1.),vec3(2.5,2.5,1.1)),0.1);
        d=-smin(-d,DFBox(vec3(abs(p.x-2.),abs(p.y-4.25),p.z+1.)-vec3(0.125,0.125,0.),vec3(1.,1.,3.)),0.1);
    //Handle
    d=min(d,DFLine(p,vec3(3.5,2.6,0.),vec3(3.2,2.6,0.))-0.15);
    return d;
}

vec4 TraceDoor(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFDoor(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFDoor(RP+eps.xyy)-DFDoor(RP-eps.xyy),
                        DFDoor(RP+eps.yxy)-DFDoor(RP-eps.yxy),
                        DFDoor(RP+eps.yyx)-DFDoor(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

vec4 TraceDoorRot(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFDoor(RP.zyx);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFDoor(RP.zyx+eps.yyx)-DFDoor(RP.zyx-eps.yyx),
                        DFDoor(RP.zyx+eps.yxy)-DFDoor(RP.zyx-eps.yxy),
                        DFDoor(RP.zyx+eps.xyy)-DFDoor(RP.zyx-eps.xyy))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

float DFWindow(vec3 p) {
    return max(max(DFBox(p,vec3(4.,3.6,1.)),-DFBox(p-vec3(0.3,0.4,-1.),vec3(3.4,2.8,3.))),
            -DFBox(p-vec3(0.15,0.35,-1.),vec3(3.7,2.9,1.4)));
}

vec4 TraceWindow(vec3 pos, vec3 dir, float FAR) {
    float t; float dist=0.; vec3 RP;
    for (int i=0; i<356; i++) {
        if (dist>FAR) break;
        RP=pos+dir*dist;
        t=DFWindow(RP);
        if (t<0.002) {
            return vec4(normalize(vec3(
                        DFWindow(RP+eps.xyy)-DFWindow(RP-eps.xyy),
                        DFWindow(RP+eps.yxy)-DFWindow(RP-eps.yxy),
                        DFWindow(RP+eps.yyx)-DFWindow(RP-eps.yyx))),dist);
        }
        dist=dist+t;
    }
    return vec4(0.,0.,0.,10000.);
}

//Lego logo (see Image)
const int samples = 2;

const vec3 positions[225] =
    vec3[225](vec3(0.9408613367791228, 0.43095909706765456, 0),
              vec3(0.9264762435267317, 0.44352663509707624, 0),
              vec3(0.8947861254762883, 0.4638692865687953, 0),
              vec3(0.8777536433400679, 0.4715814511436973, 0),
              vec3(0.841995189500208, 0.48193008580309815, 0),
              vec3(0.8048872251098951, 0.48530129825064333, 0),
              vec3(0.7861678547856077, 0.4842916850607259, 0),
              vec3(0.7490796945333518, 0.47672464768502254, 0),
              vec3(0.7309834472672143, 0.47010427463184123, 0),
              vec3(0.6967507470536414, 0.45128546857518964, 0),
              vec3(0.6815966127536668, 0.4397110894047105, 0),
              vec3(0.6551836294986841, 0.41262743744267205, 0),
              vec3(0.634461035245403, 0.3809322504759403, 0),
              vec3(0.626419887197555, 0.3635934525495947, 0),
              vec3(0.6174678863278233, 0.3359891364381042, 0),
              vec3(0.47899216991926896, -0.24549629059456585, 0),
              vec3(0.4741737266143069, -0.2751084016236367, 0),
              vec3(0.473508033500468, -0.29441126217125624, 0),
              vec3(0.4778079185647557, -0.33209980412273227, 0),
              vec3(0.4891422806195873, -0.36776620212046324, 0),
              vec3(0.5069424579864692, -0.40045137004997605, 0),
              vec3(0.5306397889869092, -0.42919622179679773, 0),
              vec3(0.5445221803251843, -0.44179131469092675, 0),
              vec3(0.575999001128787, -0.4628274056990749, 0),
              vec3(0.5934512651744912, -0.471028632284476, 0),
              vec3(0.6313136680076146, -0.48217771366078943, 0),
              vec3(0.6700652677983625, -0.48548096726553785, 0),
              vec3(0.7077538097498388, -0.48118108220125, 0),
              vec3(0.7434202077475696, -0.46984672014641854, 0),
              vec3(0.7761053756770824, -0.45204654277953654, 0),
              vec3(0.8048502274239044, -0.4283492117790967, 0),
              vec3(0.8286956768735618, -0.3993233888235917, 0),
              vec3(0.8466826379115826, -0.36553773559151465, 0),
              vec3(0.8557512754292231, -0.33741694258942456, 0),
              vec3(0.996423388384482, 0.25472647096242323, 0),
              vec3(1, 0.29294405649279703, 0),
              vec3(0.9960265197448488, 0.3307089760104401, 0),
              vec3(0.9846915584576656, 0.3670555420215273, 0),
              vec3(0.7570787710671805, -0.3279246723576778, 0),
              vec3(0.7481456607517563, -0.34489128805259295, 0),
              vec3(0.7363053501222789, -0.3595089915158228, 0),
              vec3(0.7220133343540593, -0.37147883456812697, 0),
              vec3(0.705725108622407, -0.38050186903026445, 0),
              vec3(0.6878961681026325, -0.3862791467229943, 0),
              vec3(0.6689820079700466, -0.3885117194670758, 0),
              vec3(0.649438123399958, -0.38690063908326805, 0),
              vec3(0.6304205367457778, -0.3813442914822551, 0),
              vec3(0.6058327710290847, -0.3668259574428918, 0),
              vec3(0.5925016292489125, -0.3537028573471296, 0),
              vec3(0.5819678219692868, -0.33835579970027974, 0),
              vec3(0.5720660623804614, -0.31216168851770726, 0),
              vec3(0.5701398889260951, -0.28352583320630764, 0),
              vec3(0.7155770729851352, 0.3272211318267263, 0),
              vec3(0.7245101833005594, 0.3441877475216413, 0),
              vec3(0.7363504939300369, 0.35880545098487127, 0),
              vec3(0.7506425096982563, 0.3707752940371754, 0),
              vec3(0.7669307354299086, 0.37979832849931283, 0),
              vec3(0.7847596759496831, 0.38557560619204273, 0),
              vec3(0.803673836082269, 0.38780817893612424, 0),
              vec3(0.8330139122006925, 0.38387499214489884, 0),
              vec3(0.8511765563761193, 0.3765710374186516, 0),
              vec3(0.8670548875320945, 0.36613614277101764, 0),
              vec3(0.8803725907900135, 0.35302297421472734, 0),
              vec3(0.8908533512712726, 0.3376841977625116, 0),
              vec3(0.8982208540972669, 0.3205724794271009, 0),
              vec3(0.9021987843893928, 0.3021404852212259, 0),
              vec3(0.49404521200236484, 0.32051485979824523, 0),
              vec3(0.48453276188440575, 0.3577040643779089, 0),
              vec3(0.4771903875232675, 0.3751107130887582, 0),
              vec3(0.4578154766529401, 0.40706596689622404, 0),
              vec3(0.432829864860236, 0.4345676472763559, 0),
              vec3(0.4030049704751837, 0.4568443358991251, 0),
              vec3(0.3691122118278114, 0.47312461443450343, 0),
              vec3(0.3508814516338892, 0.4787750316912871, 0),
              vec3(0.3319230072481476, 0.4826370645524623, 0),
              vec3(0.29392752080375106, 0.4846864612988684, 0),
              vec3(0.2612007307844826, 0.48048830820567073, 0),
              vec3(0.2302822471806536, 0.47103805054705644, 0),
              vec3(0.20168320536497242, 0.4567572335473808, 0),
              vec3(0.17591474071014757, 0.43806740243099923, 0),
              vec3(0.15348798858888713, 0.41539010242226715, 0),
              vec3(0.13491408437389962, 0.3891468787455399, 0),
              vec3(0.12070416343789314, 0.35975927662517293, 0),
              vec3(0.1132180666353646, 0.33590866248028545, 0),
              vec3(-0.025338065404089227, -0.24549634892148534, 0),
              vec3(-0.030138663741522187, -0.27510780484715514, 0),
              vec3(-0.03077473905960626, -0.29440849931717467, 0),
              vec3(-0.026382729388821247, -0.33208369115772834, 0),
              vec3(-0.021501053563444672, -0.35021629512770946, 0),
              vec3(-0.0067323828414551645, -0.3844667856656981, 0),
              vec3(0.01422201609720819, -0.4152246749992118, 0),
              vec3(0.026835852193426657, -0.4289915274635997, 0),
              vec3(0.05597077473090595, -0.45269631448625475, 0),
              vec3(0.07234545200867437, -0.46239235564396874, 0),
              vec3(0.10834321567353711, -0.47686699975078806, 0),
              vec3(0.12770761787487328, -0.4814513703741509, 0),
              vec3(0.16645647691437215, -0.4847091805549651, 0),
              vec3(0.20413166875492594, -0.4803171708841801, 0),
              vec3(0.23976561979432254, -0.46886097801576615, 0),
              vec3(0.27239075643035005, -0.45092623860369346, 0),
              vec3(0.30103950506079724, -0.4270985893019323, 0),
              vec3(0.31357036712323705, -0.41315793489678415, 0),
              vec3(0.3344403332411665, -0.38158898948668446, 0),
              vec3(0.3489149773479858, -0.3455912258218219, 0),
              vec3(0.42894164996584827, -0.011973834455500498, 0),
              vec3(0.42972497189919556, 0.005285807701407088, 0),
              vec3(0.4243979338193449, 0.022557766661810377, 0),
              vec3(0.410058067874302, 0.03884635586226634, 0),
              vec3(0.3951169066462894, 0.04640446369357787, 0),
              vec3(0.381196346171893, 0.04853615910943173, 0),
              vec3(0.29306584924039014, 0.048288253738397215, 0),
              vec3(0.274830481833795, 0.04272753468825939, 0),
              vec3(0.2605446253882744, 0.030976607914030365, 0),
              vec3(0.25170207774583986, 0.014529271257721282, 0),
              vec3(0.24954095118037345, 0.000010362544709030003, 0),
              vec3(0.25170207774583986, -0.014508546168303221, 0),
              vec3(0.2605446253882744, -0.030955882824612358, 0),
              vec3(0.274830481833795, -0.042706809598841385, 0),
              vec3(0.283547839032084, -0.04635430745454747, 0),
              vec3(0.31863004442757803, -0.048515434020013674, 0),
              vec3(0.25202421179653345, -0.32792467235767736, 0),
              vec3(0.2430911014811088, -0.3448912880525925, 0),
              vec3(0.22438277766140802, -0.36584357985454286, 0),
              vec3(0.20067054935175999, -0.380501869030264, 0),
              vec3(0.18284160883198575, -0.38627914672299396, 0),
              vec3(0.15420575352058608, -0.3882053201773602, 0),
              vec3(0.13463670610345768, -0.3845783042799128, 0),
              vec3(0.11660773985991546, -0.37726960481225597, 0),
              vec3(0.09378165831698615, -0.3605708705373532, 0),
              vec3(0.07691326269863996, -0.3383557997002793, 0),
              vec3(0.06947573809880092, -0.3212402796776524, 0),
              vec3(0.0647789303657329, -0.29324752838512047, 0),
              vec3(0.06639001074954098, -0.2737036438150323, 0),
              vec3(0.20590410104503487, 0.3127127704626628, 0),
              vec3(0.21430798481922464, 0.33602689053214585, 0),
              vec3(0.2307763633722193, 0.3590033597484454, 0),
              vec3(0.24497227602406446, 0.37110352110207073, 0),
              vec3(0.2612004704622315, 0.3802611176093988, 0),
              vec3(0.288338328393416, 0.3877891213826372, 0),
              vec3(0.31743891786417455, 0.3869192865064165, 0),
              vec3(0.34946754816430725, 0.37512846657511933, 0),
              vec3(0.3628577585368089, 0.365782121700417, 0),
              vec3(0.37946114119164776, 0.34811165849076364, 0),
              vec3(0.3938616180155652, 0.3191469867055984, 0),
              vec3(0.3981023608114145, 0.2852790298923329, 0),
              vec3(0.40366307986155214, 0.26704366248573774, 0),
              vec3(0.40885812964828094, 0.2593136830277175, 0),
              vec3(0.42314398609380155, 0.24756275625348856, 0),
              vec3(0.4463802520051028, 0.24175413183231625, 0),
              vec3(0.470219090251927, 0.2480492150414748, 0),
              vec3(0.4849219338265358, 0.2599629758397277, 0),
              vec3(0.4902778529410525, 0.2677196751665549, 0),
              vec3(-0.4238290609360067, -0.3879545880996168, 0),
              vec3(-0.42399143141451245, -0.3857869964555996, 0),
              vec3(-0.3435303791941341, -0.04876145696646751, 0),
              vec3(-0.1881453922760149, -0.04826752864897948, 0),
              vec3(-0.17862738206770856, -0.04635430745454769, 0),
              vec3(-0.16218004541139952, -0.037511759812112966, 0),
              vec3(-0.15042911863717046, -0.023225903366592502, 0),
              vec3(-0.14678162078146462, -0.014508546168303545, 0),
              vec3(-0.1448683995870328, 0.005011261049414758, 0),
              vec3(-0.15042911863717046, 0.02324662845600997, 0),
              vec3(-0.16218004541139952, 0.037532484901530376, 0),
              vec3(-0.17862738206770856, 0.04637503254396521, 0),
              vec3(-0.19314629078072088, 0.04853615910943141, 0),
              vec3(-0.3201711275962441, 0.04853615910943141, 0),
              vec3(-0.2395580256922737, 0.3877292902425807, 0),
              vec3(-0.013614947063175453, 0.3879753131890342, 0),
              vec3(0.001553809488533675, 0.3901364397545005, 0),
              vec3(0.010271166686822708, 0.3937839376102065, 0),
              vec3(0.024557023132343314, 0.4055348643844355, 0),
              vec3(0.03339957077477784, 0.42198220104074474, 0),
              vec3(0.035560697340244474, 0.436501109753757, 0),
              vec3(0.03339957077477784, 0.45102001846676926, 0),
              vec3(0.024557023132343314, 0.46746735512307847, 0),
              vec3(0.010271166686822708, 0.4792182818973075, 0),
              vec3(0.001553809488533675, 0.4828657797530134, 0),
              vec3(-0.012965099224478305, 0.4850269063184797, 0),
              vec3(-0.28168609287903024, 0.48485067306612756, 0),
              vec3(-0.3043423804615203, 0.47698065006041873, 0),
              vec3(-0.32039964632717177, 0.4593075787165124, 0),
              vec3(-0.5323543124694348, -0.42474224806260563, 0),
              vec3(-0.5337338883980041, -0.43998512769155146, 0),
              vec3(-0.5289140955923151, -0.45796681352017904, 0),
              vec3(-0.5177230286574426, -0.4726176319384635, 0),
              vec3(-0.5012621748910309, -0.48217218549675583, 0),
              vec3(-0.48805568326353965, -0.4848137981736519, 0),
              vec3(-0.18106368398796246, -0.4846778019002089, 0),
              vec3(-0.16282831658136732, -0.47911708285007126, 0),
              vec3(-0.1485424601358467, -0.46736615607584225, 0),
              vec3(-0.13969991249341207, -0.4509188194195329, 0),
              vec3(-0.13780384309711902, -0.4313999159620832, 0),
              vec3(-0.14369958214938683, -0.41318230940945977, 0),
              vec3(-0.1559911147398615, -0.3989255304682293, 0),
              vec3(-0.17289041011825634, -0.3901082881133118, 0),
              vec3(-0.8900128517657221, -0.3879545880996168, 0),
              vec3(-0.6958469474912434, 0.43024439706208367, 0),
              vec3(-0.6970680454957241, 0.44937401560737006, 0),
              vec3(-0.7052111612782105, 0.46615542921161646, 0),
              vec3(-0.711534261055692, 0.4730785079255896, 0),
              vec3(-0.7279951148221036, 0.4828153067067156, 0),
              vec3(-0.7474699697899465, 0.48548096726553785, 0),
              vec3(-0.756841335071212, 0.48394209929187737, 0),
              vec3(-0.7735159477880796, 0.4757893172039107, 0),
              vec3(-0.7858110168317786, 0.461806574093651, 0),
              vec3(-0.789707952521583, 0.45298025484212406, 0),
              vec3(-0.9986204823983503, -0.42409851472697496, 0),
              vec3(-1, -0.4393413360290013, 0),
              vec3(-0.9951802071943109, -0.4573230218576287, 0),
              vec3(-0.9839891402594383, -0.4719738402759131, 0),
              vec3(-0.9675282864930268, -0.48152839383420565, 0),
              vec3(-0.9543217948655356, -0.48417000651110154, 0),
              vec3(-0.6473297955899583, -0.48403401023765885, 0),
              vec3(-0.629094428183363, -0.4784732911875213, 0),
              vec3(-0.6148085717378426, -0.4667223644132922, 0),
              vec3(-0.6059660240954079, -0.4502750277569829, 0),
              vec3(-0.6040688937631473, -0.43076335438168084, 0),
              vec3(-0.6099273821747845, -0.41268783466083125, 0),
              vec3(-0.6220949031388547, -0.3986636757539205, 0),
              vec3(-0.6387381593037988, -0.3900488756991408, 0),
              vec3(-0.6530549597150334, -0.3879545880996168, 0),
              vec3(-0.1875131137334065, -0.3879545880996168, 0),
              vec3(0.4962741058527447, 0.2909237200595889, 0),
              vec3(0.9001729001451884, 0.2680691160390561, 0),
              vec3(0.9714728267726251, 0.392803750658161, 0));
const ivec3 triangles[219] = ivec3[219](
    ivec3(0, 61, 1), ivec3(0, 62, 61), ivec3(0, 224, 62), ivec3(1, 60, 2),
    ivec3(1, 61, 60), ivec3(2, 60, 3), ivec3(3, 59, 4), ivec3(3, 60, 59),
    ivec3(4, 58, 5), ivec3(4, 59, 58), ivec3(5, 58, 6), ivec3(6, 57, 7),
    ivec3(6, 58, 57), ivec3(7, 56, 8), ivec3(7, 57, 56), ivec3(8, 56, 9),
    ivec3(9, 55, 10), ivec3(9, 56, 55), ivec3(10, 54, 11), ivec3(10, 55, 54),
    ivec3(11, 53, 12), ivec3(11, 54, 53), ivec3(12, 52, 13), ivec3(12, 53, 52),
    ivec3(13, 52, 14), ivec3(14, 52, 15), ivec3(15, 51, 16), ivec3(15, 52, 51),
    ivec3(16, 51, 17), ivec3(17, 50, 18), ivec3(17, 51, 50), ivec3(18, 50, 19),
    ivec3(19, 49, 20), ivec3(19, 50, 49), ivec3(20, 48, 21), ivec3(20, 49, 48),
    ivec3(21, 47, 22), ivec3(21, 48, 47), ivec3(22, 47, 23), ivec3(23, 46, 24),
    ivec3(23, 47, 46), ivec3(24, 46, 25), ivec3(25, 45, 26), ivec3(25, 46, 45),
    ivec3(26, 44, 27), ivec3(26, 45, 44), ivec3(27, 43, 28), ivec3(27, 44, 43),
    ivec3(28, 42, 29), ivec3(28, 43, 42), ivec3(29, 41, 30), ivec3(29, 42, 41),
    ivec3(30, 40, 31), ivec3(30, 41, 40), ivec3(31, 39, 32), ivec3(31, 40, 39),
    ivec3(32, 38, 33), ivec3(32, 39, 38), ivec3(33, 38, 223),
    ivec3(33, 223, 34), ivec3(34, 223, 35), ivec3(35, 65, 36),
    ivec3(35, 223, 65), ivec3(36, 64, 37), ivec3(36, 65, 64),
    ivec3(37, 63, 224), ivec3(37, 64, 63), ivec3(62, 224, 63),
    ivec3(66, 143, 67), ivec3(66, 144, 143), ivec3(66, 222, 144),
    ivec3(67, 143, 68), ivec3(68, 142, 69), ivec3(68, 143, 142),
    ivec3(69, 142, 70), ivec3(70, 141, 71), ivec3(70, 142, 141),
    ivec3(71, 140, 72), ivec3(71, 141, 140), ivec3(72, 139, 73),
    ivec3(72, 140, 139), ivec3(73, 139, 74), ivec3(74, 139, 75),
    ivec3(75, 138, 76), ivec3(75, 139, 138), ivec3(76, 137, 77),
    ivec3(76, 138, 137), ivec3(77, 137, 78), ivec3(78, 136, 79),
    ivec3(78, 137, 136), ivec3(79, 135, 80), ivec3(79, 136, 135),
    ivec3(80, 134, 81), ivec3(80, 135, 134), ivec3(81, 134, 82),
    ivec3(82, 133, 83), ivec3(82, 134, 133), ivec3(83, 133, 84),
    ivec3(84, 132, 85), ivec3(84, 133, 132), ivec3(85, 131, 86),
    ivec3(85, 132, 131), ivec3(86, 131, 87), ivec3(87, 130, 88),
    ivec3(87, 131, 130), ivec3(88, 130, 89), ivec3(89, 129, 90),
    ivec3(89, 130, 129), ivec3(90, 128, 91), ivec3(90, 129, 128),
    ivec3(91, 128, 92), ivec3(92, 127, 93), ivec3(92, 128, 127),
    ivec3(93, 126, 94), ivec3(93, 127, 126), ivec3(94, 126, 95),
    ivec3(95, 125, 96), ivec3(95, 126, 125), ivec3(96, 124, 97),
    ivec3(96, 125, 124), ivec3(97, 123, 98), ivec3(97, 124, 123),
    ivec3(98, 123, 99), ivec3(99, 122, 100), ivec3(99, 123, 122),
    ivec3(100, 121, 101), ivec3(100, 122, 121), ivec3(101, 121, 102),
    ivec3(102, 120, 103), ivec3(102, 121, 120), ivec3(103, 119, 104),
    ivec3(103, 120, 119), ivec3(104, 109, 105), ivec3(104, 119, 109),
    ivec3(105, 107, 106), ivec3(105, 109, 107), ivec3(107, 109, 108),
    ivec3(109, 119, 110), ivec3(110, 113, 111), ivec3(110, 114, 113),
    ivec3(110, 118, 114), ivec3(110, 119, 118), ivec3(111, 113, 112),
    ivec3(114, 118, 115), ivec3(115, 117, 116), ivec3(115, 118, 117),
    ivec3(144, 147, 145), ivec3(144, 148, 147), ivec3(144, 149, 148),
    ivec3(144, 222, 149), ivec3(145, 147, 146), ivec3(149, 222, 150),
    ivec3(150, 222, 151), ivec3(152, 181, 153), ivec3(152, 186, 181),
    ivec3(152, 187, 186), ivec3(152, 221, 187), ivec3(153, 181, 154),
    ivec3(154, 165, 155), ivec3(154, 180, 165), ivec3(154, 181, 180),
    ivec3(155, 159, 156), ivec3(155, 160, 159), ivec3(155, 164, 160),
    ivec3(155, 165, 164), ivec3(156, 158, 157), ivec3(156, 159, 158),
    ivec3(160, 163, 161), ivec3(160, 164, 163), ivec3(161, 163, 162),
    ivec3(165, 180, 166), ivec3(166, 177, 167), ivec3(166, 178, 177),
    ivec3(166, 180, 178), ivec3(167, 172, 168), ivec3(167, 177, 172),
    ivec3(168, 171, 169), ivec3(168, 172, 171), ivec3(169, 171, 170),
    ivec3(172, 177, 173), ivec3(173, 175, 174), ivec3(173, 176, 175),
    ivec3(173, 177, 176), ivec3(178, 180, 179), ivec3(181, 185, 182),
    ivec3(181, 186, 185), ivec3(182, 184, 183), ivec3(182, 185, 184),
    ivec3(187, 193, 188), ivec3(187, 194, 193), ivec3(187, 221, 194),
    ivec3(188, 190, 189), ivec3(188, 193, 190), ivec3(190, 192, 191),
    ivec3(190, 193, 192), ivec3(195, 205, 196), ivec3(195, 206, 205),
    ivec3(195, 211, 206), ivec3(195, 212, 211), ivec3(195, 220, 212),
    ivec3(196, 205, 197), ivec3(197, 205, 198), ivec3(198, 200, 199),
    ivec3(198, 205, 200), ivec3(200, 205, 201), ivec3(201, 205, 202),
    ivec3(202, 205, 203), ivec3(203, 205, 204), ivec3(206, 210, 207),
    ivec3(206, 211, 210), ivec3(207, 209, 208), ivec3(207, 210, 209),
    ivec3(212, 218, 213), ivec3(212, 219, 218), ivec3(212, 220, 219),
    ivec3(213, 218, 214), ivec3(214, 218, 215), ivec3(215, 218, 216),
    ivec3(216, 218, 217));
const int len = 219;

bool sameSide(vec3 p1, vec3 p2, vec3 a, vec3 b) {
  vec3 cp1 = cross(b - a, p1 - a);
  vec3 cp2 = cross(b - a, p2 - a);

  return dot(cp1, cp2) >= 0.0;
}

bool pointInTriangle(vec3 p, vec3 a, vec3 b, vec3 c) {
  return sameSide(p, a, b, c) && sameSide(p, b, a, c) && sameSide(p, c, a, b);
}

bool inPath(vec2 p) {
  for (int i = 0; i < len; i++) {
    ivec3 triangle = triangles[i];
    vec3 a = positions[triangle[0]];
    vec3 b = positions[triangle[1]];
    vec3 c = positions[triangle[2]];

    if (pointInTriangle(vec3(p, 0.0), a, b, c)) {
      return true;
    }
  }

  return false;
}