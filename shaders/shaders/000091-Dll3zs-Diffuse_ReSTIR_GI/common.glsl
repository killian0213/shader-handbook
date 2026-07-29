// Common (common) — Diffuse ReSTIR GI by Mathis
// https://www.shadertoy.com/view/Dll3zs

//Settings
const float FOV = radians(85.); //In radians
const vec3 SkyLight = vec3(0.15,0.6,1.)*0.75;
const vec3 SunLight = vec3(1.,0.7,0.4)*3.5;
const float SunCR = 0.08;
const float EmissiveStrength = 3.75;
const float M_CLAMP_T = 16.; //Temporal M clamp (diffuse)
#define Spatial_Unbiased_RT

//Other vars
const float ExternalLightFactor = 2.; //Factor outside of the color clamped value
const float LightCoeff = 5.;
const float ILightCoeff = 1./LightCoeff;
const float FAR = 256.;
const float CFOV = tan(FOV*0.5);
const float PI = 3.141592653;
const float IPI = 1./PI;
const float PI2 = PI*2.;
const float IPI2 = 0.5/PI;
const float I3 = 1./3.;
const float I16 = 1./16.;
const float I32 = 1./32.;
const float I64 = 1./64.;
const float I256 = 1./256.;
const float I300 = 1./300.;
const float I512 = 1./512.;
const float I1024 = 1./1024.;
const float I2048 = 1./2048.;
const vec2 eps = vec2(0.,0.00025);
#define RES iChannelResolution[0].xy
#define IRES (1./iChannelResolution[0].xy)
#define ASPECT vec2(RES.x/RES.y,1.)

const vec2 SSOffsets[16] = vec2[16](vec2(0.),vec2(-0.4,-0.4),vec2(0.,0.2),vec2(0.15,-0.4),vec2(-0.4,-0.15),
                                    vec2(0.15,0.4),vec2(-0.2,-0.2),vec2(-0.4,0.4),vec2(0.4,0.15),vec2(0.2,-0.2),
                                    vec2(0.4,0.4),vec2(-0.4,0.15),vec2(0.4,-0.15),
                                    vec2(-0.15,0.4),vec2(0.4,-0.4),vec2(-0.15,-0.4));
//SKY
vec3 SampleSky(vec3 d, float Time) {
    return SkyLight*pow(max(0.,d.y),0.25); //*pow(max(0.,sin(Time*0.85+1.)),0.25);
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

vec4 MIN(vec4 d, vec4 nd) {
    return ((nd.w<d.w)?nd:d);
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

vec3 ARand23(vec2 uv) {
    //Analytic random
    return fract(sin(uv.x*uv.y)*vec3(403.125,486.125,513.432)+cos(dot(uv,vec2(13.18273,51.2134)))*vec3(173.137,261.23,203.127));
}

float ARand21(vec2 uv) {
    //Analytic random
    return fract(sin(uv.x*uv.y)*403.125+cos(dot(uv,vec2(13.18273,51.2134)))*173.137);
}

vec2 box(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin = (bmin-origin)*dir;
    vec3 tMax = (bmax-origin)*dir;
    vec3 t1 = min(tMin,tMax);
    vec3 t2 = max(tMin,tMax);
    return vec2(max(max(t1.x,t1.y),t1.z),min(min(t2.x,t2.y),t2.z));
}

vec2 boxfarNormal(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin=(bmin-origin)*dir;
    vec2 tMax=(bmax-origin)*dir;
    vec2 t2=max(tMin,tMax);
    vec2 signdir = -(max(vec2(0.),sign(dir))*2.-1.);
    if (t2.x<t2.y) return vec2(signdir.x,0.);
    else return vec2(0.,signdir.y);
}

//Non-optimal vec2/vec3 to float functions
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
    return vec2((floor(fract(v)*2048.)+0.5)*I2048,(floor(v)+0.5)*I2048);
}

float Vec2ToFloat(vec2 v) {
    v = min(v,vec2(0.9999));
    return v.x+floor(v.y*2048.);
}

vec2 FloatToVec2WM(float v) {
    float x = fract(v);
    float y = floor(mod(v,100.));
    return vec2(x,y);
}

float Vec2ToFloatWM(vec2 v) {
    return min(v.x,0.99999)+floor(v.y);
}

//Tracer
vec3 C_DarkWood(vec3 uv) {
    //uv in ([0,1],[0,1])
    vec3 fuv = floor(uv*vec3(4.,16.,16.))+0.5;
    vec2 RV = ARand23(fuv.xy*2.15362+fuv.z*1.43).xy;
    return mix(vec3(0.15,0.1,0.05),vec3(0.3,0.15,0.06)*RV.x,RV.y);
}

vec3 C_Planks(vec2 uv) {
    //uv in ([0,1],[0,1])
    vec2 fuv = floor(uv*vec2(16.,4.)-0.001)+0.5;
    vec2 RV = ARand23(fuv).xy;
    return mix(vec3(0.7,0.4,0.13),vec3(0.6,0.45,0.325)*RV.x,RV.y)*(0.25+0.75*float(
               DFBox(fract(uv*vec2(4.,1.)-0.001-vec2(0.,floor(uv.x*4.)*0.75)),vec2(1.-0.125,1.-I32))<0.));
}

vec3 C_Bricks(vec2 uv) {
    //uv in ([0,1],[0,1])
    vec2 fuv = floor(uv*vec2(16.,8.))+0.5;
    if ((fuv.y>4. && abs(fuv.x-3.5)<0.1) || (fuv.y<4. && abs(fuv.x-11.5)<0.1) || fuv.y<1. || abs(fuv.y-4.5)<0.1) return vec3(0.2);
    return vec3(0.9,0.25,0.1);
}

vec4 SDF(vec3 p, float Time) {
    vec4 d = vec4(vec3(0.1,0.85,0.1),p.y+0.1);
    
    //Floor
    d = MIN(d,vec4(C_Planks(p.xz),DFBox(p-vec3(0.,-0.1,0.),vec3(6.,0.1,8.))));
    
    //X-Normal wall with door
    d = MIN(d,vec4(C_Bricks(fract(p.zy*vec2(1.5,3.01))),DFBox(p-vec3(0.,0.,3.),vec3(0.1,2.5,5.))));
    
    //X-Normal wall with opposite
    d = MIN(d,vec4(C_Bricks(fract(p.zy*vec2(1.5,3.01))),DFBox(p-vec3(5.9,0.,0.),vec3(0.1,2.5,8.))));
    
    //Z-Normal wall
    d = MIN(d,vec4(C_Bricks(fract(p.xy*vec2(1.5,3.01))),DFBox(p-vec3(0.,0.,0.),vec3(5.9,2.5,0.1))));
    d = MIN(d,vec4(C_Bricks(fract(p.xy*vec2(1.5,3.01))),DFBox(p-vec3(0.1,0.,7.9),vec3(5.8,2.5,0.1))));
    
    //Ceiling wood
    if (DFBox(p-vec3(-0.2,2.4,-0.2),vec3(6.4,1.,8.4))<0.) {
        d = MIN(d,vec4(C_DarkWood(p),DFBox(p-vec3(-0.15,2.5,-0.15),vec3(6.3,0.3,0.3))));
        d = MIN(d,vec4(C_DarkWood(p),DFBox(p-vec3(-0.15,2.5,3.),vec3(6.3,0.3,0.3))));
        d = MIN(d,vec4(C_DarkWood(p),DFBox(p-vec3(-0.15,2.5,5.35),vec3(6.3,0.3,0.3))));
        d = MIN(d,vec4(C_DarkWood(p),DFBox(p-vec3(-0.15,2.5,7.85),vec3(6.3,0.3,0.3))));
    }
    
    //Rotated wood
    vec3 RP = p-vec3(3.,2.8,4.); RP.xz = Rotate(RP.xz,max(0.,Time-1.)*0.6);
    d = MIN(d,vec4(vec3(0.2),DFBox(RP-vec3(-2.5,0.,-4.2),vec3(5.,0.2,8.4))));
    
    //Random rotated box grid
    if (DFBox(p-vec3(0.,0.,3.),vec3(6.,2.5,5.))<0.) {
        vec3 fp = floor(p);
        vec3 Rand3 = ARand23(fp.xz+0.25);
        vec3 RP = p-vec3(fp.x+0.5,0.,fp.z+0.5); RP.xz = Rotate(RP.xz,Rand3.x*1.5);
        float Radius = 0.4-0.2*Rand3.x;
        d = MIN(d,vec4(C_DarkWood(RP.zyx)*3.,DFBox(RP-vec3(-Radius,0.,-Radius),vec3(2.*Radius,fp.z*fp.z*0.045,2.*Radius))));
    }
    
    d = MIN(d,vec4(C_Planks(p.xz),DFBox(p-vec3(1.,1.,0.05),vec3(2.,0.1,1.45))));
    d = MIN(d,vec4(C_DarkWood(p),DFBox(p-vec3(1.,0.,0.05),vec3(0.1,1.,1.45))));
    d = MIN(d,vec4(C_DarkWood(p),DFBox(p-vec3(2.9,0.,0.05),vec3(0.1,1.,1.45))));
    
    //Output
    return d;
}

vec3 Gradient(vec3 p, float Time, out vec4 SDFS) {
    SDFS = SDF(p,Time);
    return normalize(vec3(SDF(p+eps.yxx,Time).w,SDF(p+eps.xyx,Time).w,SDF(p+eps.xxy,Time).w)-SDFS.w);
}

float Trace_Sphere(vec3 Pos, vec3 Dir) {
    //Ray tracing against geometry
    float dfs; float D=0.;
    for (int i=0; i<654; i++) {
        dfs = length(Pos+Dir*D-vec3(1.5,0.5,1.5))-0.5;
        if (min(FAR-D,dfs-0.0002)<0.) {
            return D;
        }
        D += dfs;
    }
    return FAR+1.;
}

float Trace(vec3 P, vec3 D, float Time) {
    float OUT = 100000.;
    vec3 ID = 1./D;
    //Ground
    if (D.y<0.) OUT = -(P.y+0.1)/D.y;
    
    //Floor
    vec2 bb = box(P,ID,vec3(0.,-0.1,0.),vec3(6.,0.,8.));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT) OUT = bb.x;
    
    //X-Normal wall with door
    bb = box(P,ID,vec3(0.,0.,3.),vec3(0.1,2.5,8.));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT) OUT = bb.x;
    
    //X-Normal wall opposite
    bb = box(P,ID,vec3(5.9,0.,0.),vec3(6.,2.5,8.));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT) OUT = bb.x;
    
    //Z-Normal wall
    bb = box(P,ID,vec3(0.,0.,0.),vec3(5.9,2.5,0.1));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT) OUT = bb.x;
    bb = box(P,ID,vec3(0.1,0.,7.9),vec3(5.9,2.5,8.));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT) OUT = bb.x;
    
    //Ceiling
    bb = box(P,ID,vec3(-0.2,2.5,-0.2),vec3(6.2,2.8,8.2));
    if ((bb.x>0. && bb.y>bb.x) || DFBox(P-vec3(-0.2,2.4,-0.2),vec3(6.4,1.,8.4))<0.) {
        bb = box(P,ID,vec3(-0.15,2.5,-0.15),vec3(6.15,2.8,0.15));
        if (bb.x>0. && bb.y>bb.x) OUT = min(OUT,bb.x);
        bb = box(P,ID,vec3(-0.15,2.5,3.),vec3(6.15,2.8,3.3));
        if (bb.x>0. && bb.y>bb.x) OUT = min(OUT,bb.x);
        bb = box(P,ID,vec3(-0.15,2.5,5.35),vec3(6.15,2.8,5.65));
        if (bb.x>0. && bb.y>bb.x) OUT = min(OUT,bb.x);
        bb = box(P,ID,vec3(-0.15,2.5,7.85),vec3(6.15,2.8,8.15));
        if (bb.x>0. && bb.y>bb.x) OUT = min(OUT,bb.x);
    }
    
    //Rotated wood
    vec3 RP = P-vec3(3.,2.8,4.); RP.xz = Rotate(RP.xz,max(0.,Time-1.)*0.6);
    vec3 RD = D; RD.xz = Rotate(RD.xz,max(0.,Time-1.)*0.6);
    bb = box(RP,1./RD,vec3(-2.5,0.,-4.2),vec3(2.5,0.2,4.2));
    if (bb.x>0. && bb.y>bb.x) OUT = min(OUT,bb.x);
    
    //Random rotated box grid
    bb = box(P,ID,vec3(0.,0.,3.),vec3(6.,2.5,8.));
    if ((bb.x>0. && bb.y>bb.x) || DFBox(P-vec3(0.,0.,3.),vec3(6.,2.5,5.))<0.) {
        //Per 1x1 meter
        vec3 StartPos = P;
        if (bb.x>0. && bb.y>bb.x) StartPos = P+D*(bb.x+0.001);
        vec3 fp = floor(StartPos); vec3 RP,RD,Rand3; float Radius;
        for (int i=0; i<16; i++) {
            if (DFBox(fp.xz+0.5-vec2(0.,3.),vec2(6.,5.))>0.) break;
            Rand3 = ARand23(fp.xz+0.25);
            RP = P-vec3(fp.x+0.5,0.,fp.z+0.5); RP.xz = Rotate(RP.xz,Rand3.x*1.5);
            RD = D; RD.xz = Rotate(RD.xz,Rand3.x*1.5);
            Radius = 0.4-0.2*Rand3.x;
            bb = box(RP,1./RD,vec3(-Radius,0.,-Radius),vec3(Radius,fp.z*fp.z*0.045,Radius));
            if (bb.x>0. && bb.y>bb.x) { OUT = min(OUT,bb.x); }
            fp.xz -= boxfarNormal(P.xz,ID.xz,fp.xz,fp.xz+1.);
        }
    }
    
    bb = box(P,ID,vec3(1.,1.,0.05),vec3(3.,1.1,1.5));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT) OUT = bb.x;
    bb = box(P,ID,vec3(1.,0.,0.05),vec3(1.1,1.,1.5));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT) OUT = bb.x;
    bb = box(P,ID,vec3(2.9,0.,0.05),vec3(3.,1.,1.5));
    if (bb.x>0. && bb.y>bb.x && bb.x<OUT) OUT = bb.x;
    
    //Return
    return OUT;
}