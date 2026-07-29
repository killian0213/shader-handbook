// Common (common) — LEGO Creator 5891 by Mathis
// https://www.shadertoy.com/view/DsSSWh

//Settings
const float FOV = radians((100.)/2.);

//Constants
const int BuildFrames = 33;
const float SAFram = 0.24145316170843;
const float SASida = 0.18443362850791;
const float PI = 3.14159265;
const float IPI = 1./PI;
const float ToRadians = PI/180.;
const float I16 = 1./16.;
const float I26 = 1./26.;
const float I32 = 1./32.;
const float I64 = 1./64.;
const float I128 = 1./128.;
const float I255 = 1./255.;
const float I256 = 1./256.;
const float I512 = 1./512.;
const float I1024 = 1./1024.;
const float Sqrt2 = sqrt(2.);
const float Sqrt05 = sqrt(0.5);
const float ISqrt3 = 1./sqrt(3.);
const vec2 eps = vec2(0.001,0.);
const float CFOV = tan(FOV);
const vec3 SunLight = vec3(1.,0.15,0.03)*4.;
const vec3 SkyLight = vec3(0.2,0.45,0.99);
const vec3 LEGOObliqueSlope = normalize(vec3(0.,-3.,-3.4));
const vec3 LEGOSlope331 = normalize(vec3(0.9,2.,0.));
const vec3 LEGOSlope = normalize(vec3(0.9,1.,0.));
const vec3 LEGOISlope = normalize(vec3(0.9,-1.,0.));
const vec3 LEGOOSlope = normalize(vec3(3.5/6.,1.,0.));
//Defines
#define RES iChannelResolution[0].xy
#define IRES 1./iChannelResolution[0].xy
#define ASPECT vec2(iChannelResolution[0].x/iChannelResolution[0].y,1.)

//Structs
struct HIT { float D; vec3 P; vec3 N; vec3 C; int I; float M; };
struct BRICK { vec3 P; vec3 Q; int Color; int I; };

float DFBox(vec3 p, vec3 b) {
    vec3 d = abs(p-b*0.5)-b*0.5;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float DFBox(vec2 p, vec2 b) {
    vec2 d = abs(p-b*0.5)-b*0.5;
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}

float DFBoxC2(vec2 p, vec2 b) {
    vec2 d = abs(p)-b;
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}

float DFDisk(vec3 p) {
    float d = length(p.xz-0.5)-0.35;
    vec2 w = vec2(d,abs(p.y));
    return min(max(w.x,w.y),0.)+length(max(w,0.));
}

float DFLine(vec3 p, vec3 a, vec3 b) {
    vec3 ba = b-a;
    float k = dot(p-a,ba)/dot(ba,ba);
    return length((a+clamp(k,0.,1.)*(b-a))-p);
}

vec2 Rotate(vec2 p, float ang) {
    float c = cos(ang), s = sin(ang);
    return vec2(p.x*c-p.y*s,p.x*s+p.y*c);
}

vec2 Repeat(vec2 p, float n) {
    float ang = 2.*3.14159/n;
    float sector = floor(atan(p.x,p.y)/ang+0.5);
    p = Rotate(p,sector*ang);
    return p;
}

float smin(float a, float b, float k) {
    //https://iquilezles.org/articles/smin
    float h = max(k-abs(a-b),0.)/k;
    return min(a,b)-h*h*h*k*(1.0/6.0);
}

float SMIN(float a, float b, float k) {
    float h = clamp(0.5+0.5*(b-a)/k,0.,1.);
    return mix(b,a,h)-k*h*(1.-h);
}

vec2 PToUV(vec3 p) {
    return vec2(floor(p.x)+floor(p.y)*2.,floor(p.z))+0.5;
}

vec3 ARand23(vec2 uv) {
    //Analytic random
    return fract(sin(uv.x*uv.y)*vec3(403.125,486.125,513.432)+cos(dot(uv,vec2(13.18273,51.2134)))*vec3(173.137,261.23,203.127));
}

float ARand21(vec2 uv) {
    //Analytic random
    return fract(sin(uv.x*uv.y)*403.125+cos(dot(uv,vec2(13.18273,51.2134)))*173.137);
}

mat3 TBN(vec3 N) {
    vec3 Nb,Nt;
    if (abs(N.y)>0.999) {
        Nb = vec3(1.,0.,0.);
        Nt = vec3(0.,0.,1.);
    } else {
    	Nb = normalize(cross(N,vec3(0.,1.,0.)));
    	Nt = normalize(cross(Nb,N));
    }
    return mat3(Nb.x,Nt.x,N.x,Nb.y,Nt.y,N.y,Nb.z,Nt.z,N.z);
}

vec3 TBN(vec3 N, out vec3 O) {
    O = ((abs(N.y)>0.999)?vec3(1.,0.,0.):normalize(cross(N,vec3(0.,1.,0.))));
    return normalize(cross(O,N));
}

float boxfar(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t2 = max(tMin,tMax);
    return min(min(t2.x,t2.y),t2.z);
}

float boxfar(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t2 = max(tMin,tMax);
    return min(t2.x,t2.y);
}

vec2 box(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t1 = min(tMin,tMax);
    vec3 t2 = max(tMin,tMax);
    return vec2(max(max(t1.x,t1.y),t1.z),min(min(t2.x,t2.y),t2.z));
}

vec3 boxfarNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t2 = max(tMin,tMax);
    vec3 signdir = max(vec3(0.),sign(dir))*2.-1.;
    if (t2.x<min(t2.y,t2.z)) return vec3(signdir.x,0.,0.);
    else if (t2.y<t2.z) return vec3(0.,signdir.y,0.);
    else return vec3(0.,0.,signdir.z);
}

float boxfarNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax, out vec3 N) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t2 = max(tMin,tMax);
    vec3 signdir = max(vec3(0.),sign(dir))*2.-1.;
    if (t2.x<min(t2.y,t2.z)) N = vec3(signdir.x,0.,0.);
    else if (t2.y<t2.z) N = vec3(0.,signdir.y,0.);
    else N = vec3(0.,0.,signdir.z);
    return min(min(t2.x,t2.y),t2.z);
}

vec2 boxNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax, out vec3 N) {
    vec3 tMin=(bmin-origin)*dir;
    vec3 tMax=(bmax-origin)*dir;
    vec3 t1=min(tMin,tMax);
    vec3 t2=max(tMin,tMax);
    vec3 signdir = -(max(vec3(0.),sign(dir))*2.-1.);
    if (t1.x>max(t1.y,t1.z)) N = vec3(signdir.x,0.,0.);
    else if (t1.y>t1.z) N = vec3(0.,signdir.y,0.);
    else N = vec3(0.,0.,signdir.z);
    return vec2(max(max(t1.x,t1.y),t1.z),min(min(t2.x,t2.y),t2.z));
}

vec3 RandSampleCos(vec2 v) {
    float theta = sqrt(v.x);
    float phi = 2.*3.14159*v.y;
    float x = theta*cos(phi);
    float z = theta*sin(phi);
    return vec3(x,z,sqrt(max(0.,1.-v.x)));
}

float Schlick(float R0, float COS) {
    //Schlick approximation
    return R0+(1.-R0)*pow(1.-COS,5.);
}

vec3 SchlickFresnel(vec3 r0, float angle) {
    //Schlick Fresnel approximation
    return r0+(1.-r0)*pow(1.-angle,5.);
}

float SmithGGXMasking(vec3 wi, vec3 wo, float a2) {
    //Smith masking function
    float dotNL=wi.z;
    float dotNV=wo.z;
    float denomC=sqrt(a2+(1.-a2)*dotNV*dotNV)+dotNV;
    return 2.*dotNV/denomC;
}

float SmithGGXMaskingShadowing(vec3 wi, vec3 wo, float alpha) {
    //Smith masking shadowing function
    float dotNL=wi.z;
    float dotNV=wo.z;
    float denomA=dotNV*sqrt(alpha+(1.-alpha)*dotNL*dotNL);
    float denomB=dotNL*sqrt(alpha+(1.-alpha)*dotNV*dotNV);
    return 2.*dotNL*dotNV/(denomA+denomB);
}

vec3 GgxVndf(vec3 wo, float roughness, float u1, float u2) {
    //Returns the mini normal
    vec3 v=normalize(vec3(wo.x*roughness,wo.y*roughness,wo.z));
    vec3 t1=(v.z<0.999)?normalize(cross(v,vec3(0.,0.,1.))):vec3(1.,0.,0.);
    vec3 t2=cross(t1, v);
    float a=1./(1.+v.z);
    float r=sqrt(u1);
    float phi=(u2<a)?(u2/a)*PI:PI+(u2-a)/(1.-a)*PI;
    float p1=r*cos(phi);
    float p2=r*sin(phi)*((u2<a)?1.:v.z);
    vec3 n=p1*t1+p2*t2+sqrt(max(0.,1.-p1*p1-p2*p2))*v;
    return normalize(vec3(roughness*n.x,roughness*n.y,max(0.,n.z)));
}

void ImportanceSampleGGX(vec2 uRand, vec3 wo, float Roughness, vec3 SpecularColor,
                         out vec3 wi, out vec3 reflectance) {
    //Importance sampling
    float a2=Roughness*Roughness;
    vec3 wm=GgxVndf(wo,Roughness,uRand.x,uRand.y);
    wi=reflect(-wo,wm);
    if (wi.z>0.) {
        vec3 F=SchlickFresnel(SpecularColor,dot(wi, wm));
        float G1=SmithGGXMasking(wi,wo,a2);
        float G2=SmithGGXMaskingShadowing(wi,wo,a2);
        reflectance=F*(G2/G1);
    } else {
        reflectance=vec3(0.);
    }
}

vec3 SampleSky(vec3 d, vec3 sd) { 
    vec3 L = vec3(0.);
    L = SkyLight*(1.-0.5*d.y)+SunLight*pow(dot(d,sd)*0.4+0.4,2.);
    if (d.y>0.) {
        float dist = -1000./d.y; //1000 brick height
        vec3 hitp = d*dist;
        vec2 gridp = floor(hitp.xz*0.001); //500 brick size
        vec4 glR4 = vec4(ARand21(gridp),ARand21(gridp+vec2(1.,0.)),ARand21(gridp+vec2(0.,1.)),ARand21(gridp+1.));
        vec2 glfrac = fract(hitp.xz*0.001);
        float glrv = mix(mix(glR4.x,glR4.y,glfrac.x),mix(glR4.z,glR4.w,glfrac.x),glfrac.y);
        L += float(glrv<0.4)*3.;
    }
    L = mix(SkyLight*0.8+0.2,L,pow(abs(d.y),0.5));
    //Return
    return L;
}

//MODELS
float DFStud(vec3 p) {
    float d = -smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.3,-p.y+0.2,0.075);
    d = max(-p.y,smin(d,DFDisk(p),0.05));
    return d;
}

float DFBrick(vec3 p, vec3 BSize) {
    float d = DFBox(p-vec3(0.04),BSize-vec3(0.08,0.48,0.08))-0.04;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),BSize-vec3(0.4,-0.4,0.4)));
    if (min(BSize.x,BSize.z)>1.5) {
        d = min(d,max(max(max(DFLine(vec3(fract(clamp(p.x,0.5,BSize.x-0.5)-0.5),p.yz),vec3(0.5,-1.,1.),vec3(0.5,1.,1.))-0.407,
        -DFLine(vec3(fract(clamp(p.x,0.5,BSize.x-0.5)-0.5),p.yz),vec3(0.5,-1.,1.),vec3(0.5,1.,1.))+0.3),p.y-(BSize.y-0.45)),-p.y));
    } else {
        float tmpLine = DFLine(vec3(fract(clamp(p.x,0.5,BSize.x-0.5)-0.5),p.yz),vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5));
        d = min(d,max(max(max(tmpLine-0.2,-tmpLine+0.1),p.y-(BSize.y-0.45)),-p.y));
    }
    vec3 StudPos = vec3(clamp(floor(p.x),0.,BSize.x-1.),BSize.y-0.4,clamp(floor(p.z),0.,BSize.z-1.));
    d = max(d,-max(DFLine(p-StudPos,vec3(0.5,-1.,0.5),vec3(0.5,-0.05,0.5))-0.15,p.y-1.19)); //Hole under stud
    d = min(d,DFStud(p-StudPos)); //Studs
    return d;
}

float DFBrick_NoStud(vec3 p, vec3 BSize) {
    float d = DFBox(p-vec3(0.04),BSize-vec3(0.08,0.48,0.08))-0.04;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),BSize-vec3(0.4,-0.59,0.4)));
    if (min(BSize.x,BSize.z)>1.5) {
        d = min(d,max(max(max(DFLine(vec3(fract(clamp(p.x,0.5,3.5)-0.5),p.yz),vec3(0.5,-1.,1.),vec3(0.5,1.,1.))-0.407,
        -DFLine(vec3(fract(clamp(p.x,0.5,BSize.x-0.5)-0.5),p.yz),vec3(0.5,-1.,1.),vec3(0.5,1.,1.))+0.3),p.y-(BSize.y-0.45)),-p.y));
    }
    return d;
}

float DFGrate(vec3 p) {
    float d = DFBox(p-vec3(0.02),vec3(1.96,0.36,0.96))-0.02;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),vec3(1.6,1.25,0.6)));
    d = max(d,-DFBox(vec3(p.x+2.,p.y-0.2,fract(p.z*2.5)*0.4-0.2),vec3(8.,1.,0.2)));
    return d;
}

float DFCorner(vec3 p, float Yi) {
    float Y = Yi*0.4;
    float d = min(DFBox(p-vec3(0.02),vec3(1.96,Y-0.04,0.96))-0.02,DFBox(p-vec3(0.02),vec3(0.96,Y-0.04,1.96))-0.02);
    //Interior
    d = max(d,-min(DFBox(p-vec3(0.2,-1.,0.2),vec3(1.6,0.8+Y,0.6)),DFBox(p-vec3(0.2,-1.,0.2),vec3(0.6,0.8+Y,1.6))));
    float tmpLine = min(DFLine(vec3(fract(clamp(p.x,0.5,2.-0.5)-0.5),p.yz),vec3(0.5,-1.,0.5),vec3(0.5,0.8+Y,0.5)),
    DFLine(vec3(p.xy,fract(clamp(p.z,0.5,2.-0.5)-0.5)),vec3(0.5,-1.,0.5),vec3(0.5,0.6+Y,0.5)));
    d = min(d,max(max(max(tmpLine-0.2,-tmpLine+0.1),p.y-(Y-0.075)),-p.y));
    //Stud
    vec3 StudPos = vec3(clamp(floor(p.x),0.,1.),Y,clamp(floor(p.z),0.,1.-floor(p.x)));
    d = max(d,-max(DFLine(p-StudPos,vec3(0.5,-1.,0.5),vec3(0.5,-0.05,0.5))-0.15,p.y-1.19)); //Hole under stud
    d = min(d,DFStud(p-StudPos)); //Studs
    return d;
}

float DFRound111(vec3 p) {
    float d = -smin(smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.5,-p.y+0.4,0.04),p.y-0.3,0.015);
    d = min(d,max(max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))-0.397,-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.305)
    ,p.y-0.35),-p.y));
    d = max(d,-max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))-0.15,p.y-0.39));
    d = min(d,DFStud(vec3(p.x,p.y-0.4,p.z))); //Stud
    return d;
}

float DFRound131(vec3 p) {
    float d = max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))-0.397,p.y-0.35),-p.y);
    d = min(d,max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.48,-p.y+1.2,0.05),-p.y+0.2));
    //Stud
    d = smin(d,max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.3,-p.y+1.4,0.07),-p.y+1.2),0.07);
    d = -smin(-d,DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))-0.2,0.07);
    return d;
}

float DFCone131(vec3 p) {
    float d = max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))-0.397,p.y-0.35),-p.y);
    d = min(d,max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+mix(0.48,0.33,p.y-0.2),-p.y+1.2,0.05),-p.y+0.2));
    //Stud
    d = smin(d,max(-smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.3,-p.y+1.4,0.07),-p.y+1.2),0.04);
    d = -smin(-d,DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))-0.2,0.07);
    return d;
}

float DFSlope(vec3 p, float Z) {
    float d = DFBox(p-vec3(0.02),vec3(1.96,1.16,Z-0.04))-0.02;
    d = -smin(-d,-smin(-DFBox(p-vec3(0.22,-1.,0.22),vec3(1.56,1.96,Z-0.44))+0.02,-dot(LEGOSlope,p-vec3(1.8,0.2,0.)),0.05),0.02);
    //Interior
    if (Z>1.5) {
        d = min(d,max(max(max(DFLine(vec3(p.xy,fract(clamp(p.z,0.5,Z-0.5)-0.5)),vec3(1.,-1.,0.5),vec3(1.,1.,0.5))-0.407,
        -DFLine(vec3(p.xy,fract(clamp(p.z,0.5,Z-0.5)-0.5)),vec3(1.,-1.,0.5),vec3(1.,1.,0.5))+0.3),p.y-(1.2-0.05)),-p.y));
    }
    d = -smin(-d,-dot(LEGOSlope,p-vec3(2.,0.3,0.)),0.05);
    vec3 StudPos = vec3(0.,1.2,clamp(floor(p.z),0.,Z-1.));
    d = min(d,DFStud(p-StudPos)); //Studs
    return d;
}

float DFSlope331(vec3 p) {
    float d = DFBox(p-vec3(0.02),vec3(2.96,1.16,0.96))-0.02;
    //d = -smin(-d,-smin(-DFBox(p-vec3(0.22,-1.,0.22),vec3(1.56,1.96,Z-0.44))+0.02,-dot(LEGOSlope,p-vec3(1.8,0.2,0.)),0.05),0.02);
    //Interior
    //if (Z>1.5) {
        //d = min(d,max(max(max(DFLine(vec3(p.xy,fract(clamp(p.z,0.5,Z-0.5)-0.5)),vec3(1.,-1.,0.5),vec3(1.,1.,0.5))-0.407,
        //-DFLine(vec3(p.xy,fract(clamp(p.z,0.5,Z-0.5)-0.5)),vec3(1.,-1.,0.5),vec3(1.,1.,0.5))+0.3),p.y-(1.2-0.05)),-p.y));
    //}
    d = -smin(-d,-dot(LEGOSlope331,p-vec3(3.,0.3,0.)),0.05);
    d = min(d,DFStud(p-vec3(0.,1.2,0.))); //Studs
    return d;
}

float DFISlope(vec3 p, float Z) {
    float d = -smin(-DFBox(p-vec3(0.02),vec3(1.96,1.16,Z-0.04))+0.02,-dot(LEGOISlope,p-vec3(1.,0.,0.)),0.03);
    d = -smin(-d,max(DFBox(p-vec3(1.15,0.2,0.15),vec3(0.75,2.,Z-0.3)),dot(LEGOISlope,p-vec3(1.,0.2,0.))),0.05);
    //Stud
    float StudZ = clamp(floor(p.z),0.,Z-1.)+0.5;
    d = smin(d,-smin(-max(-smin(-DFLine(p,vec3(1.5,-1.,StudZ),vec3(1.5,2.,StudZ))+0.3,-p.y+1.4,0.07),-p.y+0.85),
    DFLine(p,vec3(1.5,-1.,StudZ),vec3(1.5,2.,StudZ))-0.2,0.07),0.07);
    d = min(d,DFStud(p-vec3(0.,1.2,StudZ-0.5))); //Studs
    return d;
}

float DFOnlySlope(vec3 p) {
    float d = -smin(-DFBox(p-vec3(0.1,0.1,0.1),vec3(0.8,0.8,0.8))+0.1,-dot(LEGOOSlope,p-vec3(0.,0.8,0.)),0.06);
    return d;
}

float DFHeadLight(vec3 p) {
    float d = -smin(-DFBox(p-vec3(0.04),vec3(0.92,1.12,0.92))+0.04,DFBox(p-vec3(-1.,0.25,-1.),vec3(1.2,2.,3.)),0.05);
    //Stud
    d = smin(d,-smin(-DFLine(p,vec3(0.5,0.7,0.5),vec3(-2.,0.7,0.5))+0.3,p.x,0.07),0.05);
    d = max(d,-min(DFLine(p,vec3(0.5,0.7,0.5),vec3(-2.,0.7,0.5))-0.2,DFBox(p-vec3(0.2,-1.,0.2),vec3(0.6,1.2,0.6))));
    d = max(d,-DFBox(p-vec3(0.3,0.2,0.2),vec3(3.,0.8,0.6)));
    d = min(d,max(-smin(-DFLine(p-vec3(0.,1.2,0.),vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.3,-p.y+1.2+0.2,0.075),-p.y+1.2)); //Stud
    return d;
}

float DFHose(vec3 p) {
    vec3 rp = p-vec3(0.5,0.,0.5);
    float lrp = length(rp);
    float d = -smin(rp.y,-max(lrp-0.45,-lrp+0.35),0.02);
    d = smin(d,DFLine(p,vec3(0.5,0.45,0.5),vec3(0.5,1.15,0.5))-0.2,0.07);
    //Stud
    d = smin(d,-smin(smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.3,-p.y+1.4,0.07),p.y-1.2,0.07),0.07);
    //Arm
    d = smin(d,DFLine(p,vec3(0.7,0.95,0.5),vec3(1.2,0.95,0.5))-0.2+(p.x-0.7)*0.1,0.1);
    d = smin(d,max(max(DFLine(p,vec3(0.,0.95,0.5),vec3(3.,0.95,0.5))-0.2,-p.x+1.2),p.x-1.4),0.04);
    return d;
}

float DFDoubleSlope(vec3 rp, float fi) {
    vec3 p = vec3(1.+abs(rp.x-1.),rp.yz);
    float d = DFBox(p-vec3(0.02),vec3(1.96,1.16,fi-0.04))-0.02;
    d = -smin(-d,-smin(-DFBox(p-vec3(0.22,-1.,0.22),vec3(1.56,1.96,fi-0.44))+0.02,-dot(LEGOSlope,p-vec3(0.8,1.2,0.)),0.05),0.02);
    d = -smin(-d,-dot(LEGOSlope,p-vec3(1.,1.25,0.)),0.05);
    return d;
}

float DFRound232(vec3 p) {
    float dfl = DFLine(p,vec3(1.,-3.,1.),vec3(1.,3.,1.));
    float d = -smin(smin(-max(dfl-1.,-dfl+0.9),p.y-1.2,0.02),-p.y,0.02);
    d = -smin(-max(-smin(-dfl+1.,-p.y+1.2,0.1),smin(-dfl+0.9,-p.y+1.,0.92)),p.y,0.04);
    d = min(d,max(max(max(DFLine(p,vec3(1.,-1.,1.),vec3(1.,1.,1.))-0.407,
    -DFLine(p,vec3(1.,-1.,1.),vec3(1.,1.,1.))+0.3),p.y-(1.2-0.05)),-p.y));
    vec3 StudPos = vec3(clamp(floor(p.x),0.,1.),0.,clamp(floor(p.z),0.,1.));
    d = -smin(-d,DFStud(p-StudPos),0.08); //Studs
    float ds = max(-p.y+1.16,-smin(-DFLine(p-StudPos,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))+0.3,-p.y+1.4,0.075));
    d = smin(d,ds,0.04); //Studs
    //Cross
    d = -smin(-d,smin(DFBox(p-vec3(0.925,-1.,0.8),vec3(0.15,4.,0.4)),
              DFBox(p-vec3(0.8,-1.,0.925),vec3(0.4,4.,0.15)),0.04)-0.02,0.08);
    return d;
}

float DFPanel(vec3 p) {
    float d = DFBox(p-vec3(0.04),vec3(1.92,0.32,0.92))-0.04;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),vec3(1.6,1.2,0.6)));
    d = min(d,DFBox(p-vec3(0.05,0.05,0.05),vec3(1.9,1.1,0.))-0.05);
    return d;
}

float DFWindow(vec3 p, float S) {
    float Size = S*2.;
    float YSize = 1.2+S*1.2;
    float d = DFBox(p-vec3(0.04),vec3(Size-0.08,YSize-0.08,0.92))-0.04;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),vec3(Size-0.4,1.2,0.6))); //Under
    //Under
    float tmpLine = DFLine(vec3(fract(clamp(p.x,0.5,Size-0.5)-0.5),p.yz),vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5));
    d = min(d,max(max(max(tmpLine-0.2,-tmpLine+0.1),p.y-(0.2)),-p.y));
    //Window
    d = max(d,-DFBox(p-vec3(0.2,0.4,-1.),vec3(Size-0.4,YSize-0.6,3.)));
        d = max(d,-DFBox(p-vec3(0.1,0.4,0.6),vec3(Size-0.2,YSize-0.6,3.)));
    //Stud
    vec3 StudPos = vec3(clamp(floor(p.x),0.,Size-1.),YSize,0.);
    d = min(d,DFStud(p-StudPos)); //Studs
    vec3 linep = vec3(mod(p.x,3.3)-(1.65-0.65*S),p.y-0.4,p.z-0.7);
    d = max(d,-DFLine(linep,vec3(0.),vec3(0.,4.,0.))+0.1*S);
    return d;
}

float DFWindowFrame(vec3 p) {
    float d = DFBox(p-vec3(0.18,0.08,0.08),vec3(1.64,2.84,0.04))-0.08;
    d = smin(d,DFLine(p,vec3(0.1,0.1,0.1),vec3(vec3(0.1,2.9,0.1)))-0.1,0.1);
    //Window boxes
    //d = max(d,-DFBox(p-vec3(0.2,0.15+floor(p.y/1.2)*0.,-1.),vec3(1.55,1.2-0.15-0.15,3.))-0.02);
    d = max(d,-DFBox(p-vec3(0.2,0.25+floor(p.y/1.5)*1.425,-1.),vec3(1.55,1.1,3.))-0.02);
    d = min(d,DFBox(p-vec3(0.08,0.08+floor(p.y/2.75)*2.75,0.08),vec3(0.3,0.1,0.1))-0.08);
    return d;
}

float DFBrickHole(vec3 p) {
    float d = DFBox(p-vec3(0.04),vec3(0.92,1.12,0.92))-0.04;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),vec3(0.4,1.2,0.4)));
    d = -smin(-d,DFLine(p,vec3(-5.,0.7,0.5),vec3(5.,0.7,0.5))-0.4,0.08);
    d = min(d,DFStud(p-vec3(0.,1.2,0.)));
    return d;
}

float DFHandle(vec3 p, float type) {
    //Symmetric through the x-axis
    vec3 syp = vec3(p.xy,abs(p.z-1.));
    float d = DFBox(syp-vec3(0.04,0.04,-0.96),vec3(0.92,0.32,1.92))-0.04;
    //Handle
    float Z = type*0.4;
    float tmpCyl = length(syp.xy-vec2(1.5,0.3));
    d = min(d,DFBox(syp-vec3(0.04,0.04,0.74-Z),vec3(1.46,0.32,0.22))-0.04);
    d = min(d,-smin(smin(-tmpCyl+0.3,1.-Z-syp.z,0.04),syp.z-0.7+Z,0.04));
    d = min(d,max(tmpCyl-0.2,syp.z-1.));
    //Interior + Stud
    d = max(d,-DFBox(syp-vec3(0.2,-1.,-0.8),vec3(0.6,1.2,1.6)));
    float tmpLine = min(DFLine(vec3(syp.xy,syp.z+0.5),vec3(0.5,-1.,0.5),vec3(0.5,1.2,0.5)),
    DFLine(vec3(syp.xy,syp.z+0.5),vec3(0.5,-1.,0.5),vec3(0.5,0.6,0.5)));
    d = min(d,max(max(max(tmpLine-0.2,-tmpLine+0.1),syp.y-(0.4-0.075)),-syp.y));
    d = max(d,-max(DFLine(syp,vec3(0.5,-1.,0.5),vec3(0.5,0.35,0.5))-0.15,syp.y-1.19)); //Hole under stud
    d = min(d,DFStud(syp-vec3(0.,0.4,0.))); //Studs
    return d;
}

float DFGrip(vec3 p) {
    float d = DFBox(p-vec3(0.04,0.44,0.04),vec3(0.92,0.32,0.92))-0.04;
    //Grip
    d = min(d,DFBox(p-vec3(0.04,0.44,0.39),vec3(1.36,0.32,0.22))-0.04);
    d = min(d,-smin(smin(-length(p.xy-vec2(1.45,0.68))+0.37,-p.z+0.65,0.04),-0.35+p.z,0.04));
    d = max(d,-length(p.xy-vec2(1.5,0.7))+0.2);
    d = -smin(-d,1.62-p.x,0.08);
    //Stud
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),vec3(0.6,1.6,0.6)));
    vec3 StudPos = vec3(0.,0.8,0.);
    d = max(d,-max(DFLine(p-StudPos,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5))-0.15,p.y-0.75)); //Hole under stud
    d = min(d,DFStud(p-StudPos)); //Studs
    return d;
}

float DFDisk(vec3 p, float radius) {
    //(0.4-y)^2 = 1+(0.1-y)^2
    //(0.8-y)^2 = 2.25+(0.1-y)^2
    float d;
    float sY = ((radius<1.5)?-1.41667:-1.375);
    if (radius<1.5) {
        float LenMiddle = length(p.xz-1.);
        d = max(max(length(p-vec3(1.,sY,1.))-(-sY+0.4),
             -length(p-vec3(1.,sY-0.1,1.))+(-sY+0.4)),LenMiddle-1.);
        d = smin(d,max(-p.y,-smin(-DFLine(p,vec3(1.,-1.,1.),
             vec3(1.,1.,1.))+0.3,-p.y+0.6,0.075)),0.04); //Stud
        d = min(d,max(max(LenMiddle-0.4,-p.y),p.y-0.35));
        //Holes
        d = -smin(-d,LenMiddle-0.2,0.05);
        d = max(d,-max(p.y+0.05-0.4*radius,LenMiddle-0.3));
    } else {
        float LenMiddle = length(p.xz-1.5);
        d = max(max(length(p-vec3(1.5,sY,1.5))-(-sY+0.8),
             -length(p-vec3(1.5,sY-0.1,1.5))+(-sY+0.8)),LenMiddle-1.5);
        d = min(d,max(-p.y,max(p.y-0.2,abs(LenMiddle-1.4)-0.1)));
        d = smin(d,max(-p.y+0.4,-smin(-DFLine(p,vec3(1.5,-1.,1.5),
             vec3(1.5,1.,1.5))+0.3,-p.y+1.,0.075)),0.04); //Stud
        d = min(d,max(max(LenMiddle-0.4,-p.y+0.4),p.y-0.75));
        //Holes
        d = -smin(-d,LenMiddle-0.2,0.05);
        d = max(d,-max(p.y+0.05-0.8,LenMiddle-0.3));
    }
    return d;
}

float DFDoor(vec3 p) {
    //~Model 3861
    float d = DFBox(p-vec3(0.48,0.42,0.02),vec3(3.46,7.16,0.16))-0.02;
    //Ornament
    d = -smin(-d,DFBox(p-vec3(0.75,0.6,-1.),vec3(2.5,2.6,1.15)),0.1);
    d = min(d,DFBox(p-vec3(1.15,1.,0.),vec3(1.7,1.8,0.15)));
    //Window
    d = -smin(-d,DFBox(p-vec3(0.75,4.,-1.),vec3(2.5,2.5,1.1)),0.1);
        d=-smin(-d,DFBox(vec3(abs(p.x-2.),abs(p.y-5.25),p.z+1.)-vec3(0.125,0.125,0.),vec3(1.,1.,3.)),0.1);
    //Handle
    d = min(d,DFLine(p,vec3(3.5,3.6,0.),vec3(3.2,3.6,0.))-0.15);
    //Vertical cylinder
    d = min(d,max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,10.,0.5))-0.5,p.y-7.2),-p.y));
    return d;
}

float DFSlopeCross(vec3 p) {
    return smin(DFSlope(p,2.),DFSlope(p.zyx,2.),0.04);
}

float DFDoubleSlopeInverse(vec3 p) {
    return -smin(-DFDoubleSlope(p,2.),dot(vec3(0.,LEGOSlope.y,-LEGOSlope.x),p-vec3(0.,0.1,1.)),0.1);
}

float DFWindowOblique(vec3 p) {
    float DOT0 = dot(LEGOObliqueSlope,p-vec3(0.,0.4,4.));
    float DOT1 = dot(LEGOObliqueSlope,p-vec3(0.,0.,3.));
    float d = DFBox(p-vec3(0.04,0.04,0.04),vec3(3.92,3.52,3.92))-0.04;
    d = max(d,-DFBox(p-vec3(0.24,0.44,-5.),vec3(3.52,2.72,10.))+0.04);
    d = -smin(-d,DOT0,0.05);
    d = -smin(-d,-DOT1,0.05);
    //Interior
    d = min(d,max(max(DFBox(p-vec3(0.,0.4,0.),vec3(4.,0.8,4.)),-DOT0+0.1),DOT1+0.8));
        d = min(d,max(max(max(DFBox(p-vec3(0.,1.2,0.),vec3(4.,2.4,4.)),1.6-abs(p.x-2.)),-DOT0+0.4),DOT1+0.5));
    d = max(d,-DFLine(p,vec3(-1.,3.,1.4),vec3(5.,3.,1.4))+0.1);
    d = max(d,-DFLine(p,vec3(-1.,1.2,2.9),vec3(5.,1.2,2.9))+0.1);
    //Studs
    vec3 StudPos = vec3(clamp(floor(p.x),0.,3.),3.6,0.);
    d = min(d,DFStud(p-StudPos));
    return d;
}

vec3 TraceBrick(vec3 BRPos, vec3 BRDir, vec3 CBrickSize, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFBrick(biRP,CBrickSize);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>CBrickSize.y-0.201) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceBrick_NoStud(vec3 BRPos, vec3 BRDir, vec3 CBrickSize, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFBrick_NoStud(biRP,CBrickSize);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceGrate(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFGrate(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceCorner(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFCorner(biRP,fi);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>1.399) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceRound111(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFRound111(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>0.599) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceRound131(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFRound131(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceCone131(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFCone131(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceSlope(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFSlope(biRP,fi);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>1.399) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceSlope331(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFSlope331(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>1.399) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceISlope(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFISlope(biRP,fi);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>1.399 && biRP.x<1.) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceOnlySlope(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFOnlySlope(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceHeadLight(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFHeadLight(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>1.399) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceHose(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFHose(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceDoubleSlope(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFDoubleSlope(biRP,fi);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceRound232(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFRound232(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TracePanel(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFPanel(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceWindow(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFWindow(biRP,fi);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>2.599+1.2*(fi-1.)) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceWindowFrame(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFWindowFrame(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceBrickHole(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFBrickHole(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>1.399) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceDoor(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFDoor(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceHandle(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFHandle(biRP,fi);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>0.599) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceGrip(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFGrip(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>0.599) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceDisk(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFDisk(biRP,fi);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceSlopeCross(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFSlopeCross(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>1.399) OUT.yz = fract(biRP.xz);
    return OUT;
}

vec3 TraceDoubleSlopeInverse(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFDoubleSlopeInverse(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    return OUT;
}

vec3 TraceWindowOblique(vec3 BRPos, vec3 BRDir, float fi, float biFAR) {
    vec3 OUT = vec3(0.,-1.,-1.); float bit; vec3 biRP;
    for (int i=0; i<400; i++) {
        biRP = BRPos+BRDir*OUT.x;
        bit = DFWindowOblique(biRP);
        OUT.x = OUT.x+bit;
        if (min(biFAR-OUT.x,bit-0.0005)<0.) break;
    }
    if (biRP.y>3.799) OUT.yz = fract(biRP.xz);
    return OUT;
}

float DF32x32(vec3 sp) {
    //32x32 floor SDF
    float tmpd = DFBox(sp.xz-0.25,vec2(31.75))-0.25;
    vec2 tmpw = vec2(tmpd,abs(sp.y));
    float d = min(min(max(tmpw.x,tmpw.y),0.)+length(max(tmpw,0.)),DFStud(vec3(fract(sp.x),sp.y,fract(sp.z))));
        //d = min(d,DFDoubleSlope(sp-vec3(0.,0.4,0.),1.)); //DEBUG
    return d;
}

//BrickDim array
float BrickADim[7]=float[7](1.,2.,3.,4.,6.,8.,10.);
vec3 BrickDim[42]=vec3[42](
    vec3(2.,0.8,1.), //DFGrate
    vec3(2.,0.8,2.), //DFCorner 2x1x2
    vec3(2.,1.2,2.), //DFCorner 2x2x2
    vec3(2.,1.6,2.), //DFCorner 2x3x2
    vec3(1.,0.8,1.), //Round111
    vec3(1.,1.6,1.), //Round131
    vec3(1.,1.6,1.), //Cone131
    vec3(2.,1.6,1.), //Slope 2x3x1
    vec3(2.,1.6,2.), //Slope 2x3x2
    vec3(2.,1.6,3.), //Slope 2x3x3
    vec3(2.,1.6,4.), //Slope 2x3x4
    vec3(2.,1.6,5.), //Slope 2x3x5
    vec3(2.,1.6,6.), //Slope 2x3x6
    vec3(2.,1.6,7.), //Slope 2x3x7
    vec3(2.,1.6,8.), //Slope 2x3x8
    vec3(3.,1.6,1.), //DFSlope331
    vec3(2.,1.6,1.), //DFISlope 2x3x1
    vec3(2.,1.6,2.), //DFISlope 2x3x2
    vec3(1.,0.8,1.), //DFOnlySlope
    vec3(1.,1.6,1.), //DFHeadLight
    vec3(2.,1.6,1.), //DFHose
    vec3(2.,1.2,1.), //DFDoubleSlope
    vec3(2.,1.2,2.), //DFDoubleSlope
    vec3(2.,1.2,3.), //DFDoubleSlope
    vec3(2.,1.2,4.), //DFDoubleSlope
    vec3(2.,1.2,5.), //DFDoubleSlope
    vec3(2.,1.2,6.), //DFDoubleSlope
    vec3(2.,1.6,2.), //DFRound232
    vec3(2.,1.2,1.), //DFPanel
    vec3(2.,2.8,1.), //DFWindow 2x2x1
    vec3(4.,5.2,1.), //DFWindow 4x4x1
    vec3(2.,3.,1.), //DFWindowPanel
    vec3(1.,1.6,1.), //DFBrickHole
    vec3(4.,7.2,1.), //DFDoor
    vec3(2.,0.8,2.), //DFHandle 1 Handle
    vec3(2.,0.8,2.), //DFHandle 3 Handle
    vec3(2.,1.2,1.), //DFGrip
    vec3(2.,0.8,2.), //DFDisk R = 1
    vec3(3.,1.2,3.), //DFDisk R = 1.5
    vec3(2.,1.6,2.), //DFSlopeCross
    vec3(2.,1.2,2.), //DFDoubleSlopeInverse
    vec3(4.,4.,4.) //DFWindowOblique
);

float USDF(vec3 p, int i, float fi, vec3 BrickSize) {
    //Unified SDF (visualizes indices)
    /*
    if (i<28) return DFBrick(p,BrickSize);
    else if (i<56) return DFBrick_NoStud(p,BrickSize);
    else if (i==56) return DFGrate(p);
    else if (i<=59) return DFCorner(p,fi-56.);
    else if (i==60) return DFRound111(p);
    else if (i==61) return DFRound131(p);
    else if (i==62) return DFCone131(p);
    else if (i<=70) return DFSlope(p,fi-62.);
    else if (i==71) return DFSlope331(p);
    else if (i<=73) return DFISlope(p,fi-71.);
    else if (i==74) return DFOnlySlope(p);
    else if (i==75) return DFHeadLight(p);
    else if (i==76) return DFHose(p);
    else if (i<82) return DFDoubleSlope(p,fi-76.);
    else if (i==83) return DFRound232(p);
    else if (i==84) return DFPanel(p);
    else if (i<=86) return DFWindow(p,fi-84.);
    else if (i==87) return DFWindowFrame(p);
    else if (i==88) return DFBrickHole(p);
    else if (i==89) return DFDoor(p);
    else if (i<=91) return DFHandle(p,fi-90.);
    else if (i==92) return DFGrip(p);
    else if (i<=94) return DFDisk(p,fi-92.);
    else if (i==95) return DFSlopeCross(p);
    else if (i==96) return DFDoubleSlopeInverse(p);
    else if (i==97) return DFWindowOblique(p);
    */
    return 1000.;
}

//Brick array
//Colors: //White,Yellow,Brown,Black,Red,Blue,Beige,Orange,LightBlack,LightGreen,Grey,DarkGrey,TrueYellow
const vec3 BrickColorArray[13] = vec3[13](vec3(0.99),vec3(1.,0.7,0.2),vec3(0.25,0.12,0.03),vec3(0.05),
    vec3(0.99,0.05,0.05),vec3(0.05,0.05,0.95),vec3(0.7,0.6,0.1),vec3(0.8,0.6,0.3),
    vec3(0.2),vec3(0.15,0.99,0.15),vec3(0.5),vec3(0.35),vec3(1.,1.,0.1)
);
const vec3 GarageY = normalize(vec3(0.,cos(radians(30.)),sin(radians(30.))));
const vec3 GarageRotP = vec3(21.,5.9,11.7);
const vec3 StairX = normalize(vec3(cos(radians(65.)),sin(radians(65.)),0.));
const vec3 StairY = vec3(-StairX.y,StairX.x,0.);
const vec3 StairRotP = vec3(19.5,8.3,24.);
const vec3 LampZ = normalize(vec3(0.,1.,-1.));
const vec3 LampY = vec3(0.,LampZ.z,-LampZ.y);
const vec3 LampRotP = vec3(24.5,9.5,11.5);
const vec3 DiskX = normalize(vec3(1.,1.,0.));
const vec3 DiskY = vec3(-DiskX.y,DiskX.x,0.);
const vec3 DiskRotP = vec3(20.4,12.2,15.5);
const int NBricks = 128;
const BRICK BrickArray[NBricks]=BRICK[NBricks](
    //2 lightgreen 214
    BRICK(vec3(2.,0.,14.),vec3(0.,0.,1.),9,10),
        BRICK(vec3(32.,0.,14.),vec3(0.,0.,1.),9,10),
    //2 lightgreen 212+211+dark filter
    BRICK(vec3(32.,0.,12.),vec3(0.,0.,1.),9,8),
        BRICK(vec3(32.,0.,10.),vec3(0.,0.,1.),9,1),
    BRICK(vec3(29.,0.,10.),vec3(1.,0.,0.),8,56),
    //Grey walls (garage)
    BRICK(vec3(31.,0.,11.),vec3(0.,0.,1.),10,61),
    BRICK(vec3(30.,0.,11.),vec3(0.,0.,1.),10,18),
        BRICK(vec3(30.,0.,17.),vec3(0.,0.,1.),10,15),
        BRICK(vec3(30.,0.,19.),vec3(0.,0.,1.),10,18),
    BRICK(vec3(30.,0.,27.),vec3(-1.,0.,0.),10,59),
    //3 grey bricks behind + filter
    BRICK(vec3(22.,0.,26.),vec3(1.,0.,0.),10,18),
        BRICK(vec3(16.,0.,26.),vec3(1.,0.,0.),10,18),
        BRICK(vec3(10.,0.,26.),vec3(1.,0.,0.),10,18),
    BRICK(vec3(10.,0.,25.),vec3(0.,0.,1.),8,56),
    //Grey bricks forward and side + under door
    BRICK(vec3(11.,0.,24.),vec3(0.,0.,1.),10,15),
        BRICK(vec3(11.,0.,18.),vec3(0.,0.,1.),10,18),
    BRICK(vec3(10.,0.,17.),vec3(1.,0.,0.),10,16), //beyond door
        BRICK(vec3(17.,0.,17.),vec3(1.,0.,0.),10,16),
        BRICK(vec3(21.,0.,15.),vec3(0.,0.,1.),10,16),
        BRICK(vec3(20.,0.,13.),vec3(1.,0.,0.),10,64), //Slope 2x3x2
    BRICK(vec3(15.,0.,15.),vec3(0.,0.,1.),10,9), //Under Door
        BRICK(vec3(17.,0.,15.),vec3(0.,0.,1.),10,9),
    //In to garage (grey)
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
        BRICK(vec3(22.,0.,6.),vec3(0.,0.,1.),10,32),
        BRICK(vec3(23.,0.,6.),vec3(0.,0.,1.),10,32),
        BRICK(vec3(22.,0.,0.),vec3(0.,0.,1.),10,32),
        BRICK(vec3(23.,0.,0.),vec3(0.,0.,1.),10,32),
    BRICK(vec3(27.,0.,12.),vec3(1.,0.,0.),10,29),
        BRICK(vec3(28.,0.,6.),vec3(0.,0.,1.),10,32),
        BRICK(vec3(29.,0.,6.),vec3(0.,0.,1.),10,32),
        BRICK(vec3(28.,0.,0.),vec3(0.,0.,1.),10,32),
        BRICK(vec3(29.,0.,0.),vec3(0.,0.,1.),10,32),
    //Grey at garage + yellow at door entrance + trappsteg
    BRICK(vec3(21.,0.,11.),vec3(0.,0.,1.),10,15),
    BRICK(vec3(18.,0.,15.),vec3(0.,0.,1.),1,29),
        BRICK(vec3(13.,0.,15.),vec3(0.,0.,1.),1,29),
        BRICK(vec3(12.,0.,14.),vec3(1.,0.,0.),1,32),
    BRICK(vec3(14.,0.,12.),vec3(1.,0.,0.),1,29),
        BRICK(vec3(14.,0.,10.),vec3(1.,0.,0.),1,29),
        BRICK(vec3(14.,0.,8.),vec3(1.,0.,0.),1,29),
        BRICK(vec3(13.,0.,6.),vec3(1.,0.,0.),1,29),
        BRICK(vec3(12.,0.,4.),vec3(1.,0.,0.),1,29),
        BRICK(vec3(11.,0.,2.),vec3(1.,0.,0.),1,29),
        BRICK(vec3(10.,0.,0.),vec3(1.,0.,0.),1,29),
    //Cones + 2 flowers + 4 base
    BRICK(vec3(9.,0.,17.),vec3(1.,0.,0.),1,62), //Cone
        BRICK(vec3(8.,0.,17.),vec3(1.,0.,0.),1,62),
        BRICK(vec3(9.,0.,20.),vec3(1.,0.,0.),1,62),
        BRICK(vec3(8.,0.,20.),vec3(1.,0.,0.),1,62),
    BRICK(vec3(4.,0.,19.),vec3(1.,0.,0.),4,60),
        BRICK(vec3(3.,0.,21.),vec3(1.,0.,0.),4,60),
    BRICK(vec3(2.,0.,19.),vec3(1.,0.,0.),2,74),
        BRICK(vec3(1.,0.,20.),vec3(-1.,0.,0.),2,74), //Onlyslope
        BRICK(vec3(1.,0.,19.),vec3(0.,0.,-1.),2,74),
        BRICK(vec3(2.,0.,20.),vec3(0.,0.,1.),2,74),
    //Table + door front
    BRICK(vec3(10.,1.2,17.),vec3(0.,0.,1.),2,31), //Table
        BRICK(vec3(9.,1.2,17.),vec3(0.,0.,1.),2,31),
    BRICK(vec3(17.,0.4,15.),vec3(0.,0.,1.),1,29),
        BRICK(vec3(14.,0.4,15.),vec3(0.,0.,1.),1,29),
        BRICK(vec3(14.,0.4,15.),vec3(1.,0.,0.),1,29),
        BRICK(vec3(14.,0.4,16.),vec3(1.,0.,0.),8,56),
    //H=1.2 grey walls
    BRICK(vec3(31.,1.2,11.),vec3(0.,0.,1.),10,61), //Round 131
    BRICK(vec3(30.,1.2,11.),vec3(0.,0.,1.),10,20),
        BRICK(vec3(30.,1.2,21.),vec3(0.,0.,1.),10,16), //3x3x1
        BRICK(vec3(30.,1.2,24.),vec3(0.,0.,1.),10,15), //2x3x1
    BRICK(vec3(27.,1.2,26.),vec3(1.,0.,0.),10,16), //3x3x1 behind
        BRICK(vec3(21.,1.2,26.),vec3(1.,0.,0.),10,18),
        BRICK(vec3(11.,1.2,26.),vec3(1.,0.,0.),10,20),
        BRICK(vec3(10.,1.2,26.),vec3(1.,0.,0.),3,75),
    //Rest of the wall + hose
    BRICK(vec3(11.,1.2,23.),vec3(0.,0.,1.),10,16),
        BRICK(vec3(11.,1.2,17.),vec3(0.,0.,1.),10,18),
    BRICK(vec3(11.,1.2,17.),vec3(1.,0.,0.),10,15),
        BRICK(vec3(17.,1.2,17.),vec3(1.,0.,0.),10,15),
        BRICK(vec3(19.,1.2,17.),vec3(1.,0.,0.),10,15),
        BRICK(vec3(21.,1.2,11.),vec3(0.,0.,1.),10,18),
    BRICK(vec3(10.2,2.3,27.1),vec3(0.,-270.9682,-0.25),10,76),
    //Flowers on round232
    BRICK(vec3(18.,0.,12.),vec3(1.,0.,0.),2,83),
        BRICK(vec3(18.,1.2,12.),vec3(1.,0.,0.),9,60),
        BRICK(vec3(18.,1.2,13.),vec3(1.,0.,0.),9,60),
        BRICK(vec3(19.,1.2,12.),vec3(1.,0.,0.),9,60),
        BRICK(vec3(19.,1.2,13.),vec3(1.,0.,0.),9,60),
            BRICK(vec3(18.,1.6,12.),vec3(1.,0.,0.),12,60),
            BRICK(vec3(18.,1.6,13.),vec3(1.,0.,0.),4,60),
            BRICK(vec3(19.,1.6,12.),vec3(1.,0.,0.),4,62),
            BRICK(vec3(19.,1.6,13.),vec3(1.,0.,0.),12,62),
    BRICK(vec3(2.,0.,15.),vec3(1.,0.,0.),2,83),
        BRICK(vec3(2.,1.2,15.),vec3(1.,0.,0.),4,60),
        BRICK(vec3(3.,1.2,15.),vec3(1.,0.,0.),4,60),
        BRICK(vec3(2.,1.2,16.),vec3(1.,0.,0.),4,60),
    //Bush garage
    BRICK(vec3(32.,0.,6.),vec3(0.,0.,1.),2,3),
        BRICK(vec3(32.,0.4,9.),vec3(-1.,0.,0.),9,73),
            BRICK(vec3(32.,0.4,9.),vec3(0.,0.,1.),9,72),
            BRICK(vec3(31.,0.4,7.),vec3(0.,0.,-1.),9,72),
        BRICK(vec3(32.,1.6,10.),vec3(-1.,0.,0.),9,64),
            BRICK(vec3(31.,1.6,8.),vec3(0.,0.,-1.),9,63),
        BRICK(vec3(31.,1.6,5.),vec3(1.,0.,0.),12,60),
            BRICK(vec3(30.,1.6,7.),vec3(1.,0.,0.),12,60),
            BRICK(vec3(31.,1.6,10.),vec3(1.,0.,0.),12,60),
    //Bush behind house
    BRICK(vec3(3.,0.,28.),vec3(1.,0.,0.),2,3),
        BRICK(vec3(4.,0.4,29.),vec3(0.,0.,-1.),9,73),
            BRICK(vec3(6.,0.4,28.),vec3(1.,0.,0.),9,72),
            BRICK(vec3(4.,0.4,29.),vec3(-1.,0.,0.),9,72),
        BRICK(vec3(3.,1.6,29.),vec3(0.,0.,-1.),9,64),
            BRICK(vec3(5.,1.6,28.),vec3(1.,0.,0.),9,63),
        BRICK(vec3(7.,1.6,28.),vec3(1.,0.,0.),12,60),
            BRICK(vec3(5.,1.6,27.),vec3(1.,0.,0.),12,60),
            BRICK(vec3(2.,1.6,28.),vec3(1.,0.,0.),12,60),
    //Small round + Red layer
    BRICK(vec3(31.,2.4,11.),vec3(0.,0.,1.),10,60),
    BRICK(vec3(30.,2.4,11.),vec3(0.,0.,1.),4,5),
        BRICK(vec3(30.,2.4,19.),vec3(0.,0.,1.),4,5),
    BRICK(vec3(26.,2.4,26.),vec3(1.,0.,0.),4,2),
        BRICK(vec3(18.,2.4,26.),vec3(1.,0.,0.),4,5),
        BRICK(vec3(10.,2.4,26.),vec3(1.,0.,0.),4,5),
    BRICK(vec3(11.,2.4,18.),vec3(0.,0.,1.),4,5),
    BRICK(vec3(10.,2.4,17.),vec3(1.,0.,0.),4,2),
        BRICK(vec3(17.,2.4,17.),vec3(1.,0.,0.),4,2),
        BRICK(vec3(20.,2.4,17.),vec3(1.,0.,0.),4,60),
    BRICK(vec3(21.,2.4,14.),vec3(0.,0.,1.),4,2),
        BRICK(vec3(21.,2.4,11.),vec3(0.,0.,1.),4,2),
    //First white layer
    BRICK(vec3(30.,2.8,11.),vec3(0.,0.,1.),0,17),
        BRICK(vec3(30.,2.8,15.),vec3(0.,0.,1.),0,18),
        BRICK(vec3(30.,2.8,21.),vec3(0.,0.,1.),0,18),
    BRICK(vec3(23.,2.8,26.),vec3(1.,0.,0.),0,18),
        BRICK(vec3(17.,2.8,26.),vec3(1.,0.,0.),0,18),
        BRICK(vec3(11.,2.8,26.),vec3(1.,0.,0.),0,18),
    BRICK(vec3(11.,2.8,24.),vec3(0.,0.,1.),0,16),
        BRICK(vec3(11.,2.8,20.),vec3(0.,0.,1.),0,3),
        BRICK(vec3(11.,3.2,20.),vec3(0.,0.,1.),0,3),
    //Rest of first white layer + post bottom
    BRICK(vec3(11.,2.8,17.),vec3(0.,0.,1.),0,16),
    BRICK(vec3(11.,2.8,17.),vec3(1.,0.,0.),0,1)
);

const BRICK BrickArray1[NBricks]=BRICK[NBricks](
    BRICK(vec3(17.,2.8,17.),vec3(1.,0.,0.),0,17),
        BRICK(vec3(21.,2.8,11.),vec3(0.,0.,1.),0,18),
    //Window base + 2 round131 + Second white layer
    BRICK(vec3(11.,3.6,20.),vec3(0.,0.,1.),8,10),
        BRICK(vec3(10.,4.,20.),vec3(0.,0.,1.),10,31),
    BRICK(vec3(31.,2.8,11.),vec3(0.,0.,1.),10,61),
        BRICK(vec3(31.,4.,11.),vec3(0.,0.,1.),10,61),
    BRICK(vec3(30.,4.,11.),vec3(0.,0.,1.),0,16),
        BRICK(vec3(30.,4.,14.),vec3(0.,0.,1.),0,15),
        BRICK(vec3(30.,4.,16.),vec3(0.,0.,1.),0,20),
    BRICK(vec3(20.,4.,26.),vec3(1.,0.,0.),0,20),
        BRICK(vec3(10.,4.,26.),vec3(1.,0.,0.),0,20),
    BRICK(vec3(11.,4.,24.),vec3(0.,0.,1.),0,15),
    //Rest of second white layer + Post red
    BRICK(vec3(11.,4.,17.),vec3(0.,0.,1.),0,16), //1x3x3 near window
    BRICK(vec3(21.,4.,11.),vec3(0.,0.,1.),0,16),
        BRICK(vec3(21.,4.,14.),vec3(0.,0.,1.),0,17),
        BRICK(vec3(17.,4.,17.),vec3(1.,0.,0.),0,16),
    BRICK(vec3(11.,3.2,16.),vec3(1.,0.,0.),4,8),
    //Drain cross + third white layer
    BRICK(vec3(31.,5.2,13.),vec3(-1.,0.,0.),10,57), //Cross
        BRICK(vec3(30.,5.2,12.),vec3(-1.,0.,0.),0,0), //White 1x1x1
    BRICK(vec3(30.,5.2,13.),vec3(0.,0.,1.),0,15),
        BRICK(vec3(30.,5.2,15.),vec3(0.,0.,1.),0,18),
        BRICK(vec3(30.,5.2,21.),vec3(0.,0.,1.),0,18),
    BRICK(vec3(23.,5.2,26.),vec3(1.,0.,0.),0,18),
        BRICK(vec3(17.,5.2,26.),vec3(1.,0.,0.),0,18),
        BRICK(vec3(11.,5.2,26.),vec3(1.,0.,0.),0,18),
    BRICK(vec3(11.,5.2,24.),vec3(0.,0.,1.),0,16),
        BRICK(vec3(11.,5.2,18.),vec3(0.,0.,1.),0,15),
    //Post panels + post roof
    BRICK(vec3(13.,3.6,16.),vec3(0.,0.,1.),4,84),
        BRICK(vec3(11.,3.6,18.),vec3(0.,0.,-1.),4,84),
    BRICK(vec3(11.,4.8,16.),vec3(1.,0.,0.),4,8), //Red roof
        BRICK(vec3(11.,5.2,16.),vec3(1.,0.,0.),4,29),
        BRICK(vec3(10.,5.2,17.),vec3(1.,0.,0.),0,16),
    BRICK(vec3(17.,5.2,17.),vec3(1.,0.,0.),0,17), //White to the small window
        BRICK(vec3(21.,5.2,15.),vec3(0.,0.,1.),0,15),
        BRICK(vec3(21.,5.2,11.),vec3(0.,0.,1.),0,1),
    //Small window + 4th white layer
    BRICK(vec3(21.,5.2,13.),vec3(0.,0.,1.),1,85), //Small window
        BRICK(vec3(21.,6.4,15.),vec3(0.,0.,1.),0,17), //4x1x1
    BRICK(vec3(30.,6.4,13.),vec3(0.,0.,1.),0,16),
        BRICK(vec3(30.,6.4,16.),vec3(0.,0.,1.),0,20),
    BRICK(vec3(27.,6.4,26.),vec3(1.,0.,0.),0,16),
        BRICK(vec3(21.,6.4,26.),vec3(1.,0.,0.),0,18),
        BRICK(vec3(20.,6.4,27.),vec3(0.,0.,-1.),0,72), //Inverse slope
    //End of 4th white layer + big window
    BRICK(vec3(10.,6.4,26.),vec3(1.,0.,0.),0,20),
    BRICK(vec3(11.,6.4,24.),vec3(0.,0.,1.),0,15),
        BRICK(vec3(11.,4.,20.),vec3(0.,0.,1.),1,86), //Big window
            BRICK(vec3(10.4,4.4,20.1),vec3(0.,0.,1.),0,87),
            BRICK(vec3(10.4,7.4,23.65),vec3(-0.707,180.,-0.707),0,87),
        BRICK(vec3(11.,6.4,17.),vec3(0.,0.,1.),0,16),
    BRICK(vec3(11.,6.4,17.),vec3(1.,0.,0.),0,15),
        BRICK(vec3(17.,6.4,17.),vec3(1.,0.,0.),0,14),
        BRICK(vec3(19.,6.4,17.),vec3(0.,0.,1.),3,75),
        BRICK(vec3(19.,6.4,17.),vec3(1.,0.,0.),0,14),
    //Garage door
    BRICK(GarageRotP-GarageY*5.2,vec3(1.,30.,0.),4,5),
        BRICK(GarageRotP-GarageY*4.8,vec3(1.,30.,0.),4,16),
            BRICK(GarageRotP-GarageY*4.8-vec3(-5.,0.,0.),vec3(1.,30.,0.),4,16),
        BRICK(GarageRotP-GarageY*4.8-vec3(-4.,0.,0.),vec3(GarageY.x,-GarageY.z,GarageY.y),3,75),
            BRICK(GarageRotP-GarageY*4.8-vec3(-5.,0.,0.),vec3(GarageY.x,-GarageY.z,GarageY.y),3,75),
        BRICK(GarageRotP-GarageY*3.6-vec3(-5.,0.,0.)+vec3(GarageY.x,-GarageY.z,GarageY.y)*0.2,vec3(-1.,60.,0.),3,84),
    BRICK(GarageRotP-GarageY*3.6,vec3(1.,30.,0.),4,5),
        BRICK(GarageRotP-GarageY*3.2,vec3(1.,30.,0.),4,19),
    BRICK(GarageRotP-GarageY*2.,vec3(1.,30.,0.),4,5),
        BRICK(GarageRotP-GarageY*1.6,vec3(1.,30.,0.),4,19),
    BRICK(GarageRotP-GarageY*0.4,vec3(1.,30.,0.),4,5),
        BRICK(GarageRotP-vec3(-1.,0.,0.),vec3(1.,30.,0.),4,16),
            BRICK(GarageRotP-vec3(-4.,0.,0.),vec3(1.,30.,0.),4,16),
        BRICK(GarageRotP,vec3(1.,30.,0.),4,88),
            BRICK(GarageRotP-vec3(-7.,0.,0.),vec3(1.,30.,0.),4,88),
    BRICK(GarageRotP+GarageY*1.2,vec3(1.,30.,0.),4,33),
    //Garage join technic brick
    BRICK(vec3(20.,5.6,12.),vec3(1.,0.,0.),10,88),
        BRICK(vec3(29.,5.6,12.),vec3(1.,0.,0.),10,88),
    BRICK(vec3(20.,5.6,11.),vec3(1.,0.,0.),0,14),
        BRICK(vec3(29.,5.6,11.),vec3(1.,0.,0.),0,14),
        BRICK(vec3(30.,5.6,11.),vec3(1.,0.,0.),10,61),
            BRICK(vec3(30.,6.8,11.),vec3(1.,0.,0.),10,61),
    //2 2x1x1
    BRICK(vec3(21.,6.8,11.),vec3(0.,0.,1.),0,1),
        BRICK(vec3(21.,7.2,11.),vec3(0.,0.,1.),0,1),
    BRICK(vec3(30.,6.8,11.),vec3(0.,0.,1.),0,1),
        BRICK(vec3(30.,7.2,11.),vec3(0.,0.,1.),0,1),
    //Door
    BRICK(vec3(12.8,0.4,17.4),vec3(0.8,0.,-0.6),0,89),
    //Stairs
    BRICK(vec3(21.,7.6,18.),vec3(0.,0.,1.),1,5),
        BRICK(vec3(21.,8.,18.),vec3(0.,0.,1.),1,2),
            BRICK(vec3(21.,8.,21.),vec3(0.,0.,1.),1,2),
        BRICK(vec3(21.,7.6,25.),vec3(-1.,0.,0.),3,92),
            BRICK(vec3(21.,7.6,26.),vec3(-1.,0.,0.),3,92),
        BRICK(vec3(21.,8.4,18.),vec3(0.,0.,1.),1,5),
    //Rotated stairs
    BRICK(StairRotP-StairX*1.5-StairY*0.3,StairX,10,90),
        BRICK(StairRotP-StairX*1.5-StairY*0.3,vec3(0.,65.,1.),10,1),
        BRICK(StairRotP-StairX*2.5-StairY*0.7,StairX,10,8),
        BRICK(StairRotP-StairX*8.5+StairY*0.1,StairX,2,12),
            BRICK(StairRotP+vec3(0.,0.,2.)-StairX*1.5+StairY*0.5,vec3(0.,295.,-1.),3,84),
            BRICK(StairRotP+vec3(0.,0.,2.)-StairX*3.5+StairY*0.5,vec3(0.,295.,-1.),3,84),
            BRICK(StairRotP+vec3(0.,0.,2.)-StairX*5.5+StairY*0.5,vec3(0.,295.,-1.),3,84),
            BRICK(StairRotP+vec3(0.,0.,2.)-StairX*7.5+StairY*0.5,vec3(0.,295.,-1.),3,84),
    //5th white layer
    BRICK(vec3(30.,7.6,18.),vec3(0.,0.,1.),0,16),
        BRICK(vec3(30.,7.6,21.),vec3(0.,0.,1.),0,18),
    BRICK(vec3(23.,7.6,26.),vec3(1.,0.,0.),0,18),
        BRICK(vec3(17.,7.6,26.),vec3(1.,0.,0.),0,18),
        BRICK(vec3(11.,7.6,26.),vec3(1.,0.,0.),0,18),
    BRICK(vec3(11.,7.6,21.),vec3(0.,0.,1.),0,18),
        BRICK(vec3(11.,7.6,18.),vec3(0.,0.,1.),0,16),
    BRICK(vec3(10.,7.6,17.),vec3(1.,0.,0.),0,15),
        BRICK(vec3(18.,7.6,17.),vec3(1.,0.,0.),0,15),
        BRICK(vec3(20.,7.6,17.),vec3(1.,0.,0.),0,20),
    //Lamp
    BRICK(vec3(19.,6.6,17.2),vec3(0.,0.999,0.04471),3,60),
        BRICK(vec3(18.,7.6,16.8),vec3(0.,-180.999,0.04471),3,76),
        BRICK(vec3(17.5,6.,14.9),vec3(1.,0.,0.),3,93),
        BRICK(vec3(18.,4.8,15.4),vec3(1.,0.,0.),12,61),
        BRICK(vec3(18.,4.4,15.4),vec3(1.,0.,0.),3,60),
    //Blue over door + floor over garage
    BRICK(vec3(12.,7.6,18.),vec3(0.,0.,-1.),5,65),
        BRICK(vec3(15.,7.6,18.),vec3(0.,0.,-1.),5,65),
    BRICK(vec3(20.,7.6,11.),vec3(1.,0.,0.),0,13),
        BRICK(vec3(20.,7.6,13.),vec3(1.,0.,0.),0,13),
        BRICK(vec3(20.,7.6,15.),vec3(1.,0.,0.),0,13),
    //Yellow floor + removable roof base
    BRICK(vec3(20.,8.8,17.),vec3(1.,0.,0.),1,13),
        BRICK(vec3(20.,8.8,19.),vec3(1.,0.,0.),1,13),
        BRICK(vec3(20.,8.8,21.),vec3(1.,0.,0.),1,13),
        BRICK(vec3(20.,8.8,23.),vec3(1.,0.,0.),1,13),
        BRICK(vec3(20.,8.8,25.),vec3(1.,0.,0.),1,13),
    BRICK(vec3(14.,8.8,26.),vec3(1.,0.,0.),1,32),
        BRICK(vec3(13.,8.8,26.),vec3(1.,0.,0.),1,0),
        BRICK(vec3(11.,8.8,26.),vec3(1.,0.,0.),1,29),
    BRICK(vec3(14.,8.8,17.),vec3(1.,0.,0.),1,32),
        BRICK(vec3(13.,8.8,17.),vec3(1.,0.,0.),1,0),
        BRICK(vec3(11.,8.8,17.),vec3(1.,0.,0.),1,29),
    BRICK(vec3(11.,8.8,17.),vec3(0.,0.,1.),1,29),
        BRICK(vec3(11.,8.8,19.),vec3(0.,0.,1.),1,0),
        BRICK(vec3(11.,8.8,20.),vec3(0.,0.,1.),1,29),
        BRICK(vec3(11.,8.8,22.),vec3(0.,0.,1.),1,29)
);

const BRICK BrickArray2[NBricks]=BRICK[NBricks](
    BRICK(vec3(11.,8.8,24.),vec3(0.,0.,1.),1,0),
    BRICK(vec3(11.,8.8,25.),vec3(0.,0.,1.),1,29),
    //First layer on garage
    BRICK(vec3(21.,8.,11.),vec3(1.,0.,0.),0,24),
        BRICK(vec3(25.,8.,11.),vec3(1.,0.,0.),0,24),
    BRICK(vec3(21.,8.,16.),vec3(1.,0.,0.),4,19), //Red brick
    BRICK(vec3(21.,8.,14.),vec3(-1.,0.,0.),5,66),
        BRICK(vec3(21.,8.,17.),vec3(-1.,0.,0.),5,65),
        BRICK(vec3(29.,8.,10.),vec3(1.,0.,0.),5,66),
        BRICK(vec3(29.,8.,14.),vec3(1.,0.,0.),5,65),
    //First layer inner quad
    BRICK(vec3(21.,9.2,17.),vec3(0.,0.,1.),0,29),
        BRICK(vec3(21.,9.2,17.),vec3(1.,0.,0.),0,24),
        BRICK(vec3(25.,9.2,17.),vec3(1.,0.,0.),0,24),
    BRICK(vec3(30.,9.2,17.),vec3(0.,0.,1.),0,20),
        BRICK(vec3(29.,9.2,24.),vec3(0.,0.,1.),10,15), //Grey
    BRICK(vec3(26.,9.2,26.),vec3(1.,0.,0.),0,16),
        BRICK(vec3(22.,9.2,26.),vec3(1.,0.,0.),0,17),
        BRICK(vec3(22.,9.2,25.),vec3(0.,0.,1.),0,15),
        BRICK(vec3(21.,9.2,25.),vec3(0.,0.,1.),0,29),
    //Second layer on garage
    BRICK(vec3(22.,9.2,13.),vec3(-1.,0.,0.),5,65),
        BRICK(vec3(22.,9.2,17.),vec3(-1.,0.,0.),5,66),
        BRICK(vec3(28.,9.2,10.),vec3(1.,0.,0.),5,65),
        BRICK(vec3(28.,9.2,13.),vec3(1.,0.,0.),5,66),
    BRICK(vec3(22.,9.2,11.),vec3(1.,0.,0.),0,22),
        BRICK(vec3(26.,9.2,11.),vec3(1.,0.,0.),0,22),
        BRICK(vec3(24.,9.2,12.),vec3(0.,0.,-1.),3,91),
    BRICK(vec3(22.,9.2,16.),vec3(1.,0.,0.),0,18), //Whie brick on red
    //Second layer inner quad
    BRICK(vec3(31.,10.4,26.),vec3(0.,0.,1.),5,70),
        BRICK(vec3(23.,10.4,26.),vec3(0.,0.,1.),5,64),
    BRICK(vec3(29.,10.4,24.),vec3(0.,0.,1.),10,15), //Grey
    BRICK(vec3(30.,10.4,23.),vec3(0.,0.,1.),0,16), //White bricks
        BRICK(vec3(30.,10.4,18.),vec3(0.,0.,1.),0,16),
    BRICK(vec3(29.,10.4,18.),vec3(0.,0.,-1.),5,64), //Blue slope
    BRICK(vec3(21.,10.4,26.),vec3(0.,0.,-1.),0,72), //ISlope
        BRICK(vec3(22.,10.4,18.),vec3(0.,0.,1.),0,72),
    //Blue slopes + 2 SlopeCross
    BRICK(vec3(23.,10.4,12.),vec3(-1.,0.,0.),5,64),
        BRICK(vec3(23.,10.4,16.),vec3(-1.,0.,0.),5,66),
        BRICK(vec3(23.,10.4,18.),vec3(-1.,0.,0.),5,95),
            BRICK(vec3(27.,10.4,18.),vec3(0.,0.,-1.),5,95),
    BRICK(vec3(27.,10.4,10.),vec3(1.,0.,0.),5,64),
        BRICK(vec3(27.,10.4,12.),vec3(1.,0.,0.),5,66),
    //2 Islopes + 2 grey round131 + 2 white 6x3x1
    BRICK(vec3(24.,10.4,18.),vec3(0.,0.,1.),0,72),
        BRICK(vec3(27.,10.4,18.),vec3(0.,0.,1.),0,72),
    BRICK(vec3(24.,10.4,17.),vec3(0.,0.,1.),10,61),
        BRICK(vec3(27.,10.4,17.),vec3(0.,0.,1.),10,61),
    BRICK(vec3(24.,10.4,11.),vec3(0.,0.,1.),0,18),
        BRICK(vec3(27.,10.4,11.),vec3(0.,0.,1.),0,18),
    //2 white + some blue ceiling bricks + doubleslope
    BRICK(vec3(30.,11.6,23.),vec3(0.,0.,1.),0,15), //White bricks
        BRICK(vec3(30.,11.6,19.),vec3(0.,0.,1.),0,15),
    BRICK(vec3(28.,11.6,19.),vec3(0.,0.,-1.),5,65), //Blue slope near garage
        BRICK(vec3(26.,11.6,19.),vec3(0.,0.,-1.),5,95), //Blue slopecross
    BRICK(vec3(31.,11.6,25.),vec3(0.,0.,1.),5,64), //Blue slope behind house
    BRICK(vec3(21.,11.6,19.),vec3(0.,0.,-1.),5,77), //Double slope
    //Inner quad window + one blue ceiling
    BRICK(vec3(29.,11.6,25.),vec3(0.,0.,1.),5,70),
    BRICK(vec3(29.,10.4,23.),vec3(0.,0.,-1.),1,85), //Window
    BRICK(vec3(23.,11.6,19.),vec3(1.,0.,0.),0,17),
    //Window over garage + some other bricks
    BRICK(vec3(21.,11.6,25.),vec3(0.,0.,-1.),0,72), //White ISlope
        BRICK(vec3(22.,11.6,19.),vec3(0.,0.,1.),0,72),
    BRICK(vec3(28.,11.6,25.),vec3(0.,0.,-1.),10,72), //Grey ISlope
    BRICK(vec3(24.,9.6,11.),vec3(1.,0.,0.),1,85), //Window
        BRICK(vec3(24.,12.,11.),vec3(1.,0.,0.),0,1),
        BRICK(vec3(24.,12.4,11.),vec3(1.,0.,0.),0,1),
    BRICK(vec3(24.,11.6,19.),vec3(-1.,0.,0.),5,95),
    //Only blue ceiling
    BRICK(vec3(24.,11.6,14.),vec3(-1.,0.,0.),5,66), //Directly over garage
        BRICK(vec3(24.,11.6,17.),vec3(-1.,0.,0.),5,65),
        BRICK(vec3(26.,11.6,10.),vec3(1.,0.,0.),5,66),
        BRICK(vec3(26.,11.6,14.),vec3(1.,0.,0.),5,65),
    BRICK(vec3(23.,12.8,24.),vec3(0.,0.,1.),5,64), //Behind house
        BRICK(vec3(31.,12.8,24.),vec3(0.,0.,1.),5,70),
    //Two white islopes + grey islope + blue ceiling
    BRICK(vec3(21.,12.8,24.),vec3(0.,0.,-1.),0,72), //White ISlope
        BRICK(vec3(22.,12.8,20.),vec3(0.,0.,1.),0,72),
    BRICK(vec3(28.,12.8,24.),vec3(0.,0.,-1.),10,72), //Grey ISlope
    BRICK(vec3(27.,12.8,20.),vec3(0.,0.,-1.),5,66), //Blue ceiling over garage
        BRICK(vec3(21.,12.8,20.),vec3(0.,0.,-1.),5,64),
    BRICK(vec3(29.,12.8,24.),vec3(0.,0.,-1.),0,17),
    BRICK(vec3(25.,12.8,20.),vec3(-1.,0.,0.),5,95), //Blue slopecross
        BRICK(vec3(25.,12.8,20.),vec3(0.,0.,-1.),5,95),
    //Blue ceiling that covers garage + white 2x3x1 over inner quad window
    BRICK(vec3(25.,12.8,18.),vec3(-1.,0.,0.),5,70),
        BRICK(vec3(25.,12.8,10.),vec3(1.,0.,0.),5,70),
    BRICK(vec3(30.,14.,21.),vec3(0.,0.,1.),0,15), //White 2x3x1
    BRICK(vec3(31.,14.,23.),vec3(0.,0.,1.),5,64), //Blue behind
        BRICK(vec3(29.,14.,23.),vec3(0.,0.,1.),5,70),
    //Grey and blue ceiling on almost final ceiling height
    BRICK(vec3(28.,14.,23.),vec3(0.,0.,-1.),10,72), //Grey ISlope
    BRICK(vec3(22.,14.,21.),vec3(0.,0.,1.),0,15), //White 2x3x1
    BRICK(vec3(29.,14.,21.),vec3(0.,0.,-1.),5,64), //Blue forward
        BRICK(vec3(21.,14.,21.),vec3(0.,0.,-1.),5,70),
    //Grey disk-layer on top of garage
    BRICK(vec3(26.,14.,10.),vec3(0.,0.,1.),10,9),
        BRICK(vec3(26.,14.,16.),vec3(0.,0.,1.),10,9),
    BRICK(vec3(24.,14.,13.),vec3(1.,0.,0.),10,60),
        BRICK(vec3(25.,14.,13.),vec3(1.,0.,0.),10,60),
        BRICK(vec3(25.,14.,14.),vec3(1.,0.,0.),10,60),
        BRICK(vec3(25.,14.,15.),vec3(1.,0.,0.),10,60),
    BRICK(vec3(25.,14.,16.),vec3(-1.,0.,0.),8,91), //Disk holder
    BRICK(LampRotP+LampZ*2.2,-LampZ-vec3(0.,180.,0.),3,92), //Lamp over garage
        BRICK(LampRotP+LampZ*2.2+LampY*0.8,-LampZ-vec3(0.,180.,0.),12,74),
    //Disk
    BRICK(DiskRotP+DiskX*2.2,DiskX+vec3(0.,180.,0.),3,92),
        BRICK(DiskRotP+DiskX*2.2,DiskX+vec3(0.,180.,0.),10,60), //1x1x1 round
        BRICK(DiskRotP+DiskX*1.2+DiskY*0.8+vec3(0.,0.,1.),DiskX+vec3(0.,180.,0.),0,94), //Disk
        BRICK(DiskRotP+DiskX*3.2+DiskY*1.6-vec3(0.,0.,1.),-DiskX-vec3(0.,180.,0.),10,76), 
            BRICK(DiskRotP+DiskX*2.2+DiskY*2.,DiskX+vec3(0.,180.,0.),10,60),
    //Top slopes on inner quad
    BRICK(vec3(21.,15.2,22.),vec3(0.,0.,-1.),5,64), //Blue forward
        BRICK(vec3(23.,15.2,22.),vec3(0.,0.,-1.),5,70),
    BRICK(vec3(23.,15.2,22.),vec3(0.,0.,1.),5,64), //Blue behind
        BRICK(vec3(31.,15.2,22.),vec3(0.,0.,1.),5,70),
    //Doubelslope ceiling on garage + grey on inner quad
    BRICK(vec3(24.,14.4,18.),vec3(1.,0.,0.),5,96),
        BRICK(vec3(24.,14.4,14.),vec3(1.,0.,0.),5,80),
        BRICK(vec3(24.,14.4,10.),vec3(1.,0.,0.),5,80),
    BRICK(vec3(21.,16.4,21.),vec3(1.,0.,0.),10,9),
        BRICK(vec3(24.,16.4,21.),vec3(1.,0.,0.),10,9),
        BRICK(vec3(30.,16.4,21.),vec3(1.,0.,0.),10,7),
    //Doubleslope ceiling on inner quad
    BRICK(vec3(22.,16.8,21.),vec3(0.,0.,1.),5,77),
        BRICK(vec3(26.,16.8,21.),vec3(0.,0.,1.),5,80),
        BRICK(vec3(27.,16.8,21.),vec3(0.,0.,1.),5,77),
        BRICK(vec3(31.,16.8,21.),vec3(0.,0.,1.),5,77),
    //Chimney
    BRICK(vec3(28.,16.4,21.),vec3(1.,0.,0.),1,22),
        BRICK(vec3(27.,16.4,21.),vec3(1.,0.,0.),10,21),
    BRICK(vec3(27.,17.6,21.),vec3(1.,0.,0.),1,22),
        BRICK(vec3(29.,17.6,21.),vec3(1.,0.,0.),10,21),
    BRICK(vec3(28.,18.8,21.),vec3(1.,0.,0.),8,62),
        BRICK(vec3(28.,18.8,22.),vec3(1.,0.,0.),8,62),
    //Removable ceiling - basis
    BRICK(vec3(10.,9.2,25.),vec3(1.,0.,0.),0,13), //10x1x2
        BRICK(vec3(10.,9.2,17.),vec3(1.,0.,0.),0,13),
        BRICK(vec3(11.,9.2,19.),vec3(0.,0.,1.),0,4),
    BRICK(vec3(11.,9.6,17.),vec3(0.,0.,1.),0,6), //1x1x10
    BRICK(vec3(11.,9.6,26.),vec3(1.,0.,0.),0,6), //10x1x1
        BRICK(vec3(11.,9.6,17.),vec3(1.,0.,0.),0,6),
    BRICK(vec3(17.,9.6,25.),vec3(1.,0.,0.),1,2), //Yellow 3x1x1
        BRICK(vec3(17.,9.6,18.),vec3(1.,0.,0.),1,2),
    BRICK(vec3(11.,9.6,18.),vec3(1.,0.,0.),10,1)
);

const BRICK BrickArray3[NBricks]=BRICK[NBricks](
    //White layer
    BRICK(vec3(17.,10.,25.),vec3(1.,0.,0.),0,10), //White 4x1x2
        BRICK(vec3(17.,10.,17.),vec3(1.,0.,0.),0,10),
    BRICK(vec3(11.,10.,26.),vec3(1.,0.,0.),0,4), //6x1x1
    BRICK(vec3(11.,10.,24.),vec3(0.,0.,1.),0,2), //1x1x3
        BRICK(vec3(11.,10.,17.),vec3(0.,0.,1.),0,2),
    BRICK(vec3(12.,10.,17.),vec3(0.,0.,1.),0,1),
        BRICK(vec3(13.,10.,17.),vec3(0.,0.,1.),0,1),
    //Window bases + blue ceiling behind + 2 1x3x1
    BRICK(vec3(11.,10.,20.),vec3(0.,0.,1.),8,10),
        BRICK(vec3(10.,10.4,20.),vec3(0.,0.,1.),10,31),
    BRICK(vec3(13.,10.,16.),vec3(1.,0.,0.),8,10),
        BRICK(vec3(13.,10.4,16.),vec3(1.,0.,0.),10,31),
    BRICK(vec3(21.,10.4,26.),vec3(0.,0.,1.),5,70), //Blue ceiling behind
        BRICK(vec3(13.,10.4,26.),vec3(0.,0.,1.),5,66),
    BRICK(vec3(20.,10.4,18.),vec3(1.,0.,0.),0,14), //1x3x1
        BRICK(vec3(20.,10.4,25.),vec3(1.,0.,0.),0,14),
    //White ISlopes + some white bricks
    BRICK(vec3(20.,10.4,18.),vec3(0.,0.,1.),0,72),
        BRICK(vec3(18.,10.4,18.),vec3(0.,0.,1.),0,72),
        BRICK(vec3(13.,10.4,18.),vec3(0.,0.,1.),0,72),
    BRICK(vec3(19.,10.4,26.),vec3(0.,0.,-1.),0,72),
    BRICK(vec3(11.,10.4,18.),vec3(0.,0.,1.),0,15), //White 2x3x1
        BRICK(vec3(11.,10.4,24.),vec3(0.,0.,1.),0,15),
    BRICK(vec3(18.,10.4,17.),vec3(0.,0.,1.),0,14), //White 1x3x1
        BRICK(vec3(13.,10.4,17.),vec3(0.,0.,1.),0,14),
    //4 blue ceilings
    BRICK(vec3(9.,10.4,18.),vec3(0.,0.,-1.),5,65), //Blue ceiling forward
        BRICK(vec3(18.,10.4,18.),vec3(0.,0.,-1.),5,65),
    BRICK(vec3(13.,11.6,25.),vec3(0.,0.,1.),5,66), //Blue ceiling behind
        BRICK(vec3(21.,11.6,25.),vec3(0.,0.,1.),5,66),
    //White bricks second layer
    BRICK(vec3(18.,11.6,17.),vec3(0.,0.,1.),0,15), //White 1x3x1
        BRICK(vec3(13.,11.6,17.),vec3(0.,0.,1.),0,15),
    BRICK(vec3(11.,11.6,19.),vec3(0.,0.,1.),0,14),
        BRICK(vec3(11.,11.6,24.),vec3(0.,0.,1.),0,14),
    BRICK(vec3(20.,11.6,19.),vec3(0.,0.,1.),0,18),
    //Third layer - blue ceilings and white ISlopes
    BRICK(vec3(9.,11.6,19.),vec3(0.,0.,-1.),5,65), //Blue ceiling forward
        BRICK(vec3(18.,11.6,19.),vec3(0.,0.,-1.),5,65),
    BRICK(vec3(13.,12.8,24.),vec3(0.,0.,1.),5,66), //Blue ceiling behind
        BRICK(vec3(21.,12.8,24.),vec3(0.,0.,1.),5,66),
    BRICK(vec3(18.,11.6,19.),vec3(0.,0.,1.),0,72),
        BRICK(vec3(13.,11.6,19.),vec3(0.,0.,1.),0,72),
    //Third layer white 1x3x4 + crossed slopes
    BRICK(vec3(20.,12.8,20.),vec3(0.,0.,1.),0,17),
    BRICK(vec3(9.,12.8,20.),vec3(0.,0.,-1.),5,64), //Blue ceiling forward
        BRICK(vec3(19.,12.8,20.),vec3(0.,0.,-1.),5,64),
    BRICK(vec3(13.,12.8,20.),vec3(-1.,0.,0.),5,95),
        BRICK(vec3(17.,12.8,20.),vec3(0.,0.,-1.),5,95),
    //2 Windows
    BRICK(vec3(11.,10.4,20.),vec3(0.,0.,1.),1,86), //Big window
        BRICK(vec3(10.4,10.8,20.1),vec3(0.,0.,1.),0,87),
        BRICK(vec3(10.4,13.8,23.9),vec3(0.,180.,-1.),0,87),
    BRICK(vec3(17.,10.4,18.),vec3(-1.,0.,0.),1,86),
        BRICK(vec3(16.9,10.8,17.4),vec3(-1.,0.,0.),0,87),
        BRICK(vec3(13.1,13.8,17.4),vec3(1.,180.,0.),0,87),
    //Blue ceilings + arc
    BRICK(vec3(13.,14.,23.),vec3(0.,0.,1.),5,66), //Blue ceiling behind
        BRICK(vec3(21.,14.,23.),vec3(0.,0.,1.),5,66),
    BRICK(vec3(13.,12.8,18.),vec3(-1.,0.,0.),5,64), //Blue ceiling forward near window
        BRICK(vec3(17.,12.8,16.),vec3(1.,0.,0.),5,64),
    BRICK(vec3(18.,12.8,21.),vec3(-1.,0.,0.),10,18), //Grey "arc"
    //Two 10x3x1 white bricks
    BRICK(vec3(10.,14.,21.),vec3(1.,0.,0.),0,20),
        BRICK(vec3(10.,14.,22.),vec3(1.,0.,0.),0,20),
    //Blue ceiling forward + slopecross
    BRICK(vec3(9.,14.,21.),vec3(0.,0.,-1.),5,65), //Blue ceiling forward
        BRICK(vec3(18.,14.,21.),vec3(0.,0.,-1.),5,65),
    BRICK(vec3(14.,14.,21.),vec3(-1.,0.,0.),5,95), //SlopeCross
        BRICK(vec3(16.,14.,21.),vec3(0.,0.,-1.),5,95),
    //Forward window ceiling + 2x3x1 on top
    BRICK(vec3(16.,14.,18.),vec3(-1.,0.,0.),0,15),
    BRICK(vec3(14.,14.,19.),vec3(-1.,0.,0.),5,65), //Blue ceiling forward near window
        BRICK(vec3(16.,14.,16.),vec3(1.,0.,0.),5,65),
    //Oblique window
    BRICK(vec3(13.,11.6,23.),vec3(1.,0.,0.),0,97),
    //Ceiling behind + SlopeCross
    BRICK(vec3(11.,15.2,22.),vec3(0.,0.,1.),5,64),
        BRICK(vec3(19.,15.2,22.),vec3(0.,0.,1.),5,70),
        BRICK(vec3(21.,15.2,22.),vec3(0.,0.,1.),5,64),
    BRICK(vec3(15.,15.2,22.),vec3(-1.,0.,0.),5,95), //SlopeCross
        BRICK(vec3(15.,15.2,22.),vec3(0.,0.,-1.),5,95),
    //Rest of the slopes
    BRICK(vec3(9.,15.2,22.),vec3(0.,0.,-1.),5,66), //Blue ceiling forward
        BRICK(vec3(17.,15.2,22.),vec3(0.,0.,-1.),5,66),
    BRICK(vec3(15.,15.2,20.),vec3(-1.,0.,0.),5,66), //Blue ceiling forward near window
        BRICK(vec3(15.,15.2,16.),vec3(1.,0.,0.),5,66),
    //Grey layer
    BRICK(vec3(18.,16.4,21.),vec3(1.,0.,0.),10,9),
        BRICK(vec3(15.,16.4,21.),vec3(1.,0.,0.),10,9),
        BRICK(vec3(12.,16.4,21.),vec3(1.,0.,0.),10,9),
        BRICK(vec3(9.,16.4,21.),vec3(1.,0.,0.),10,9),
    BRICK(vec3(14.,16.4,21.),vec3(0.,0.,-1.),10,9),
        BRICK(vec3(14.,16.4,18.),vec3(0.,0.,-1.),10,8),
    //DoubeSlopes on top
    BRICK(vec3(14.,16.8,20.),vec3(1.,0.,0.),5,96), //InverseDoubleSlope
        BRICK(vec3(14.,16.8,16.),vec3(1.,0.,0.),5,80),
    BRICK(vec3(13.,16.8,21.),vec3(0.,0.,1.),5,80),
        BRICK(vec3(17.,16.8,21.),vec3(0.,0.,1.),5,80),
        BRICK(vec3(21.,16.8,21.),vec3(0.,0.,1.),5,80),
    //Tree
    BRICK(vec3(1.,0.,19.),vec3(1.,0.,0.),2,61),
        BRICK(vec3(1.,1.2,19.),vec3(1.,0.,0.),2,61),
        BRICK(vec3(1.,2.4,19.),vec3(1.,0.,0.),2,61),
        BRICK(vec3(0.5,3.6,18.5),vec3(1.,0.,0.),9,83),
    BRICK(vec3(0.5,4.8,19.5),vec3(0.,0.,-1.),9,72), //Green ISlopes
        BRICK(vec3(1.5,4.8,18.5),vec3(1.,0.,0.),9,72),
        BRICK(vec3(2.5,4.8,19.5),vec3(0.,0.,1.),9,72),
        BRICK(vec3(1.5,4.8,20.5),vec3(-1.,0.,0.),9,72),
    BRICK(vec3(1.5,6.,19.5),vec3(-1.,0.,0.),9,71), //Slope 331
        BRICK(vec3(1.5,6.,19.5),vec3(0.,0.,-1.),9,71),
        BRICK(vec3(1.5,6.,19.5),vec3(1.,0.,0.),9,71),
        BRICK(vec3(1.5,6.,19.5),vec3(0.,0.,1.),9,71),
    BRICK(vec3(1.5,6.,17.5),vec3(0.,0.,1.),9,14), //1x3x1
        BRICK(vec3(3.5,6.,18.5),vec3(0.,0.,1.),9,14),
        BRICK(vec3(2.5,6.,20.5),vec3(0.,0.,1.),9,14),
        BRICK(vec3(0.5,6.,19.5),vec3(0.,0.,1.),9,14),
    BRICK(vec3(-1.5,5.6,18.5),vec3(1.,0.,0.),4,60), //Apples
        BRICK(vec3(1.5,5.6,16.5),vec3(1.,0.,0.),4,60),
        BRICK(vec3(3.5,5.6,19.5),vec3(1.,0.,0.),4,60),
        BRICK(vec3(0.5,5.6,21.5),vec3(1.,0.,0.),4,60),
    //Post
    BRICK(vec3(12.,4.,15.5),vec3(0.42,0.,0.9075241),0,29),
        BRICK(vec3(12.9,4.4,15.5),vec3(-0.42,0.,0.9075241),0,29),
    
    
    
    
    //Unused bricks (22 st)
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(21.,0.,12.),vec3(1.,0.,0.),10,29)
);

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