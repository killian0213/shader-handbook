// Common (common) — LEGO Denoising by Mathis
// https://www.shadertoy.com/view/msG3zG

//Settings
const float FOV = radians(85.);
const vec3 SkyLight = vec3(0.6,0.8,1.)*0.5;
const vec3 SunLight = vec3(1.,0.5,0.25)*5.;
const float SunCR = 0.05;
//#define SecondBounce

//Other vars
const float LightCoeff = 8.;
const float ILightCoeff = 1./LightCoeff;
const float VarCoeff = 16.;
const float RefMaterial = 0.075;
const int BuildFrames = 7;
const float CFOV = tan(FOV*0.5);
const float PI = 3.141592653;
const float HPI = PI*0.5;
const float IPI = 1./PI;
const float PI2 = PI*2.;
const float IPI2 = 0.5/PI;
const float ToRadians = PI/180.;
const float I3 = 1./3.;
const float I16 = 1./16.;
const float I32 = 1./32.;
const float I64 = 1./64.;
const float I128 = 1./128.;
const float I256 = 1./256.;
const float I300 = 1./300.;
const float I512 = 1./512.;
const float I1024 = 1./1024.;
const float I2048 = 1./2048.;
const vec2 eps = vec2(0.0025,0.);
//Bricks
const vec3 LEGOObliqueSlope = normalize(vec3(0.,-3.,-3.4));
const vec3 LEGOSlope331 = normalize(vec3(0.9,2.,0.));
const vec3 LEGOSlope = normalize(vec3(0.9,1.,0.));
const vec3 LEGOISlope = normalize(vec3(0.9,-1.,0.));
const vec3 LEGOOSlope = normalize(vec3(3.5/6.,1.,0.));
//RES
#define RES iChannelResolution[0].xy
#define IRES (1./iChannelResolution[0].xy)
#define ASPECT vec2(RES.x/RES.y,1.)

const vec2 SSOffsets[16] = vec2[16](vec2(0.),vec2(-0.4,-0.4),vec2(0.,0.2),vec2(0.15,-0.4),vec2(-0.4,-0.15),
                                    vec2(0.15,0.4),vec2(-0.2,-0.2),vec2(-0.4,0.4),vec2(0.4,0.15),vec2(0.2,-0.2),
                                    vec2(0.4,0.4),vec2(-0.4,0.15),vec2(0.4,-0.15),
                                    vec2(-0.15,0.4),vec2(0.4,-0.4),vec2(-0.15,-0.4));

struct HIT { float D; vec3 N; vec3 C; vec3 E; };
struct BRICK { vec3 P; vec3 Q; int C; int I; };

//SKY
vec3 SampleSky(vec3 d, vec3 sd, float Time) {
    return SkyLight*(1.-0.5*d.y)*(d.y*0.5+0.5);
}

//SDF
float DFBox(vec3 p, vec3 b) {
    vec3 d = abs(p-b*0.5)-b*0.5;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float DFBoxC(vec3 p, vec3 b) {
    vec3 d = abs(p)-b;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float DFBox(vec2 p, vec2 b) {
    vec2 d = abs(p-b*0.5)-b*0.5;
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}

float DFBoxC(vec2 p, vec2 b) {
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

float DFCylinder(vec3 p, float r, float h) {
    vec2 d = vec2(length(p.xz)-r,abs(p.y)-h);
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}


float DFPlane(vec3 p, vec3 p0, vec3 p1, vec3 p2) {
    //Intersects a plane
    vec3 Normal = normalize(cross(p1-p0,p2-p0));
    vec3 tp = vec3(dot(p-p0,normalize(p1-p0)),dot(p-p0,normalize(p2-p0)),dot(p-p0,Normal));
    return DFBox(tp-vec3(0.,0.,-0.005),vec3(length(p1-p0),length(p2-p0),0.01));
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
    O = ((abs(N.y)<=0.999)?normalize(cross(N,vec3(0.,1.,0.))):vec3(1.,0.,0.));
    return normalize(cross(O,N));
}

vec3 RandSample(vec2 v) {
    float r=sqrt(1.-v.x*v.x);
    float phi=2.*3.14159*v.y;
    return vec3(cos(phi)*r,sin(phi)*r,v.x);
}

vec3 RandSampleCos(vec2 v) {
    float theta=sqrt(v.x);
    float phi=2.*3.14159*v.y;
    float x=theta*cos(phi);
    float z=theta*sin(phi);
    return vec3(x,z,sqrt(max(0.,1.-v.x)));
}

vec3 SchlickFresnel(vec3 r0, float angle) {
    //Schlick Fresnel approximation
    return r0+(1.-r0)*pow(1.-angle,5.);
}

vec3 ARand23(vec2 uv) {
    //Analytic random
    return fract(sin(uv.x*uv.y)*vec3(403.125,486.125,513.432)+cos(dot(uv,vec2(13.18273,51.2134)))*vec3(173.137,261.23,203.127));
}

float ARand21(vec2 uv) {
    //Analytic random
    return fract(sin(uv.x*uv.y)*403.125+cos(dot(uv,vec2(13.18273,51.2134)))*173.137);
}

vec2 ABox(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t1 = min(tMin,tMax);
    vec3 t2 = max(tMin,tMax);
    return vec2(max(max(t1.x,t1.y),t1.z),min(min(t2.x,t2.y),t2.z));
}

vec2 ABoxfarNormal(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin=(bmin-origin)*dir;
    vec2 tMax=(bmax-origin)*dir;
    vec2 t2=max(tMin,tMax);
    vec2 signdir = -(max(vec2(0.),sign(dir))*2.-1.);
    if (t2.x<t2.y) return vec2(signdir.x,0.);
    else return vec2(0.,signdir.y);
}

vec2 ABoxNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax, out vec3 N) {
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

//Non-optimal vec2/vec3 to float functions
vec3 FloatToVec3(float v) {
    float x = fract(v);
    float z = floor(v*I300);
    float y = floor(v-z*300.)*I300;
    return vec3(x,y,z*I300);
}

float Vec3ToFloat(vec3 v) {
    return min(v.x,0.998)+min(299.,floor(v.y*300.+0.5))+floor(v.z*300.+0.5)*300.;
}

vec2 FloatToVec2(float v) {
    return vec2((floor(fract(v)*2048.)+0.5)*I2048,(floor(v)+0.5)*I2048);
}

float Vec2ToFloat(vec2 v) {
    return min(v.x,0.999)+min(floor(v.y*2048.),2048.);
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
        float tmpLine = DFLine(vec3(p.x-clamp(floor(p.x-0.5),0.,BSize.x-2.)-0.5,p.yz),vec3(0.5,-1.,1.),vec3(0.5,1.,1.));
        d = min(d,max(max(max(tmpLine-0.407,-tmpLine+0.3),p.y-(BSize.y-0.45)),-p.y));
    } else if (BSize.x>1.5) {
        float tmpLine = DFLine(vec3(p.x-clamp(floor(p.x-0.5),0.,BSize.x-2.)-0.5,p.yz),vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5));
        d = min(d,max(max(max(tmpLine-0.2,-tmpLine+0.1),p.y-(BSize.y-0.45)),-p.y));
    }
    vec3 StudPos = vec3(clamp(floor(p.x),0.,BSize.x-1.),BSize.y-0.4,clamp(floor(p.z),0.,BSize.z-1.));
    d = max(d,-max(DFLine(p-StudPos,vec3(0.5,-1.,0.5),vec3(0.5,-0.05,0.5))-0.15,p.y-1.19)); //Hole under stud
    d = min(d,DFStud(p-StudPos)); //Studs
    return d;
}

float DFBrick_NoStud(vec3 p, vec3 BSize) {
    float d = DFBox(p-vec3(0.04),BSize-vec3(0.08,0.48,0.08))-0.04;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),BSize-vec3(0.4,-0.4,0.4)));
    if (BSize.x>1.5) {
        float tmpLine = DFLine(vec3(p.x-clamp(floor(p.x-0.5),0.,BSize.x-2.)-0.5,p.yz),vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5));
        d = min(d,max(max(max(tmpLine-0.2,-tmpLine+0.1),p.y-(BSize.y-0.45)),-p.y));
    }
    return d;
}

float DFPanelWall(vec3 p, vec3 BSize) {
    float d = DFBox(p-vec3(0.04),vec3(BSize.x-0.08,0.32,BSize.z-0.08));
    d = min(d,DFBox(p-vec3(0.04),vec3(BSize.x-0.08,BSize.y-0.08,0.12)));
    d = min(d,DFBox(p-vec3(0.04,BSize.y-0.16,0.04),vec3(BSize.x-0.08,0.12,BSize.z-0.08)));
    return d-0.04;
}

float DFGrate(vec3 p) {
    float d = DFBox(p-vec3(0.02),vec3(1.96,0.36,0.96))-0.02;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),vec3(1.6,1.25,0.6)));
    d = max(d,-DFBox(vec3(p.x+2.,p.y-0.2,fract(p.z*2.5)*0.4-0.2),vec3(8.,1.,0.2)));
    return d;
}

float DFRound111(vec3 p) {
    float LineDF = DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5));
    float d = -smin(smin(-LineDF+0.5,-p.y+0.4,0.04),p.y-0.3,0.015);
    d = min(d,max(max(max(LineDF-0.397,-LineDF+0.305),p.y-0.35),-p.y));
    d = max(d,-max(LineDF-0.15,p.y-0.39));
    d = min(d,DFStud(vec3(p.x,p.y-0.4,p.z))); //Stud
    return d;
}

float DFRound131(vec3 p) {
    float LineDF = DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5));
    float d = max(max(LineDF-0.397,p.y-0.35),-p.y);
    d = min(d,max(-smin(-LineDF+0.48,-p.y+1.2,0.05),-p.y+0.2));
    //Stud
    d = smin(d,max(-smin(-LineDF+0.3,-p.y+1.4,0.07),-p.y+1.2),0.07);
    d = -smin(-d,LineDF-0.2,0.07);
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
    d = max(d,-min(DFLine(p,vec3(0.5,0.7,0.5),vec3(-2.,0.7,0.5))-0.2,DFBox(p-vec3(0.3,-1.,0.2),vec3(0.5,1.5,0.6))));
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

float DFPanel(vec3 p) {
    float d = DFBox(p-vec3(0.04),vec3(1.92,0.32,0.92))-0.04;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),vec3(1.6,1.2,0.6)));
    d = min(d,DFBox(p-vec3(0.05,0.05,0.05),vec3(1.9,1.1,0.))-0.05);
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
    float d = DFBox(p-vec3(0.48,0.42,0.02),vec3(3.46,5.16,0.16))-0.02;
    //Ornament
    d = -smin(-d,DFBox(p-vec3(0.75,0.6,-1.),vec3(2.5,2.6,1.1)),0.1);
    d = min(d,DFBox(p-vec3(1.15,1.,0.),vec3(1.7,1.8,0.15)));
    //Window
    d = -smin(-d,DFBox(p-vec3(0.75,3.75,-1.),vec3(2.5,1.4,1.1)),0.1);
    //Handle
    d = min(d,DFLine(p,vec3(3.5,3.4,0.),vec3(3.2,3.4,0.))-0.15);
    //Vertical cylinder
    d = min(d,max(max(DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,10.,0.5))-0.5,p.y-5.6),-p.y));
    return d;
}


//BrickDim array
float BrickADim[7]=float[7](1.,2.,3.,4.,6.,8.,10.);
vec3 BrickDim[44]=vec3[44](
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
    vec3(2.,2.4,1.), //DFPanelWall H=2, x=2
    vec3(2.,3.6,1.), //DFPanelWall H=3, x=2
    vec3(3.,3.6,1.) //DFPanelWall H=3, x=3
);

//Colors: //White,LightBlue,Orange,Black,Red,Blue,Beige,Brown,LightBlack,LightGreen,Grey,DarkGrey,TrueYellow
const vec3 BrickColorArray[13] = vec3[13](vec3(0.9),vec3(0.3,0.55,0.85),vec3(0.8,0.35,0.2),vec3(0.05),
    vec3(0.99,0.05,0.05),vec3(0.05,0.1,0.95),vec3(0.7,0.6,0.1),vec3(0.4,0.1,0.03),
    vec3(0.1),vec3(0.15,0.99,0.15),vec3(0.45),vec3(0.25),vec3(1.,1.,0.1)
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
const BRICK BrickArray0[NBricks]=BRICK[NBricks](
    //Floor
        BRICK(vec3(0.,0.,0.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,2.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,4.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,6.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,8.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,10.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,12.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,14.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,16.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,18.),vec3(1.,0.,0.),0,12),
        BRICK(vec3(0.,0.,20.),vec3(1.,0.,0.),0,5),
    
    //Wall H=1
        BRICK(vec3(0.,0.4,0.),vec3(1.,0.,0.),0,5), //Back
        BRICK(vec3(1.,0.4,1.),vec3(0.,0.,1.),0,5), //Behind head
            BRICK(vec3(1.,0.4,9.),vec3(0.,0.,1.),0,5),
            BRICK(vec3(1.,0.4,17.),vec3(0.,0.,1.),0,3),
        BRICK(vec3(8.,0.4,1.),vec3(0.,0.,1.),0,3), //Door wall
            BRICK(vec3(8.,0.4,9.),vec3(0.,0.,1.),0,5),
            BRICK(vec3(8.,0.4,17.),vec3(0.,0.,1.),0,3),
        BRICK(vec3(1.,0.4,20.),vec3(1.,0.,0.),0,4), //Front
        //Head H=1
        BRICK(vec3(1.,0.4,4.),vec3(1.,0.,0.),0,2),
            BRICK(vec3(1.,0.4,9.),vec3(1.,0.,0.),0,2),
    
    //Doors H=1
        BRICK(vec3(4.,0.4,5.),vec3(0.,0.,1.),0,89), //Head door
            //BRICK(vec3(3.9,0.4,4.85),vec3(sin(0.3),0.,cos(0.3)),0,89), //Head door (rotated)
        BRICK(vec3(8.,0.4,5.),vec3(0.,0.,1.),0,89), //Entrance door
    
    //Wall H=2
        BRICK(vec3(1.,0.8,0.),vec3(1.,0.,0.),11,4),
        BRICK(vec3(1.,0.8,0.),vec3(0.,0.,1.),11,5), //Behind head
            BRICK(vec3(1.,0.8,8.),vec3(0.,0.,1.),11,5),
            BRICK(vec3(1.,0.8,16.),vec3(0.,0.,1.),11,3),
        BRICK(vec3(0.,0.8,20.),vec3(1.,0.,0.),11,5), //Front
        BRICK(vec3(8.,0.8,0.),vec3(0.,0.,1.),11,3), //Door wall
            BRICK(vec3(8.,0.8,4.),vec3(0.,0.,1.),11,0),
            BRICK(vec3(8.,0.8,9.),vec3(0.,0.,1.),11,5),
            BRICK(vec3(8.,0.8,17.),vec3(0.,0.,1.),11,2),
        //Head H=2
        BRICK(vec3(1.,0.8,4.),vec3(1.,0.,0.),11,2),
            BRICK(vec3(1.,0.8,9.),vec3(1.,0.,0.),11,2),
    
    //Wall panels
        BRICK(vec3(1.,1.2,0.),vec3(1.,0.,0.),0,98), //Back
            BRICK(vec3(3.,1.2,0.),vec3(1.,0.,0.),0,98),
            BRICK(vec3(5.,1.2,0.),vec3(1.,0.,0.),0,98),
        BRICK(vec3(0.,1.2,4.),vec3(0.,0.,-1.),1,99), //Sides
            BRICK(vec3(8.,1.2,1.),vec3(0.,0.,1.),1,99),
        BRICK(vec3(4.,1.2,5.),vec3(-1.,0.,0.),2,99), //Head
            BRICK(vec3(1.,1.2,9.),vec3(1.,0.,0.),2,99),
            BRICK(vec3(0.,1.2,7.),vec3(0.,0.,-1.),0,98), //Along wall toilet
                BRICK(vec3(0.,1.2,9.),vec3(0.,0.,-1.),0,98),
        BRICK(vec3(0.,1.2,20.),vec3(0.,0.,-1.),2,98), //Behind chairs front
            BRICK(vec3(8.,1.2,18.),vec3(0.,0.,1.),2,98),
        BRICK(vec3(3.,2.4,21.),vec3(-1.,0.,0.),1,97), //Front
            BRICK(vec3(5.,2.4,21.),vec3(-1.,0.,0.),1,97),
            BRICK(vec3(7.,2.4,21.),vec3(-1.,0.,0.),1,97),
        BRICK(vec3(0.,2.4,17.),vec3(0.,0.,-1.),1,97), //Windows kitchen and sofa
            BRICK(vec3(0.,2.4,15.),vec3(0.,0.,-1.),1,97),
            BRICK(vec3(8.,2.4,15.),vec3(0.,0.,1.),1,97),
            BRICK(vec3(8.,2.4,13.),vec3(0.,0.,1.),1,97),
    
    //Wall H=3 from back door wall
        BRICK(vec3(8.,1.2,0.),vec3(0.,0.,1.),2,14), //Back
        BRICK(vec3(8.,1.2,4.),vec3(0.,0.,1.),2,14), //Near door
            BRICK(vec3(8.,1.2,10.),vec3(0.,0.,1.),2,17),
            BRICK(vec3(8.,1.2,9.),vec3(0.,0.,1.),2,14),
            BRICK(vec3(8.,1.2,14.),vec3(0.,0.,1.),2,17),
            BRICK(vec3(4.,1.2,20.),vec3(1.,0.,0.),2,17),
        BRICK(vec3(1.,1.2,10.),vec3(0.,0.,1.),2,17), //Opposite door
            BRICK(vec3(1.,1.2,9.),vec3(0.,0.,1.),2,14),
            BRICK(vec3(1.,1.2,14.),vec3(0.,0.,1.),2,17),
            BRICK(vec3(0.,1.2,20.),vec3(1.,0.,0.),2,17),
        BRICK(vec3(1.,1.2,0.),vec3(0.,0.,1.),2,14), //Near back and head
            BRICK(vec3(1.,1.2,4.),vec3(0.,0.,1.),2,14),
    
    //Wall H=6 (same as panels)
        BRICK(vec3(8.,2.4,0.),vec3(0.,0.,1.),2,14), //Back
        BRICK(vec3(8.,2.4,4.),vec3(0.,0.,1.),2,14), //Near door
            BRICK(vec3(8.,2.4,9.),vec3(0.,0.,1.),2,17),
            BRICK(vec3(8.,2.4,17.),vec3(0.,0.,1.),2,14),
            BRICK(vec3(8.,2.4,20.),vec3(0.,0.,1.),2,14),
        BRICK(vec3(1.,2.4,9.),vec3(0.,0.,1.),2,17), //Opposite door
            BRICK(vec3(1.,2.4,17.),vec3(0.,0.,1.),2,14),
            BRICK(vec3(1.,2.4,20.),vec3(0.,0.,1.),2,14),
        BRICK(vec3(1.,2.4,0.),vec3(0.,0.,1.),2,14), //Near back and head
            BRICK(vec3(1.,2.4,4.),vec3(0.,0.,1.),2,14),
    
    //Wall H=9
        BRICK(vec3(8.,3.6,0.),vec3(0.,0.,1.),2,14), //Back
        BRICK(vec3(8.,3.6,4.),vec3(0.,0.,1.),2,14), //Door side
                BRICK(vec3(8.,3.6,9.),vec3(0.,0.,1.),2,3), //Hooks and stove
                BRICK(vec3(8.,4.,9.),vec3(0.,0.,1.),2,3),
                BRICK(vec3(8.,4.4,11.),vec3(0.,0.,1.),10,8), //Stove
                    BRICK(vec3(7.,4.8,11.),vec3(0.,0.,1.),8,56),
                BRICK(vec3(8.,4.4,9.),vec3(0.,0.,1.),10,1),
            BRICK(vec3(8.,3.6,17.),vec3(0.,0.,1.),2,14),
            BRICK(vec3(8.,3.6,20.),vec3(0.,0.,1.),2,14),
        BRICK(vec3(1.,3.6,9.),vec3(0.,0.,1.),2,17), //Opposite door
            BRICK(vec3(1.,3.6,17.),vec3(0.,0.,1.),2,14),
            BRICK(vec3(1.,3.6,20.),vec3(0.,0.,1.),2,14),
            BRICK(vec3(1.,3.6,20.),vec3(0.,0.,1.),2,14),
        BRICK(vec3(1.,3.6,0.),vec3(0.,0.,1.),2,14), //Near back and head
            BRICK(vec3(1.,3.6,4.),vec3(0.,0.,1.),2,14),
    
    //Wall H=12 (white with curtains hooks)
        BRICK(vec3(0.,4.8,0.),vec3(1.,0.,0.),0,19), //Back
        BRICK(vec3(8.,4.8,3.),vec3(0.,0.,1.),0,15), //Door wall
            BRICK(vec3(8.,4.8,9.),vec3(0.,0.,1.),0,17),
            BRICK(vec3(8.,4.8,19.),vec3(0.,0.,1.),0,15),
                BRICK(vec3(7.,4.8,17.),vec3(1.,0.,0.),0,75), //Air vent
                BRICK(vec3(7.,4.8,18.),vec3(1.,0.,0.),0,75),
                BRICK(vec3(7.2,6.,17.),vec3(0.,90.,1.),2,56),
        BRICK(vec3(1.,4.8,5.),vec3(0.,0.,1.),0,17), //Opposite door
            BRICK(vec3(1.,4.8,9.),vec3(0.,0.,1.),0,17),
            BRICK(vec3(1.,4.8,17.),vec3(0.,0.,1.),0,17),
        BRICK(vec3(0.,4.8,4.),vec3(1.,0.,0.),0,17), //Head
            BRICK(vec3(1.,4.8,9.),vec3(1.,0.,0.),0,14),
            BRICK(vec3(2.,4.8,10.),vec3(0.,0.,-1.),0,75),
                BRICK(vec3(2.,6.,9.8),vec3(1.,90.,0.),2,60),
                BRICK(vec3(2.,6.,8.6),vec3(1.,90.,0.),2,60),
            BRICK(vec3(3.,4.8,9.),vec3(1.,0.,0.),0,14),
    
    //Roof base H=15
        BRICK(vec3(1.,6.,0.),vec3(1.,0.,0.),10,32), //Back
        BRICK(vec3(8.,6.,0.),vec3(0.,0.,1.),10,29), //Door side
            BRICK(vec3(8.,6.,2.),vec3(0.,0.,1.),10,0),
            BRICK(vec3(8.,6.,3.),vec3(0.,0.,1.),10,33),
            BRICK(vec3(8.,6.,11.),vec3(0.,0.,1.),10,0),
            BRICK(vec3(8.,6.,12.),vec3(0.,0.,1.),10,33),
        BRICK(vec3(0.,6.,20.),vec3(1.,0.,0.),10,29), //Front
            BRICK(vec3(3.,6.,20.),vec3(0.,0.,1.),10,0),
            BRICK(vec3(3.,6.,20.),vec3(1.,0.,0.),10,29),
            BRICK(vec3(6.,6.,20.),vec3(0.,0.,1.),10,0),
            BRICK(vec3(6.,6.,20.),vec3(1.,0.,0.),10,29),
        BRICK(vec3(1.,6.,0.),vec3(0.,0.,1.),10,29), //Opposite door
            BRICK(vec3(1.,6.,2.),vec3(0.,0.,1.),10,0),
            BRICK(vec3(1.,6.,3.),vec3(0.,0.,1.),10,33),
            BRICK(vec3(1.,6.,11.),vec3(0.,0.,1.),10,0),
            BRICK(vec3(1.,6.,12.),vec3(0.,0.,1.),10,33),
    
    //Front window hooks
    BRICK(vec3(1.,4.8,20.),vec3(1.,0.,0.),0,4),
        BRICK(vec3(1.,5.2,21.),vec3(0.,0.,-1.),0,91),
        BRICK(vec3(3.,5.2,21.),vec3(0.,0.,-1.),0,91),
        BRICK(vec3(5.,5.2,21.),vec3(0.,0.,-1.),0,91),
        BRICK(vec3(1.,5.6,20.),vec3(1.,0.,0.),0,4),
    
    //Side windows front - window hooks
    BRICK(vec3(1.,4.8,13.),vec3(0.,0.,1.),0,3),
        BRICK(vec3(0.,5.2,13.),vec3(1.,0.,0.),0,91)
);

const BRICK BrickArray1[96]=BRICK[96](
        BRICK(vec3(0.,5.2,15.),vec3(1.,0.,0.),0,91),
        BRICK(vec3(1.,5.6,13.),vec3(0.,0.,1.),0,3),
    BRICK(vec3(8.,4.8,13.),vec3(0.,0.,1.),0,3),
        BRICK(vec3(8.,5.2,15.),vec3(-1.,0.,0.),0,91),
        BRICK(vec3(8.,5.2,17.),vec3(-1.,0.,0.),0,91),
        BRICK(vec3(8.,5.6,13.),vec3(0.,0.,1.),0,3),
    
    //Side windows back - window hooks
    BRICK(vec3(1.,4.8,1.),vec3(0.,0.,1.),0,1),
        BRICK(vec3(1.,4.8,3.),vec3(0.,0.,1.),0,14),
        BRICK(vec3(0.,5.2,1.),vec3(1.,0.,0.),0,91),
        BRICK(vec3(1.,5.6,1.),vec3(0.,0.,1.),0,1),
    BRICK(vec3(8.,4.8,1.),vec3(0.,0.,1.),0,1),
        BRICK(vec3(8.,5.2,3.),vec3(-1.,0.,0.),0,91),
        BRICK(vec3(8.,5.6,1.),vec3(0.,0.,1.),0,1),
    
    //Interior - bed
        BRICK(vec3(6.,0.4,1),vec3(0.,0.,1.),7,9), //"Not" legs
        BRICK(vec3(6.,0.8,1.),vec3(0.,0.,1.),7,9),
    BRICK(vec3(2.,1.2,1.),vec3(0.,0.,1.),0,30), //Base
        BRICK(vec3(4.,1.2,1.),vec3(0.,0.,1.),0,37),
        BRICK(vec3(6.,1.2,1.),vec3(0.,0.,1.),0,37),
    BRICK(vec3(1.5,1.6,1.41666666),vec3(0.,0.,1.),10,1), //Pillow
    BRICK(vec3(1.5,1.6,3.25),vec3(cos(0.8),0.,-sin(0.8)),9,10), //Blanket
    BRICK(vec3(6.,0.4,2.),vec3(0.,0.,-1.),10,75), //Small table
        BRICK(vec3(7.,1.61,1.),vec3(0.,0.,1.),6,60),
    
    //Roof base - head
    BRICK(vec3(4.,6.,4.),vec3(0.,0.,1.),10,29),
        BRICK(vec3(1.,6.,4.),vec3(1.,0.,0.),10,29),
        BRICK(vec3(1.,6.,9.),vec3(1.,0.,0.),10,30),
    
    //Interior - head
    BRICK(vec3(1.,0.4,5.),vec3(1.,0.,0.),5,60), //Basin
        BRICK(vec3(1.,0.8,5.),vec3(1.,0.,0.),0,72),
        BRICK(vec3(1.,2.01,5.),vec3(1.,0.,0.),10,76),
    BRICK(vec3(4.,0.4,6.),vec3(0.,0.,1.),7,2), //Entrance brick
        BRICK(vec3(1.,0.41,6.),vec3(1.,0.,0.),2,56), //Grate
    BRICK(vec3(1.,0.4,7.),vec3(1.,0.,0.),0,8), //Seat
        BRICK(vec3(1.,0.8,7.),vec3(1.,0.,0.),0,8),
        BRICK(vec3(3.,1.21,8.),vec3(0.,0.,1.),10,75),
        BRICK(vec3(1.,1.21,8.),vec3(1.,0.,0.),5,61),
    
    //Interior - entrance
    BRICK(vec3(6.,0.4,6.),vec3(0.,0.,1.),2,37), //Entrance
        BRICK(vec3(8.,0.4,6.),vec3(0.,0.,1.),2,37),
    
    //Galley
    BRICK(vec3(7.,0.4,11.),vec3(0.,0.,1.),0,11), //Stove
        BRICK(vec3(7.,0.8,11.),vec3(0.,0.,1.),11,15),
        BRICK(vec3(5.,0.8,11.),vec3(1.,0.,0.),11,75),
        BRICK(vec3(5.,0.8,12.),vec3(1.,0.,0.),11,75),
        BRICK(vec3(7.,2.,11.),vec3(0.,0.,1.),11,8),
            BRICK(vec3(5.,2.41,11.),vec3(1.,0.,0.),10,60),
            BRICK(vec3(5.,2.41,12.),vec3(1.,0.,0.),10,60),
            BRICK(vec3(6.,2.41,11.),vec3(1.,0.,0.),10,60),
            BRICK(vec3(6.,2.41,12.),vec3(1.,0.,0.),10,60),
        BRICK(vec3(7.,0.4,10.),vec3(0.,0.,1.),10,14), //Stove wall with hooks
            BRICK(vec3(6.,1.2,11.),vec3(0.,0.,-1.),10,92),
            BRICK(vec3(7.,2.,10.),vec3(0.,0.,1.),10,14),
            BRICK(vec3(6.,2.8,11.),vec3(0.,0.,-1.),10,92),
            BRICK(vec3(7.,3.6,10.),vec3(0.,0.,1.),11,0),
            BRICK(vec3(6.,4.,11.),vec3(0.,0.,-1.),11,74),
    BRICK(vec3(7.,0.8,13.),vec3(0.,0.,1.),0,15), //Working area
        BRICK(vec3(6.,0.8,13.),vec3(0.,0.,1.),0,15),
        BRICK(vec3(7.,2.,13.),vec3(0.,0.,1.),0,36),
        BRICK(vec3(6.001,0.8,14.),vec3(0.,0.,1.),0,72),
        BRICK(vec3(6.,0.81,15.),vec3(1.,0.,0.),5,61),
        BRICK(vec3(7.,2.02,16.),vec3(-1.,0.,0.),10,76),
    BRICK(vec3(6.,0.81,16.),vec3(1.,0.,0.),4,61), //Fire extinguisher
        BRICK(vec3(6.8,2.02,17.15),vec3(-0.9,0.,-0.43588989),0,76),
    
    //Sofa
    BRICK(vec3(3.,0.4,10.),vec3(0.,0.,1.),10,11),
        BRICK(vec3(3.,0.8,10.),vec3(0.,0.,1.),9,11),
    BRICK(vec3(1.,1.2,10.),vec3(1.,0.,0.),9,74),
        BRICK(vec3(1.,1.21,11.),vec3(1.,0.,0.),9,74),
        BRICK(vec3(1.,1.21,12.),vec3(1.,0.,0.),9,74),
        BRICK(vec3(1.,1.21,13.),vec3(1.,0.,0.),9,74),
        BRICK(vec3(1.,1.21,14.),vec3(1.,0.,0.),9,74),
        BRICK(vec3(1.,1.21,15.),vec3(1.,0.,0.),9,74),
        BRICK(vec3(2.01,1.21,16.),vec3(0.,0.,-1.),9,74), //Sofa side
    
    //Dining area
    BRICK(vec3(1.,0.4,18.),vec3(1.,0.,0.),0,11),
        BRICK(vec3(2.,0.8,18.),vec3(0.,0.,1.),2,1),
        BRICK(vec3(3.,0.8,18.),vec3(0.,0.,1.),2,56),
        BRICK(vec3(7.,0.8,18.),vec3(0.,0.,1.),2,1),
        BRICK(vec3(6.,0.8,18.),vec3(0.,0.,1.),2,56),
    BRICK(vec3(3.5,0.9,18.5),vec3(1.,0.,0.),11,61), //Table
        BRICK(vec3(3.,2.,18.),vec3(1.,0.,0.),0,8),
    
    
    
    
    
    
    
    
    
    
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29),
    BRICK(vec3(210.,0.,12.),vec3(1.,0.,0.),10,29)
);