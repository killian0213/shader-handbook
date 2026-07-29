// Common (common) — LEGO Voxel Cone Tracing by Mathis
// https://www.shadertoy.com/view/l3Xyz4

//Constants
const float FOV = radians((47.5)/2.);
const float LightCoeff = 8.;
const float ILightCoeff = 1./LightCoeff;
const vec3 SUN_TARGET = vec3(4., 1.5, 2.);
const vec3 SUN_DIR = normalize(vec3(1.4, 0.6, 0.8));
const vec3 SUN_TAN = normalize(cross(SUN_DIR, vec3(0., 1., 0.)));
const vec3 SUN_BIT = cross(SUN_TAN, SUN_DIR);
const float SUN_SM_SIZE = 4.;
const float PI = 3.141592653;
const float HPI = 3.141592653*0.5;
const float IPI = 1./PI;
const float I3 = 1./3.;
const float I15 = 1./15.;
const float I16 = 1./16.;
const float I32 = 1./32.;
const float I35 = 1./35.;
const float I64 = 1./64.;
const float I128 = 1./128.;
const float I512 = 1./512.;
const float I1024 = 1./1024.;
const vec2 eps = vec2(1./31., 0.);
const vec2 epsv = vec2(0.2, 0.);
const float CFOV = tan(FOV);
const vec3 LEGOOSlope = normalize(vec3(3.5/6.,1.,0.));
const vec3 LEGOISlope = normalize(vec3(1.,-1.,0.));
const vec2 SSOffsets8[8] = vec2[8](vec2(0.,0.2),vec2(0.,-0.2),vec2(0.2,0.),vec2(-0.2,0.),
                                  vec2(0.4),vec2(-0.4),vec2(-0.4,0.4),vec2(0.4,-0.4));
//Defines
#define RES iChannelResolution[0].xy
#define IRES 1./iChannelResolution[0].xy
#define ASPECT vec2(iChannelResolution[0].x/iChannelResolution[0].y,1.)

struct HIT { float D; vec3 C; vec3 N; int M; };
struct DF { float D; vec3 C; int M; };
struct BRICKTYPE { float UVOffset; vec2 UVDim; vec3 BrickDim; };
struct BRICK { vec3 P; vec4 Q; vec3 C; int I; int M; };

vec3 SampleSky(vec3 d) {
    vec3 L = vec3(0.2)*(d.y*0.5+0.5);
    vec3 InitialDir = vec3(sin(-0.78),0.3,cos(-0.78));
    if (dot(d,InitialDir)>0.75) L += vec3(2.5);
    else if (dot(d,vec3(-InitialDir.x,InitialDir.yz))>0.85) L += vec3(2.7,0.4,0.075);
    //Return
    return L;
}

//SDF
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

float DFExtrude(vec3 p, float sdf, float h) {
    //By IQ: https://www.shadertoy.com/view/4lyfzw
    vec2 w = vec2(sdf,abs(p.z)-h);
  	return min(max(w.x,w.y),0.)+length(max(w,0.));
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

vec2 ABox(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t1 = min(tMin,tMax);
    vec2 t2 = max(tMin,tMax);
    return vec2(max(t1.x,t1.y),min(t2.x,t2.y));
}

vec2 ABox(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t1 = min(tMin,tMax);
    vec3 t2 = max(tMin,tMax);
    return vec2(max(max(t1.x,t1.y),t1.z),min(min(t2.x,t2.y),t2.z));
}

float ABoxfar(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t2 = max(tMin,tMax);
    return min(t2.z,min(t2.x,t2.y));
}

float ABoxfar(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t2 = max(tMin,tMax);
    return min(t2.x,t2.y);
}

vec2 ABoxfarNormal(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax, out float dist) {
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t2 = max(tMin,tMax);
    dist = min(t2.x,t2.y);
    vec2 signdir = (max(vec2(0.),sign(dir))*2.-1.);
    if (t2.x<t2.y) return vec2(signdir.x,0.);
    else return vec2(0.,signdir.y);
}

vec3 ABoxfarNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t1 = min(tMin,tMax);
    vec3 t2 = max(tMin,tMax);
    vec3 signdir = (max(vec3(0.),sign(dir))*2.-1.);
    if (t2.x<min(t2.y,t2.z)) return vec3(signdir.x,0.,0.);
    else if (t2.y<t2.z) return vec3(0.,signdir.y,0.);
    else return vec3(0.,0.,signdir.z);
}

vec2 ABoxNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax, out vec3 N) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t1 = min(tMin,tMax);
    vec3 t2 = max(tMin,tMax);
    vec3 signdir = -(max(vec3(0.),sign(dir))*2.-1.);
    if (t1.x>max(t1.y,t1.z)) N = vec3(signdir.x,0.,0.);
    else if (t1.y>t1.z) N = vec3(0.,signdir.y,0.);
    else N = vec3(0.,0.,signdir.z);
    return vec2(max(max(t1.x,t1.y),t1.z),min(min(t2.x,t2.y),t2.z));
}

vec3 ABoxNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t1 = min(tMin,tMax);
    vec3 t2 = max(tMin,tMax);
    vec3 signdir = -(max(vec3(0.),sign(dir))*2.-1.);
    if (t1.x>max(t1.y,t1.z)) return vec3(signdir.x,0.,0.);
    else if (t1.y>t1.z) return vec3(0.,signdir.y,0.);
    else return vec3(0.,0.,signdir.z);
}

vec3 RandSample(vec2 v) {
    float r=sqrt(1.-v.x*v.x);
    float phi=2.*3.14159*v.y;
    return vec3(cos(phi)*r,sin(phi)*r,v.x);
}

vec3 RandSampleCos(vec2 v) {
    float theta = sqrt(v.x);
    float phi = 2.*3.14159*v.y;
    float x = theta*cos(phi);
    float z = theta*sin(phi);
    return vec3(x,z,sqrt(max(0.,1.-v.x)));
}

vec3 RandSampleCosXYer(vec2 v) {
    float theta = sqrt(v.x);
    float phi = 2.*3.14159*v.y;
    float x = theta*cos(phi);
    float z = theta*sin(phi);
    return vec3(x,z,0.);
}

//Float-Vec conversion
vec3 FloatToVec3(float v) {
    int VPInt = floatBitsToInt(v);
    int VPInt1024 = VPInt%1024;
    int VPInt10241024 = ((VPInt-VPInt1024)/1024)%1024;
    return vec3(VPInt1024,VPInt10241024,((VPInt-VPInt1024-VPInt10241024)/1048576))*I1024;
}

float Vec3ToFloat(vec3 v) {
    ivec3 intv = min(ivec3(floor(v*1024.)),ivec3(1023));
    return intBitsToFloat(intv.x+intv.y*1024+intv.z*1048576);
}

vec2 FloatToVec2(float v) {
    int VPInt = floatBitsToInt(v);
    int VPInt1 = VPInt%32768;
    return vec2(VPInt1,((VPInt-VPInt1)/32768))/32768.;
}

float Vec2ToFloat(vec2 v) {
    ivec2 intv = min(ivec2(floor(v*32768.)),ivec2(32767));
    return intBitsToFloat(intv.x+intv.y*32768);
}
//GGX
vec3 SchlickFresnel(vec3 r0, float angle) {
    //Schlick Fresnel approximation
    return r0+(1.-r0)*pow(1.-angle,5.);
}

float SmithGGXMasking(vec3 wi, vec3 wo, float a2) {
    //Smith masking function
    float dotNL = wi.z;
    float dotNV = wo.z;
    float denomC = sqrt(a2+(1.-a2)*dotNV*dotNV)+dotNV;
    return 2.*dotNV/denomC;
}

float SmithGGXMaskingShadowing(vec3 wi, vec3 wo, float alpha) {
    //Smith masking shadowing function
    float dotNL = wi.z;
    float dotNV = wo.z;
    float denomA = dotNV*sqrt(alpha+(1.-alpha)*dotNL*dotNL);
    float denomB = dotNL*sqrt(alpha+(1.-alpha)*dotNV*dotNV);
    return 2.*dotNL*dotNV/(denomA+denomB);
}

vec3 GgxVndf(vec3 wo, float roughness, float u1, float u2) {
    //Returns the mini normal
    vec3 v = normalize(vec3(wo.x*roughness,wo.y*roughness,wo.z));
    vec3 t1 = (v.z<0.999)?normalize(cross(v,vec3(0.,0.,1.))):vec3(1.,0.,0.);
    vec3 t2 = cross(t1, v);
    float a = 1./(1.+v.z);
    float r = sqrt(u1);
    float phi = (u2<a)?(u2/a)*PI:PI+(u2-a)/(1.-a)*PI;
    float p1 = r*cos(phi);
    float p2 = r*sin(phi)*((u2<a)?1.:v.z);
    vec3 n = p1*t1+p2*t2+sqrt(max(0.,1.-p1*p1-p2*p2))*v;
    return normalize(vec3(roughness*n.x,roughness*n.y,max(0.,n.z)));
}

void ImportanceSampleGGX(vec2 uRand, vec3 wo, float Roughness, vec3 SpecularColor, out vec3 wi, out vec3 reflectance) {
    //Importance sampling
    float a2 = Roughness*Roughness;
    vec3 wm = GgxVndf(wo,Roughness,uRand.x,uRand.y);
    wi = reflect(-wo,wm);
    if (wi.z>0.) {
        vec3 F = SchlickFresnel(SpecularColor,dot(wi, wm));
        float G1 = SmithGGXMasking(wi,wo,a2);
        float G2 = SmithGGXMaskingShadowing(wi,wo,a2);
        reflectance = F*(G2/G1);
    } else {
        reflectance = vec3(0.);
    }
}


//SDF
float DFStud(vec3 p) {
    float d = -smin(-DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.3,-p.y+0.2,0.075);
    d = max(-p.y,smin(d,DFDisk(p),0.05));
    return d;
}

float DFBrick(vec3 p, vec3 BSize) {
    float d = DFBox(p-vec3(0.04),BSize-vec3(0.08,0.48,0.08))-0.04;
    d = -smin(-d,DFBox(p-vec3(0.25,-0.95,0.25),BSize-vec3(0.5,-0.3,0.5))-0.05,0.05);
    if (min(BSize.x,BSize.z)>1.5) {
        float LineDF = DFLine(vec3(fract(clamp(p.x,0.5,BSize.x-0.5)-0.5),p.yz),vec3(0.5,-1.,1.),vec3(0.5,1.,1.));
        d = smin(d,-smin(-max(max(LineDF-0.407,-LineDF+0.3),p.y-(BSize.y-0.45)),p.y,0.05),0.05);
    } else {
        float tmpLine = DFLine(vec3(fract(clamp(p.x,0.5,BSize.x-0.5)-0.5),p.yz),vec3(0.5,-1.,0.5),vec3(0.5,2.,0.5));
        d = min(d,max(max(max(tmpLine-0.2,-tmpLine+0.1),p.y-(BSize.y-0.45)),-p.y));
    }
    vec3 StudPos = vec3(clamp(floor(p.x),0.,BSize.x-1.),BSize.y-0.4,clamp(floor(p.z),0.,BSize.z-1.));
    d = -smin(-d,-smin(-DFLine(p-StudPos,vec3(0.5,-1.,0.5),vec3(0.5,-0.05,0.5))+0.15,-p.y+BSize.y-0.45,0.05),0.05); //Hole under stud
    d = min(d,DFStud(p-StudPos)); //Studs
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

float DFISlope(vec3 p, float Z) {
    float d = -smin(-DFBox(p-vec3(0.02),vec3(1.96,1.16,Z-0.04))+0.017,-dot(LEGOISlope,p-vec3(1.,0.,0.)),0.03);
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
    float d = DFBrick(p.zyx,vec3(2.,0.8,1.));
    //Handle
    float Z = type*0.4;
    float tmpCyl = length(p.xy-vec2(1.5,0.3));
    d = min(d,DFBox(syp-vec3(0.04,0.04,0.74-Z),vec3(1.46,0.32,0.22))-0.04);
    d = min(d,-smin(smin(-tmpCyl+0.3,1.-Z-syp.z,0.04),syp.z-0.7+Z,0.04));
    d = min(d,max(max(tmpCyl-0.2,0.05-p.z),p.z-1.95));
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

float DFGrate(vec3 p) {
    float d = DFBox(p-vec3(0.02),vec3(1.96,0.36,0.96))-0.02;
    d = max(d,-DFBox(p-vec3(0.2,-1.,0.2),vec3(1.6,1.25,0.6)));
    d = max(d,-DFBox(vec3(p.x+2.,p.y-0.2,fract(p.z*2.5)*0.4-0.2),vec3(8.,1.,0.2)));
    return d;
}

float DFRound111(vec3 p) {
    float LineDF = DFLine(p,vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5));
    float d = -smin(smin(-LineDF+0.499,-p.y+0.4,0.04),p.y-0.3,0.05);
    d = smin(d,-smin(smin(-max(LineDF-0.397,-LineDF+0.305),-p.y+0.35,0.05),p.y-0.01,0.05),0.05);
    d = -smin(-d,-smin(-LineDF+0.15,-p.y+0.38,0.05),0.05);
    d = min(d,DFStud(vec3(p.x,p.y-0.4,p.z))); //Stud
    return d;
}

float DFHeadLight(vec3 p) {
    float d = -smin(-DFBox(p-vec3(0.04),vec3(0.92,1.12,0.92))+0.04,DFBox(p-vec3(-1.,0.25,-1.),vec3(1.2,2.,3.)),0.05);
    //Stud
    d = smin(d,-smin(-DFLine(p,vec3(0.5,0.7,0.5),vec3(-2.,0.7,0.5))+0.3,p.x,0.07),0.05);
    d = -smin(-d,min(DFBox(p-vec3(0.35,0.25,0.25),vec3(2.9,0.7,0.5)),DFBox(p-vec3(0.35,-1.,0.25),vec3(0.4,1.95,0.5)))-0.05,0.05);
    d = -smin(-d,DFLine(p,vec3(0.5,0.7,0.5),vec3(-2.,0.7,0.5))-0.2,0.05);
    d = smin(d,max(-smin(-DFLine(p-vec3(0.,1.2,0.),vec3(0.5,-1.,0.5),vec3(0.5,1.,0.5))+0.3,-p.y+1.2+0.2,0.075),-p.y+1.2),0.03); //Stud
    return d;
}

DF MIN(DF OUT, DF IN) {
    if (OUT.D>IN.D) return IN;
    return OUT;
}

DF SDF(vec3 p) {
    DF OUT = DF(100000.,vec3(1.),1);
    
    //Return
    return OUT;
}

vec3 StudInfo[22] = vec3[22](
    vec3(0.,10.,0.), //0
    vec3(1.,0.599,1.), //1
    vec3(1.,10.,1.), //2
    vec3(1.,0.599,1.), //3, Brick111
    vec3(1.,10.,1.), //4
    vec3(4.,0.599,1.), //5
    vec3(4.,0.599,2.), //6
    vec3(1.,1.399,1.), //7
    vec3(1.,1.399,1.), //8
    vec3(1.,0.999,1.), //9, Grip
    vec3(1.,0.599,2.), //10
    vec3(2.,0.599,1.), //11
    vec3(1.,10.,1.), //12
    vec3(1.,10.,1.), //13
    vec3(1.,10.,1.), //14
    vec3(1.,10.,1.), //15
    vec3(1.,10.,1.), //16, Lever
    vec3(1.,10.,1.), //17
    vec3(1.,10.,1.), //18
    vec3(2.,0.599,1.), //19
    vec3(1.,10.999,1.), //20
    vec3(1.,10.,1.) //21
);

const vec3 L_SteeringY = normalize(vec3(-sin(radians(40.)),cos(radians(40.)),0.));
const vec3 L_SteeringX = normalize(cross(L_SteeringY,vec3(0.,0.,1.)));
const vec3 L_SteeringP = vec3(9.15,1.7,2.);
const float L_RoofAngle = radians(10.);
const vec3 L_RoofY = normalize(vec3(sin(L_RoofAngle),cos(L_RoofAngle),0.));
const vec3 L_RoofX = normalize(cross(L_RoofY,vec3(0.,0.,1.)));
const vec3 L_RoofP = vec3(5.85,4.55,4.);
const float L_ScreenAngle = radians(32.5);
const vec3 L_ScreenY = normalize(vec3(-sin(L_ScreenAngle),cos(L_ScreenAngle),0.));
const vec3 L_ScreenX = normalize(cross(L_ScreenY,vec3(0.,0.,1.)));
const vec3 L_ScreenP = vec3(8.5,3.1,1.); //Rotation point
const vec3 L_RedEmissive = vec3(1.,0.1,0.025)*3.;
const vec3 L_CarColor = vec3(0.2,0.4,0.8);
BRICK Bricks[99] = BRICK[99](
    //Tires
    BRICK(vec3(3.,-0.05,1.),vec4(1.,0.,0.,0.),vec3(0.2),12,2),
        BRICK(vec3(3.,-0.05,4.),vec4(1.,0.,0.,0.),vec3(0.2),12,2),
    BRICK(vec3(9.,-0.05,1.),vec4(1.,0.,0.,0.),vec3(0.2),12,2),
        BRICK(vec3(9.,-0.05,4.),vec4(1.,0.,0.,0.),vec3(0.2),12,2),
        //Tire rim
        BRICK(vec3(3.,-0.05,1.),vec4(1.,0.,0.,0.),vec3(0.9),13,1),
            BRICK(vec3(5.,-0.05,5.),vec4(-1.,0.,0.,0.),vec3(0.9),13,1),
        BRICK(vec3(9.,-0.05,1.),vec4(1.,0.,0.,0.),vec3(0.9),13,1),
            BRICK(vec3(11.,-0.05,5.),vec4(-1.,0.,0.,0.),vec3(0.9),13,1),
        //Tire rim connector (but actually not)
        BRICK(vec3(3.,0.8,2.),vec4(1.,0.,0.,0.),vec3(0.6),11,1),
            BRICK(vec3(3.,0.8,3.),vec4(1.,0.,0.,0.),vec3(0.6),11,1),
        BRICK(vec3(9.,0.8,2.),vec4(1.,0.,0.,0.),vec3(0.6),11,1),
            BRICK(vec3(9.,0.8,3.),vec4(1.,0.,0.,0.),vec3(0.6),11,1),
    
    //Base 412
    BRICK(vec3(2.,0.4,2.),vec4(1.,0.,0.,0.),vec3(0.3),6,1),
    BRICK(vec3(8.,0.4,2.),vec4(1.,0.,0.,0.),vec3(0.3),6,1),
    BRICK(vec3(8.,0.4,1.),vec4(0.,0.,1.,0.),vec3(0.3),6,1),
        BRICK(vec3(5.,0.8,1.),vec4(1.,0.,0.,0.),vec3(0.6),6,1),
        BRICK(vec3(5.,0.8,3.),vec4(1.,0.,0.,0.),vec3(0.6),6,1),
    
    //Back headlights low
    BRICK(vec3(2.,0.8,1.),vec4(1.,0.,0.,0.),L_CarColor,7,1),
        BRICK(vec3(2.,0.8,2.),vec4(1.,0.,0.,0.),L_CarColor,7,1),
        BRICK(vec3(2.,0.8,3.),vec4(1.,0.,0.,0.),L_CarColor,7,1),
        BRICK(vec3(2.,0.8,4.),vec4(1.,0.,0.,0.),L_CarColor,7,1),
    BRICK(vec3(2.2,2.,1.),vec4(0.,0.,1.,HPI),L_CarColor*0.5,5,1), //411
        BRICK(vec3(1.8,2.,2.),vec4(-0.04471,-0.999,0.,0.),L_CarColor,0,1),
        BRICK(vec3(1.8,2.,3.),vec4(-0.04471,-0.999,0.,0.),L_CarColor,0,1),
        BRICK(vec3(1.8,2.,4.),vec4(-0.04471,-0.999,0.,0.),L_CarColor,0,1),
        BRICK(vec3(1.8,2.,5.),vec4(-0.04471,-0.999,0.,0.),L_CarColor,0,1),
    
    //Back headlights above
    BRICK(vec3(2.,2.,2.),vec4(1.,0.,0.,0.),vec3(0.3),7,1),
        BRICK(vec3(2.,2.,3.),vec4(1.,0.,0.,0.),vec3(0.3),7,1),
    BRICK(vec3(2.2,3.2,2.),vec4(0.,0.,1.,HPI),vec3(0.3),11,1), //211
        BRICK(vec3(1.8,3.2,1.),vec4(0.,0.,1.,HPI),vec3(0.1),5,1), //411
    BRICK(vec3(1.4,3.2,1.),vec4(0.,0.,1.,HPI),L_RedEmissive,4,0), //Grate
        BRICK(vec3(1.4,3.2,3.),vec4(0.,0.,1.,HPI),L_RedEmissive,4,0),
    
    //Back headlights side
    BRICK(vec3(4.,2.,2.),vec4(0.,0.,1.,0.),vec3(0.3),7,1), //To origin
        BRICK(vec3(4.,3.2,2.2),vec4(-1.,0.,0.,HPI),vec3(1.,1.,0.3),1,0),
        BRICK(vec3(4.,3.2,1.8),vec4(-1.,0.,0.,HPI),vec3(0.1),11,1),
        BRICK(vec3(4.,3.2,1.4),vec4(-1.,0.,0.,HPI),L_RedEmissive,4,0),
    BRICK(vec3(3.,2.,4.),vec4(0.,0.,-1.,0.),vec3(0.3),7,1), //From origin
        BRICK(vec3(3.,3.2,3.8),vec4(1.,0.,0.,HPI),vec3(1.,1.,0.3),1,0),
        BRICK(vec3(2.,3.2,4.2),vec4(1.,0.,0.,HPI),vec3(0.3),11,1),
        BRICK(vec3(2.,3.2,4.6),vec4(1.,0.,0.,HPI),L_RedEmissive,4,0),
    
    //Under headlights side
    BRICK(vec3(4.,1.2,2.),vec4(0.,0.,1.,0.),vec3(0.6),11,1),
        BRICK(vec3(4.,1.6,2.),vec4(0.,0.,1.,0.),vec3(0.6),11,1),
    
    //Seat
    BRICK(vec3(4.,1.2,2.),vec4(1.,0.,0.,0.),vec3(0.7,0.3,0.2),4,1),
        BRICK(vec3(4.,1.2,3.),vec4(1.,0.,0.,0.),vec3(0.7,0.3,0.2),4,1),
    BRICK(vec3(7.,1.2,2.),vec4(0.,0.,1.,0.),vec3(0.7,0.3,0.2),4,1),
    
    //Over tires (inverse slope and onlyslope)
    BRICK(vec3(6.,1.2,2.),vec4(-1.,0.,0.,0.),L_CarColor,8,1),
        BRICK(vec3(6.,1.2,5.),vec4(-1.,0.,0.,0.),L_CarColor,8,1),
    BRICK(vec3(4.,2.4,1.),vec4(1.,0.,0.,0.),L_CarColor,0,1),
        BRICK(vec3(4.,2.4,4.),vec4(1.,0.,0.,0.),L_CarColor,0,1),
    
    //On top of back + pipe
    BRICK(vec3(3.,3.2,1.),vec4(0.,0.,1.,0.),L_CarColor,6,1), //412
        BRICK(vec3(4.,3.2,1.),vec4(0.,0.,1.,0.),L_CarColor,5,1), //411
    BRICK(vec3(2.,3.6,3.),vec4(1.,0.,0.,0.),vec3(0.3),7,1),
        BRICK(vec3(2.2,4.8,3.),vec4(0.,0.,1.,HPI),vec3(0.9),2,1), //Pipe
    BRICK(vec3(2.,3.6,3.),vec4(0.,0.,-1.,0.),L_CarColor,0,1),
        BRICK(vec3(3.,4.8,4.),vec4(-1.,0.,0.,0.),L_CarColor,0,1),
    
    //Base of roof
    BRICK(vec3(3.,3.6,4.),vec4(1.,0.,0.,0.),vec3(0.9),2,1),
        BRICK(vec3(3.,3.6,1.),vec4(1.,0.,0.,0.),vec3(0.9),2,1),
    BRICK(vec3(4.,4.8,1.),vec4(0.,0.,1.,0.),vec3(0.6),5,1), //411
        BRICK(vec3(3.,5.2,2.),vec4(1.,0.,0.,0.),vec3(0.6),10,1),
    
    //Front
    BRICK(vec3(12.,0.8,1.),vec4(0.,0.,1.,0.),vec3(0.6),5,1), //411
        BRICK(vec3(12.,1.2,2.),vec4(-1.,0.,0.,0.),L_CarColor,7,1), //Headlight
        BRICK(vec3(12.,1.2,5.),vec4(-1.,0.,0.,0.),L_CarColor,7,1),
    BRICK(vec3(11.8,2.4,2.),vec4(0.,0.,-1.,HPI),vec3(2.),1,0),
        BRICK(vec3(11.8,2.4,5.),vec4(0.,0.,-1.,HPI),vec3(2.),1,0),
    
    //Doors with base and mirrors
    BRICK(vec3(9.,1.2,1.),vec4(0.,0.,1.,0.),L_CarColor,7,1),
        BRICK(vec3(9.,2.4,1.2),vec4(-1.,0.,0.,HPI),L_CarColor,21,1), //Vertical Grip
        BRICK(vec3(6.,1.4,0.8),vec4(1.,0.,0.,-HPI),L_CarColor,19,1), //Door (Long Handle)
            BRICK(vec3(8.,1.35,1.2),vec4(0.,0.999,0.04471,0.),vec3(0.6),20,1), //Studgrip
            BRICK(vec3(7.22,3.5,0.41),vec4(0.,0.,1.,HPI),vec3(0.9),0,1), //Mirror
    BRICK(vec3(8.,1.2,5.),vec4(0.,0.,-1.,0.),L_CarColor,7,1),
        BRICK(vec3(9.,1.4,4.8),vec4(-1.,0.,0.,-HPI),L_CarColor,21,1), //Vertical Grip
        BRICK(vec3(6.,2.4,5.2),vec4(1.,0.,0.,HPI),L_CarColor,19,1), //Door (Long Handle)
            BRICK(vec3(7.,1.35,4.8),vec4(0.,0.999,-0.04471,0.),vec3(0.6),20,1), //Studgrip
            BRICK(vec3(7.22,2.5,5.6),vec4(0.,0.,-1.,-HPI),vec3(0.9),0,1), //Mirror
    
    //Over wheels forward (211+411)
    BRICK(vec3(8.,2.4,1.),vec4(1.,0.,0.,0.),L_CarColor,5,1),
        BRICK(vec3(9.,2.,1.),vec4(1.,0.,0.,0.),L_CarColor,11,1),
    BRICK(vec3(8.,2.4,4.),vec4(1.,0.,0.,0.),L_CarColor,5,1),
        BRICK(vec3(9.,2.,4.),vec4(1.,0.,0.,0.),L_CarColor,11,1),
    
    //Steering wheel and base
    BRICK(vec3(9.,1.2,2.),vec4(0.,0.,1.,0.),vec3(0.3),17,1),
    BRICK(L_SteeringP,vec4(0.,0.,1.,0.69813170079),vec3(0.6),18,1),
        BRICK(L_SteeringP+L_SteeringY*1.2,vec4(0.,0.,1.,0.69813170079),L_CarColor,1,1),
        BRICK(L_SteeringP+L_SteeringY*1.2+vec3(0.,0.,1.),vec4(0.,0.,1.,0.69813170079),vec3(3.),1,0),
        BRICK(L_SteeringP+L_SteeringY*1.6+L_SteeringX*0.5+vec3(0.,0.,-0.5),vec4(0.,0.,1.,0.69813170079),vec3(0.8),14,1),
    
    //Hatch and under the hatch
    BRICK(vec3(11.,1.2,4.),vec4(0.,0.,-1.,0.),vec3(0.3),17,1), //Rotating brick
        BRICK(vec3(11.,1.2,4.),vec4(0.,0.,-1.,0.),vec3(0.6),18,1),
        BRICK(vec3(12.,2.4,4.),vec4(-1.,0.,0.,0.),vec3(0.6),10,1),
    BRICK(vec3(9.,1.2,2.),vec4(1.,0.,0.,0.),vec3(0.3),2,1), //Under
        BRICK(vec3(9.,1.2,3.),vec4(1.,0.,0.,0.),vec3(0.3),2,1),
        BRICK(vec3(11.,1.2,2.),vec4(0.,0.,1.,0.),vec3(0.3),0,1),
        BRICK(vec3(10.,1.2,4.),vec4(0.,0.,-1.,0.),vec3(1.,0.5,0.3)*2.5,0,0),
    
    //Roof
    BRICK(L_RoofP,vec4(-L_RoofX,0.),vec3(0.6),9,1),
        BRICK(L_RoofP-vec3(0.,0.,1.),vec4(-L_RoofX,0.),vec3(0.6),9,1),
    BRICK(L_RoofP+L_RoofY*0.8+L_RoofX-vec3(0.,0.,3.),vec4(0.,0.,1.,-L_RoofAngle),L_CarColor,6,1),
        BRICK(L_RoofP+L_RoofY*0.4+L_RoofX*2.-vec3(0.,0.,3.),vec4(0.,0.,1.,-L_RoofAngle),L_CarColor,6,1),
        BRICK(L_RoofP+L_RoofY*0.8+L_RoofX*1.-vec3(0.,0.,2.),vec4(L_RoofX,0.),vec3(0.6),10,1),
    
    //Levers
    BRICK(vec3(8.,2.8,1.),vec4(1.,0.,0.,0.),vec3(0.8),15,1), //Lever base
        BRICK(vec3(8.,2.8,4.),vec4(1.,0.,0.,0.),vec3(0.8),15,1),
    BRICK(L_ScreenP-L_ScreenY*0.5-L_ScreenX*0.5+vec3(0.,0.,1.),vec4(L_ScreenY,0.),vec3(0.1),16,1), //Lever
        BRICK(L_ScreenP-L_ScreenY*0.5-L_ScreenX*0.5+vec3(0.,0.,4.),vec4(L_ScreenY,0.),vec3(0.1),16,1)
);