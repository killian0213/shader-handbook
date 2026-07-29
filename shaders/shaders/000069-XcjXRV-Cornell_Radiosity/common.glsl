// Common (common) — Cornell Radiosity by Mathis
// https://www.shadertoy.com/view/XcjXRV

//Constants
const float FOV = radians(90.);
const vec3 DSP = vec3(0.3125 ,0.21,0.35);
const vec3 CameraPos = vec3(0.5,0.501,-0.5);
const float LightCoeff = 8.;
const float ILightCoeff = 1./LightCoeff;
const float CFOV = tan(FOV*0.5);
const float PI = 3.141592653;
const float HPI = PI*0.5;
const float IPI = 1./PI;
const float PI2 = PI*2.;
const float IPI2 = 0.5/PI;
const float ToRadians = PI/180.;
const float I3 = 1./3.;
const float I12 = 1./12.;
const float I16 = 1./16.;
const float I24 = 1./24.;
const float I32 = 1./32.;
const float I48 = 1./48.;
const float I64 = 1./64.;
const float I128 = 1./128.;
const float I256 = 1./256.;
const float I512 = 1./512.;
const float I1024 = 1./1024.;
const float I2048 = 1./2048.;
const vec2 eps = vec2(0.00025,0.);
//RES
#define RES iChannelResolution[0].xy
#define IRES (1./iChannelResolution[0].xy)
#define ASPECT vec2(RES.x/RES.y,1.)
#define RESOff max(mod(iChannelResolution[0].xy,8.),vec2(0.,1.))

struct HIT { vec3 v; vec4 m; };

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

float DFLine(vec2 p, vec2 a, vec2 b) {
    vec2 ba = b-a;
    float k = dot(p-a,ba)/dot(ba,ba);
    return length((a+clamp(k,0.,1.)*(b-a))-p);
}

float DFCylinder(vec3 p, float r, float h) {
    vec2 d = vec2(length(p.xz)-r,abs(p.y)-h);
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}

float DFCone(vec3 p, float CR, float h) {
    //Credit: iq
    vec2 q = h*vec2(CR,-1.);
    vec2 w = vec2(length(p.xz),p.y);
    vec2 a = w-q*clamp(dot(w,q)/dot(q,q),0.,1.);
    vec2 b = w-q*vec2(clamp( w.x/q.x,0.,1.),1.);
    float k = sign(q.y);
    float d = min(dot(a,a),dot(b,b));
    float s = max(k*(w.x*q.y-w.y*q.x),k*(w.y-q.y));
    return sqrt(d)*sign(s);
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

vec2 Repeat0(vec2 p, float n) {
    float ang = 2.*3.14159/n;
    float sector = clamp(floor(atan(p.x,p.y)/ang+0.5),5.,7.);
    p = Rotate(p,sector*ang);
    return p;
}

vec2 Repeat1(vec2 p, float n) {
    float ang = 2.*3.14159/n;
    float sector = clamp(floor(atan(p.x,p.y)/ang+0.5),-10.,10.);
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
        Nb = vec3(1.,0.,0.);
        Nt = vec3(0.,0.,1.);
    } else {
    	Nb = normalize(cross(N,vec3(0.,1.,0.)));
    	Nt = normalize(cross(Nb,N));
    }
    return mat3(Nb.x,Nt.x,N.x,Nb.y,Nt.y,N.y,Nb.z,Nt.z,N.z);
}

vec3 TBN(vec3 N, out vec3 O) {
    O = ((abs(N.y)<=0.999)?normalize(cross(N,vec3(0.,1.,0.))):vec3(1.,0.,0.));
    return normalize(cross(O,N));
}

vec3 RandSample(vec2 v) {
    float r = sqrt(1.-v.x*v.x);
    float phi = 2.*3.14159*v.y;
    return vec3(cos(phi)*r,sin(phi)*r,v.x);
}

vec3 RandSampleCos(vec2 v) {
    float theta = sqrt(v.x);
    float phi = 2.*3.14159*v.y;
    float x = theta*cos(phi);
    float z = theta*sin(phi);
    return vec3(x,z,sqrt(max(0.,1.-v.x)));
}

vec3 SchlickFresnel(vec3 r0, float angle) {
    //Schlick Fresnel approximation
    return r0+(1.-r0)*pow(1.-angle,5.);
}

vec3 BRDF_GGX(vec3 w_o, vec3 w_i, vec3 n, float alpha, vec3 F0) {
    vec3 h = normalize(w_i+w_o);
    float a2 = alpha*alpha;
    float D = a2/(PI*pow(pow(dot(h,n),2.)*(a2-1.)+1.,2.));
    vec3 F = F0+(1.-F0)*pow(1.-dot(n,w_o),5.);
    float k = a2*0.5;
    float G = 1./((dot(n,w_i)*(1.-k)+k)*(dot(n,w_o)*(1.-k)+k));
    vec3 OUT = F*(D*G*0.25);
    return ((isnan(OUT)!=bvec3(false))?vec3(0.):OUT);
}

float IntegrateQuad(vec3 P, vec3 N, vec3 p0, vec3 p1, vec3 p2, vec3 p3) {
    //Returns the cosine integral over a quad
    //*
    vec3 v0 = normalize(p0-P);
    vec3 v1 = normalize(p1-P);
    vec3 v2 = normalize(p2-P);
    vec3 v3 = normalize(p3-P);
    float ret = abs(dot(N,normalize(cross(v0,v1)))*acos(dot(v0,v1))+
                    dot(N,normalize(cross(v1,v2)))*acos(dot(v1,v2))+
                    dot(N,normalize(cross(v2,v3)))*acos(dot(v2,v3))+
                    dot(N,normalize(cross(v3,v0)))*acos(dot(v3,v0)));
    return ((isnan(ret))?0.:ret);
    //*/
    
    //Paper: https://ieeexplore.ieee.org/abstract/document/4121581
    //Solid angle
    /*
    vec3 a = p0-P;
    vec3 b = p1-P;
    vec3 c = p2-P;
    vec3 d = p3-P;
    float al = length(a);
    float bl = length(b);
    float cl = length(c);
    float dl = length(d);
    return 2.*(atan(dot(a,cross(b,c))/(al*bl*cl+dot(a,b)*cl+dot(a,c)*bl+dot(b,c)*al))+
               atan(dot(a,cross(c,d))/(al*cl*dl+dot(a,c)*dl+dot(a,d)*cl+dot(c,d)*al)));
    //*/
}

vec3 ARand23(vec2 uv) {
    //Analytic random
    return fract(sin(uv.x*uv.y)*vec3(403.125,486.125,513.432)+cos(dot(uv,vec2(13.18273,51.2134)))*vec3(173.137,261.23,203.127));
}

float ARand21(vec2 uv) {
    //Analytic random
    return fract(sin(uv.x*uv.y)*403.125+cos(dot(uv,vec2(13.18273,51.2134)))*173.137);
}

vec3 APlane(vec3 P, vec3 D, vec3 Tan, vec3 Bit, vec3 Nor, vec2 Size) {
    float NorDot = dot(Nor,D);
    float PDot = dot(Nor,P);
    if (sign(NorDot*PDot)<-0.5) {
        float t = -PDot/NorDot;
        vec2 Hit2 = vec2(dot(P+D*t,Tan),dot(P+D*t,Bit));
        if (DFBox(Hit2,Size)<0.) return vec3(Hit2,t);
    }
    return vec3(-1.);
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

float ABoxfar(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t2 = max(tMin,tMax);
    return min(t2.x,t2.y);
}

vec2 ABoxfarNormal(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t2 = max(tMin,tMax);
    vec2 signdir = (max(vec2(0.),sign(dir))*2.-1.);
    if (t2.x<t2.y) return vec2(signdir.x,0.);
    else return vec2(0.,signdir.y);
}

vec3 ABoxfarNormal(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax, out float dist) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t2 = max(tMin,tMax);
    dist = min(min(t2.x,t2.y),t2.z);
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

vec3 floatToVec3(float v) {
    //Returns vec3 from int
    int VPInt = floatBitsToInt(v);
    int VPInt1024 = VPInt%1024;
    int VPInt10241024 = ((VPInt-VPInt1024)/1024)%1024;
    return vec3(VPInt1024,VPInt10241024,((VPInt-VPInt1024-VPInt10241024)/1048576))*I1024;
}

float vec3ToFloat(vec3 v) {
    //Returns "int" from vec3 (10 bit per channel)
    ivec3 intv = min(ivec3(floor(v*1024.)),ivec3(1023));
    return intBitsToFloat(intv.x+intv.y*1024+intv.z*1048576);
}

vec2 floatToVec2(float v) {
    //Returns vec3 from int
    int VPInt = floatBitsToInt(v);
    int VPInt16k = VPInt%1048576;
    return vec2(VPInt16k,((VPInt-VPInt16k)/1048576)%1048576);
}

float vec2ToFloat(vec2 v) {
    //Returns "int" from vec3 (10 bit per channel)
    ivec2 intv = min(ivec2(floor(v*1048576.)),ivec2(1048575));
    return intBitsToFloat(intv.x+intv.y*1048576);
}

vec2 floatToVec2WM(float v) {
    return vec2(fract(v),floor(v));
}

float vec2ToFloatWM(vec2 v) {
    return min(v.x,0.99999)+floor(v.y);
}

float TraceSphere(vec3 p, vec3 d, float r) {
    float P = 2.*dot(p,d);
    float Q = dot(p,p)-r*r;
    float pow2 = P*P*0.25-Q;
    if (P<0. && pow2>0.) {
        float t = -P*0.5-sqrt(pow2);
        vec3 hitp = p+d*t;
        return t;
    } else {
        return -1.;
    }
}

HIT Trace(vec3 P, vec3 D, float Time) {
    //Ray tracing
    vec3 ID = 1./D;
    HIT OUT = HIT(vec3(-2.,-2.,1000000),vec4(0.));
    
    //Floor
    if (max(-P.y,D.y)<0.) {
        float t = -P.y/D.y;
        if (DFBox(P.xz+D.xz*t,vec2(1.))<0.) {
            OUT = HIT(vec3((P+D*t).xz*24.,t),vec4(0.,0.,24.,24.));
        }
    }
    //Ceiling
    if (max(P.y-1.,-D.y)<0.) {
        float t = -(P.y-1.)/D.y;
        if (t<OUT.v.z && DFBox(P.xz+D.xz*t,vec2(1.))<0.) {
            OUT = HIT(vec3(vec2(24.,0.)+(P+D*t).xz*24.,t),vec4(24.,0.,24.,24.));
        }
    }
    
    
    //X Walls
    if (max(-P.x,D.x)<0.) {
        //Red wall
        float t = -P.x/D.x;
        if (t<OUT.v.z && DFBox(P.zy+D.zy*t,vec2(1.))<0.) {
            OUT = HIT(vec3(vec2(0.,24.)+(P.zy+D.zy*t)*24.,t),vec4(0.,24.,24.,24.));
        }
    }
    if (max(P.x-1.,-D.x)<0.) {
        //Green wall
        float t = -(P.x-1.)/D.x;
        if (t<OUT.v.z && DFBox(P.zy+D.zy*t,vec2(1.))<0.) {
            OUT = HIT(vec3(vec2(24.,24.)+(P.zy+D.zy*t)*24.,t),vec4(24.,24.,24.,24.));
        }
    }
    
    //Z Walls
    if (max(P.z-1.,-D.z)<0.) {
        float t = -(P.z-1.)/D.z;
        vec2 tuv = (P.xy+D.xy*t)*24.-vec2(8.,0.);
        if (t<OUT.v.z && DFBox(tuv,vec2(16.,24.))<0.) {
            OUT = HIT(vec3(vec2(48.,0.)+tuv,t),vec4(48.,0.,16.,24.));
        }
    }
    
    
    //Sphere diffuse
    vec3 RP = P-DSP;
    float spherehit = TraceSphere(RP,D,0.2);
    if (spherehit>-0.5 && spherehit<OUT.v.z) {
        vec3 hitp = RP+D*spherehit;
        float theta = atan(length(hitp.xz),hitp.y);
        theta = theta*IPI*16.;
        float thetaFloor = floor(theta);
        float YRes = 1.+ceil(30.*sin(thetaFloor/15.*PI));
        float phiUV = (atan(hitp.x,hitp.z)*IPI*0.5+0.5)*YRes;
        OUT = HIT(vec3(vec2(48.,24.)+vec2(theta,phiUV/YRes),spherehit),vec4(-1.));
    }
    
    //Sphere specular
    spherehit = TraceSphere(P-vec3(0.75,0.225,0.7),D,0.225);
    if (spherehit>-0.5 && spherehit<OUT.v.z) {
        OUT = HIT(vec3(vec2(65.5),spherehit),vec4(-1.));
    }
    
    
    
    RP = P-vec3(4.*I24,0.,13.*I24);
    RP.xz = Rotate(RP.xz,-0.8);
    vec3 RD = D; RD.xz = Rotate(RD.xz,-0.8);
    if (max(RP.z,-RD.z)<0.) {
        //Front
        float t = -RP.z/RD.z;
        vec2 tuv = (RP.xy+RD.xy*t)*24.;
        if (t<OUT.v.z && DFBox(tuv,vec2(12.,16.))<0.) {
            OUT = HIT(vec3(vec2(0.,48.)+tuv,t),vec4(0.,48.,12.,16.));
        }
    }
    if (max(-RP.z+2.*I24,RD.z)<0.) {
        //Back
        float t = -(RP.z-2.*I24)/RD.z;
        vec2 tuv = (RP.xy+RD.xy*t)*24.;
        if (t<OUT.v.z && DFBox(tuv,vec2(12.,16.))<0.) {
            OUT = HIT(vec3(vec2(12.,48.)+tuv,t),vec4(12.,48.,12.,16.));
        }
    }
    if (max(RP.x,-RD.x)<0.) {
        //Side +
        float t = -RP.x/RD.x;
        vec2 tuv = (RP.zy+RD.zy*t)*24.;
        if (t<OUT.v.z && DFBox(tuv,vec2(2.,16.))<0.) {
            OUT = HIT(vec3(vec2(24.,48.)+tuv,t),vec4(24.,48.,2.,16.));
        }
    }
    if (max(-RP.y+0.66666666666,RD.y)<0.) {
        //Side +
        float t = -(RP.y-0.66666666666)/RD.y;
        vec2 tuv = (RP.xz+RD.xz*t)*24.;
        if (t<OUT.v.z && DFBox(tuv,vec2(12.,2.))<0.) {
            OUT = HIT(vec3(vec2(26.,48.)+tuv.yx,t),vec4(26.,48.,2.,12.));
        }
    }
    
    //Output
    return OUT;
}