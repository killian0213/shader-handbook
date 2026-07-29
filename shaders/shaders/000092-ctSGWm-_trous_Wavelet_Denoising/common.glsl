// Common (common) — Àtrous Wavelet Denoising by Mathis
// https://www.shadertoy.com/view/ctSGWm

//Constants
const float FOV = radians((65.)/2.);
const float ReflConst = 3.;
const float IReflConst = 1./ReflConst;
const vec3 SunLight = vec3(2.6,2.,1.);
const vec3 SunDir = normalize(vec3(1.,0.7,-0.3));
const float SunCR = 0.1;
const float PI = 3.14159265;
const float PI2 = PI*2.;
const float HPI = PI*0.5;
const float IPI = 1./PI;
const float ToRadians = PI/180.;
const float I3 = 1./3.;
const float I16 = 1./16.;
const float I26 = 1./26.;
const float I32 = 1./32.;
const float I64 = 1./64.;
const float I128 = 1./128.;
const float I255 = 1./255.;
const float I256 = 1./256.;
const float I300 = 1./300.;
const float I512 = 1./512.;
const float I1024 = 1./1024.;
const float I2048 = 1./2048.;
const float Sqrt2 = sqrt(2.);
const float ISqrt2 = sqrt(0.5);
const float Sqrt3 = sqrt(3.);
const float ISqrt3 = 1./sqrt(3.);
const vec2 eps = vec2(0.,0.001);
const float CFOV = tan(FOV);
const vec2 SSOffsets8[8] = vec2[8](vec2(0.,0.2),vec2(0.,-0.2),vec2(0.2,0.),vec2(-0.2,0.),
                                  vec2(0.4),vec2(-0.4),vec2(-0.4,0.4),vec2(0.4,-0.4));
const vec2 SSOffsets[16] = vec2[16](vec2(0.),vec2(-0.4,-0.4),vec2(0.,0.2),vec2(0.15,-0.4),vec2(-0.4,-0.15),
                                    vec2(0.15,0.4),vec2(-0.2,-0.2),vec2(-0.4,0.4),vec2(0.4,0.15),vec2(0.2,-0.2),
                                    vec2(0.4,0.4),vec2(-0.4,0.15),vec2(0.4,-0.15),
                                    vec2(-0.15,0.4),vec2(0.4,-0.4),vec2(-0.15,-0.4));
//Defines
#define RES iChannelResolution[0].xy
#define IRES 1./iChannelResolution[0].xy
#define ASPECT vec2(iChannelResolution[0].x/iChannelResolution[0].y,1.)

struct HIT { float D; vec3 DC; float M; float Specular; float Metal; };

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

//Analytic
float SolidAngle(vec3 P, vec3 N, vec3 p0, vec3 p1, vec3 p2) {
    //Returns the solid angle for a visible triangle
    vec3 v0=normalize(p0-P);
    vec3 v1=normalize(p1-P);
    vec3 v2=normalize(p2-P);
    float ret=abs(dot(N,normalize(cross(v0,v1)))*acos(dot(v0,v1))+
                dot(N,normalize(cross(v1,v2)))*acos(dot(v1,v2))+
                dot(N,normalize(cross(v2,v0)))*acos(dot(v2,v0)));
    return ((isnan(ret))?0.:ret);
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

vec2 box(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t1 = min(tMin,tMax);
    vec2 t2 = max(tMin,tMax);
    return vec2(max(t1.x,t1.y),min(t2.x,t2.y));
}

vec3 boxNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax, out vec2 bb) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t1 = min(tMin,tMax);
    vec3 t2 = max(tMin,tMax);
    bb = vec2(max(max(t1.x,t1.y),t1.z),min(min(t2.x,t2.y),t2.z));
    vec3 signdir = -max(vec3(0.),sign(dir))*2.+1.;
    if (t1.x>max(t1.y,t1.z)) return vec3(signdir.x,0.,0.);
    else if (t1.y>t1.z) return vec3(0.,signdir.y,0.);
    else return vec3(0.,0.,signdir.z);
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

vec3 SchlickFresnel(vec3 r0, float angle) {
    //Schlick Fresnel approximation
    return r0+(1.-r0)*pow(1.-angle,5.);
}

vec3 SampleWindow(vec3 p, vec3 d, float M) {
    //Samples the window
    if (M>3.5) {
        //Render city
        float YCoeff = pow(1.-max(0.,d.y),8.);
        vec3 L = mix(vec3(0.025,0.13,0.17)*YCoeff+vec3(0.3,0.05,0.02)*YCoeff*YCoeff,SunLight,pow(max(0.,dot(d,SunDir)),24.));
        L *= float(d.y>0.);
        //City
        float R = 500.;
        float BWidth = 40.;
        float BHeight = 30.;
        for (int i=0; i<4; i++) {
            float A = dot(p.xz,p.xz)-R*R;
            float B = 2.*dot(p.xz,d.xz);
            float C = dot(d.xz,d.xz);
            float cP = B/C;
            float cQ = A/C;
            float det = cP*cP*0.25-cQ;
            float t1 = -cP*0.5+sqrt(det);
            vec3 sp = p+d*t1;
            float xcoord = atan(sp.x-2.,sp.z-2.)*R+20.;
            vec3 RandV = ARand23(vec2(floor(xcoord/BWidth)+0.5));
            if ((t1<L.x || L.y>=0.) &&
                mod(xcoord,BWidth)-BWidth*0.5<floor(BWidth*(0.2+0.2*RandV.x)*0.5)*2. &&
                sp.y<floor((-50.+BHeight*(0.5+0.5*RandV.y))*0.5)*2.) {
                L = vec3(2.6/max(1.,1.+R*0.02)*float(DFBox(mod(vec2(xcoord,sp.y),vec2(2.))-vec2(0.4,0.5),vec2(1.2,1.2))<0.
                         && ARand21(vec2(floor(xcoord*0.5),floor(sp.y*0.5))*0.25)<0.4));
            }
            R *= 0.5;
            BHeight *= 1.4;
        }
        return L;
    } else return SunLight;
}

//Float-Vec conversion
vec3 FloatToVec3(float v) {
    float x = fract(v);
    float z = floor(v*I300);
    float y = floor(v-z*300.)*I300;
    return vec3(x,y,z*I300);
}

float Vec3ToFloat(vec3 v) {
    v = min(v,vec3(0.998));
    return v.x+floor(v.y*300.)+floor(v.z*300.)*300.;
}

vec2 FloatToVec2(float v) {
    return vec2(fract(v),floor(v)*I2048);
}

float Vec2ToFloat(vec2 v) {
    v = min(v,vec2(0.999));
    return v.x+floor(v.y*2048.);
}

//Camera
const int NVecs = 11;
vec3 Positions[NVecs] = vec3[NVecs](vec3(-1.5,3.5,-1.5),
                            vec3(-1.5,0.5,-1.5),vec3(-1.5,0.5,-1.5),vec3(-1.5,0.5,-1.5), //Low position
                            vec3(1.99,2.3,3.7),vec3(1.99,2.3,3.7), //Near door
                            vec3(3.2,2.8,2.2),vec3(3.2,2.8,2.2), //Look out from window
                            vec3(3.4,2.3,-2.5),vec3(3.4,2.3,-2.5), //Beside the window
                            vec3(-1.5,3.5,-1.5)
                            );
vec3 Centers[NVecs] = vec3[NVecs](vec3(2.,1.,2.),
                          vec3(2.,0.3,2.),vec3(2.,0.3,2.),vec3(2.,1.2,4.),
                          vec3(3.,0.5,1.),vec3(4.,2.2,2.3),
                          vec3(20.,-1.,2.),vec3(20.,-1.,2.),
                          vec3(2.,1.5,2.),vec3(2.,1.5,2.),
                          vec3(2.,1.,2.)
                          );
vec3 CameraCenter(vec4 Mouse, float t) {
    if (Mouse.z>0.) {
        return vec3(2.,1.,2.);
    } else {
        //Epic animation
        float Time = t*(1.-exp(-t*0.125));
        float TPeriod = 1.;
        float ITPeriod = 1./TPeriod;
        int PIndex = min(int(floor(Time*ITPeriod)),NVecs-1);
        float fx = fract(Time*ITPeriod);
        return mix(Centers[PIndex],Centers[(PIndex+1)%NVecs],fx*fx*(3.-2.*fx));
    }
}

vec3 Position(vec4 Mouse, float t, vec2 ires) {
    vec2 Angles = vec2(2.8,0.01)+Mouse.xy*ires*vec2(2.3,1.2);
    if (Mouse.z>0.) {
        return vec3(2.,2.,2.)+vec3(vec2(sin(Angles.x),cos(Angles.x))*cos(Angles.y),sin(Angles.y)).xzy*8.*(0.125*5.);
    } else {
        //Epic animation
        float Time = t*(1.-exp(-t*0.125));
        float TPeriod = 1.;
        float ITPeriod = 1./TPeriod;
        int PIndex = min(int(floor(Time*ITPeriod)),NVecs-1);
        float fx = fract(Time*ITPeriod);
        return mix(Positions[PIndex],Positions[(PIndex+1)%NVecs],fx*fx*(3.-2.*fx));
    }
}

//SDF
void Trace_WindowFrame(vec3 P, vec3 D, inout HIT OUT) {
    float dft = 0.; float tmpt,aplen; vec3 ap,rp;
    for (int i=0; i<128; i++) {
        //SDF
        ap = P+D*dft;
        ap.yz = abs(ap.yz); //Symmetry
        //Base pillars (idk)
        tmpt = max(DFBox(ap-vec3(-0.1,0.,-0.1),vec3(0.1,1.9,0.2)),-length(ap.xz-vec2(-0.125,0.1))+0.075);
        tmpt = min(tmpt,max(DFBox(ap-vec3(-0.1,-0.1,0.),vec3(0.1,0.2,1.9)),-length(ap.xy-vec2(-0.125,0.1))+0.075));
        //Small pillar
        rp = vec3(ap.x,Rotate(ap.yz,0.78539816339));
        tmpt = min(tmpt,max(max(DFBox(rp-vec3(-0.1,-0.1,1.),vec3(0.1,0.2,0.9)),-length(rp.xy-vec2(-0.125,0.1))+0.075),
                    -length(rp.xy-vec2(-0.125,-0.1))+0.075));
        //Donuts
        aplen = length(ap.yz);
        tmpt = min(tmpt,max(max(length(vec2(ap.x,aplen-1.))-0.1,-length(vec2(ap.x+0.125,aplen-1.1))+0.075),
                   -length(vec2(ap.x+0.125,aplen-0.9))+0.075));
        tmpt = min(tmpt,max(max(length(vec2(ap.x,aplen-1.9))-0.1,-length(vec2(ap.x+0.125,aplen-2.))+0.075),
                   -length(vec2(ap.x+0.125,aplen-1.8))+0.075));
        //Check intersection
        dft += tmpt;
        if (dft>OUT.D) break;
        if (tmpt<0.001) {
            OUT = HIT(dft,vec3(0.5,0.2,0.1),0.2,0.25,0.95);
            break;
        }
    }
}

void Trace_MetalCylinders(vec3 P, vec3 D, inout HIT OUT) {
    //First vertical cylinder
    vec3 RP = P-vec3(3.5,0.,0.);
    float A = dot(RP.xz,RP.xz)-0.0289; //R = 0.17
    float B = 2.*dot(RP.xz,D.xz);
    float C = dot(D.xz,D.xz);
    float cP = B/C;
    float cQ = A/C;
    float det = cP*cP*0.25-cQ;
    if (det>=0.) {
        //Valid intersection
        det = sqrt(det);
        float t0 = -cP*0.5-det;
        float t1 = -cP*0.5+det;
        vec3 sp = P+D*t0;
        if (t0>0. && t0<OUT.D && sp.y<3.4) {
            OUT = HIT(t0,vec3(1.),0.025,1.,1.);
        }
    }
    //Bent cylinder
    float dft = 0.; float tmpt,aplen; vec3 ap,rp;
    for (int i=0; i<128; i++) {
        //SDF
        ap = P+D*dft;
        aplen = length(ap.xy-vec2(3.1,3.4));
        tmpt = max(max(length(vec2(ap.z,aplen-0.4))-0.17,-ap.y+3.4),-ap.x+3.1);
        aplen = length(ap.xz-vec2(1.5,0.4));
        tmpt = min(tmpt,max(max(length(vec2(ap.y-3.8,aplen-0.4))-0.17,ap.x-1.5),-ap.z-0.25));
        //Check intersection
        dft += tmpt;
        if (dft>OUT.D) break;
        if (tmpt<0.001) {
            OUT = HIT(dft,vec3(1.),0.025,1.,1.);
            break;
        }
    }
    //Horisontal cylinder
    RP = P-vec3(3.5,3.8,0.);
    A = dot(RP.yz,RP.yz)-0.0289; //R = 0.18
    B = 2.*dot(RP.yz,D.yz);
    C = dot(D.yz,D.yz);
    cP = B/C;
    cQ = A/C;
    det = cP*cP*0.25-cQ;
    if (det>=0.) {
        //Valid intersection
        det = sqrt(det);
        float t0 = -cP*0.5-det;
        float t1 = -cP*0.5+det;
        vec3 sp = P+D*t0;
        if (t0>0. && t0<OUT.D && sp.x<=3.11 && sp.x>=1.5) {
            OUT = HIT(t0,vec3(1.),0.025,1.,1.);
        }
    }
}

void Trace_RoundBox(vec3 P, vec3 D, vec3 Size, float R, inout HIT OUT) {
    float dft = 0.; float tmpt;
    for (int i=0; i<128; i++) {
        //SDF
        tmpt = DFBox(P+D*dft,Size)-R;
        //Check intersection
        dft += tmpt;
        if (dft>OUT.D) break;
        if (tmpt<0.001) {
            OUT = HIT(dft,vec3(0.47,0.35,0.25),0.3,0.05,0.6);
            break;
        }
    }
}

void Trace_Cylinder0(vec3 P, vec3 D, inout HIT OUT) {
    float A = dot(P.xz,P.xz)-0.04;
    float B = 2.*dot(P.xz,D.xz);
    float C = dot(D.xz,D.xz);
    float cP = B/C;
    float cQ = A/C;
    float det = cP*cP*0.25-cQ;
    if (det>=0.) {
        //Valid intersection
        det = sqrt(det);
        float t0 = -cP*0.5-det;
        float t1 = -cP*0.5+det;
        vec3 sp = P+D*t0;
        if (t0>0. && t0<OUT.D && abs(sp.y-(0.05+(sin(atan(sp.x,sp.z)*4.+0.1)*0.5+0.5)*0.05))<0.1) {
            OUT = HIT(t0,vec3(1.),0.,0.25,0.);
        } else if (t1>0.) {
            sp = P+D*t1;
            if (t1<OUT.D && abs(sp.y-(0.05+(sin(atan(sp.x,sp.z)*4.+0.1)*0.5+0.5)*0.05))<0.1) {
                OUT = HIT(t1,vec3(1.),0.,0.25,0.);
            }
        }
    }
}

void Trace_Door(vec3 P, vec3 D, inout HIT OUT) {
    //Wood door
    float dft = 0.; float tmpt; vec3 sp;
    for (int i=0; i<128; i++) {
        //SDF
        sp = P+D*dft;
        tmpt = DFBox(sp-vec3(0.01),vec3(0.88,2.08,0.03))-0.01;
        //Higher carving
        tmpt = min(max(tmpt,-DFBox(sp-vec3(0.2,1.1,-0.01),vec3(0.5,0.8,0.))+0.05),
                   DFBox(sp-vec3(0.3,1.2,0.04),vec3(0.3,0.6,0.))-0.01);
        tmpt = min(max(tmpt,-DFBox(sp-vec3(0.2,0.15,-0.01),vec3(0.5,0.6,0.))+0.05),
                   DFBox(sp-vec3(0.3,0.25,0.04),vec3(0.3,0.4,0.))-0.01);
        //Check intersection
        dft += tmpt;
        if (dft>OUT.D) break;
        if (tmpt<0.001) {
            OUT = HIT(dft,vec3(0.9),0.2,0.1,0.3);
            break;
        }
    }
    //Handle
    dft = 0.;
    for (int i=0; i<128; i++) {
        //SDF
        tmpt = DFLine(P+D*dft,vec3(0.88,0.9,-0.04),vec3(0.78,0.9,-0.04))-0.02;
        tmpt = min(tmpt,DFLine(P+D*dft,vec3(0.88,0.9,-0.04),vec3(0.88,0.9,0.))-0.02);
        //Check intersection
        dft += tmpt;
        if (dft>OUT.D) break;
        if (tmpt<0.001) {
            OUT = HIT(dft,vec3(0.9,0.7,0.2),0.03,0.8,0.9);
            break;
        }
    }
}

void Trace_DoorFrame(vec3 P, vec3 D, inout HIT OUT) {
    //Wood door
    float dft = 0.; float tmpt; vec3 sp;
    for (int i=0; i<128; i++) {
        //SDF
        sp = P+D*dft;
        tmpt = max(DFBox(sp-vec3(-0.15,0.,-0.08),vec3(0.15,2.25,0.08)),
                   -DFLine(sp,vec3(-0.15,0.,-0.12),vec3(-0.15,2.25,-0.12))+0.1);
        tmpt = min(tmpt,max(DFBox(sp-vec3(0.9,0.,-0.08),vec3(0.15,2.25,0.08)),
                   -DFLine(sp,vec3(1.05,0.,-0.12),vec3(1.05,2.25,-0.12))+0.1));
        tmpt = max(min(tmpt,DFBox(sp-vec3(0.,2.1,-0.08),vec3(0.9,0.15,0.08))),
                   -DFLine(sp,vec3(-0.15,2.25,-0.12),vec3(1.05,2.25,-0.12))+0.1);
        //Check intersection
        dft += tmpt;
        if (dft>OUT.D) break;
        if (tmpt<0.001) {
            OUT = HIT(dft,vec3(0.2,0.1,0.04),0.2,0.1,0.5);
            break;
        }
    }
}

void Trace_Sphere(vec3 P, vec3 D, inout HIT OUT) {
    //Wood door
    float dft = 0.; float tmpt;
    for (int i=0; i<128; i++) {
        //SDF
        tmpt = length(P+D*dft-vec3(3.1,0.5,1.))-0.5;
        //Check intersection
        dft += tmpt;
        if (dft>OUT.D) break;
        if (tmpt<0.001) {
            OUT = HIT(dft,vec3(1.),0.04,1.,1.);
            break;
        }
    }
}

//Trace function
HIT Trace(vec3 P, vec3 D, float Time) {
    HIT OUT = HIT(1000000000.,vec3(1.),-1.,-1.,-1.);
    vec3 ID = 1./D;
    //Ground and floor
    if (D.y<0.) {
        float GDist = -(P.y+0.1)/D.y;
        OUT = HIT(GDist,vec3(0.2),0.15,0.6,1.);
    }
    vec2 bb = box(P,ID,vec3(0.,-0.1,0.),vec3(4.,0.,4.)); //Floor
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT.D) OUT = HIT(bb.x,vec3(0.2,0.1,0.04),0.2,0.1,0.1);
    
    //X-Normal wall
    vec2 bb2 = box(P,ID,vec3(3.5,-0.1,0.),vec3(4.1,4.,4.));
    if (bb2.x>0. && bb2.y>bb2.x && bb2.x<OUT.D || DFBox(P-vec3(3.5,-0.1,0.),vec3(0.6,4.1,4.))<=0.) {
        //Wall
        bb = box(P,ID,vec3(4.,-0.1,0.),vec3(4.1,4.,4.));
        if (bb.x>0. && bb.y>bb.x && bb.x<OUT.D) {
            OUT = HIT(bb.x,vec3(1.),0.1,0.75,0.05);
            //Emissive circle
            float CLen = length(P.zy+D.zy*bb.x-2.);
            float CX = atan(P.z+D.z*bb.x-2.,P.y+D.y*bb.x-2.);
            if (CLen<1.9 && P.x+D.x*bb.x<4.05) {
                OUT.M = 3.;
                //Broken windows
                if ((CX>0. && CX<1.5707963 && CLen<0.9) ||
                    (CX>2.35619449 && CLen>0.9)) OUT.M = 4.5;
            }
        }
        //Window frame
        Trace_WindowFrame(P-vec3(4.,2.,2.),D,OUT);
    }
    
    //Z-Normal wall
    bb2 = box(P,ID,vec3(0.,-0.1,3.6),vec3(4.,4.,4.1));
    if (bb2.x>0. && bb2.y>bb2.x && bb2.x<OUT.D || DFBox(P-vec3(0.,-0.1,3.6),vec3(4.,4.1,0.5))<=0.) {
        //Wall
        bb = box(P,ID,vec3(0.,-0.1,4.),vec3(4.,4.,4.1));
        if (bb.x>0. && bb.y>bb.x && bb.x<OUT.D) OUT = OUT = HIT(bb.x,vec3(1.,0.1,0.1),0.3,0.5,0.2);
        //Metal cylinders
        Trace_MetalCylinders(P-vec3(0.,-0.15,3.8),D,OUT);
        Trace_MetalCylinders(P-vec3(-0.8,-0.65,3.8),D,OUT);
        //Door
        Trace_Door(P-vec3(1.2,0.,3.95),D,OUT);
        Trace_DoorFrame(P-vec3(1.2,0.,4.),D,OUT);
        //Leaning wood
        vec3 RP = P-vec3(0.1,0.02,3.7); RP.yz = Rotate(RP.yz,-0.08);
        vec3 RD = D; RD.yz = Rotate(RD.yz,-0.08);
        bb = box(RP,1./RD,vec3(0.),vec3(0.24,2.8,0.06));
        if (bb.x>0. && bb.y>bb.x && bb.x<OUT.D) OUT = HIT(bb.x,vec3(0.6,0.3,0.09),0.2,0.1,0.05);
        RP = RP+vec3(0.08,0.06,0.06);
        bb = box(RP,1./RD,vec3(0.),vec3(0.24,2.8,0.06));
        if (bb.x>0. && bb.y>bb.x && bb.x<OUT.D) OUT = HIT(bb.x,vec3(0.6,0.3,0.09),0.2,0.1,0.05);
        RP = RP+vec3(-0.1,0.06,0.06);
        bb = box(RP,1./RD,vec3(0.),vec3(0.24,2.8,0.06));
        if (bb.x>0. && bb.y>bb.x && bb.x<OUT.D) OUT = HIT(bb.x,vec3(0.6,0.3,0.09),0.2,0.1,0.05);
    }
    
    //Boxes close to vec3(4,0,4)
    bb2 = box(P,ID,vec3(2.,0.,1.5),vec3(4.,3.,4.));
    if (bb2.x>0. && bb2.y>bb2.x && bb2.x<OUT.D || DFBox(P-vec3(2.,0.,1.5),vec3(2.,3.,2.5))<=0.) {
        //Boxes
        vec3 RP = P-vec3(3.1,0.,3.); RP.xz = Rotate(RP.xz,0.9);
        vec3 RD = D; RD.xz = Rotate(RD.xz,0.9);
        Trace_RoundBox(RP,RD,vec3(0.45),0.05,OUT);
        RP = P-vec3(2.45,0.05,3.); RP.xz = Rotate(RP.xz,-0.1);
        RD = D; RD.xz = Rotate(RD.xz,-0.1);
        Trace_RoundBox(RP,RD,vec3(0.45,0.55,0.45),0.05,OUT);
        //Rotated box
        RP = P-vec3(2.4,0.3,2.12); RP.xz = Rotate(RP.xz,0.3); RP.zy = Rotate(RP.zy,0.8);
        RD = D; RD.xz = Rotate(RD.xz,0.3); RD.zy = Rotate(RD.zy,0.8);
        Trace_RoundBox(RP,RD,vec3(0.65,1.2,0.35),0.05,OUT);
    }
    
    //Sphere
    Trace_Sphere(P,D,OUT);
    
    //Rotating block
    float TAngle = Time;
    vec3 RP = P-vec3(-1.,-0.1,3.); RP.xz = Rotate(RP.xz,TAngle);
    vec3 RD = D; RD.xz = Rotate(RD.xz,TAngle);
    bb = box(RP,1./RD,vec3(-0.8,0.,-0.05),vec3(0.8,0.8,0.1));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT.D) OUT = HIT(bb.x,vec3(0.),0.1,0.5,0.);
    
    //Return
    return OUT;
}