// Common (common) — Light Propagation by Mathis
// https://www.shadertoy.com/view/4d3fWX

//SETTINGS
const float VoxelisationDist=0.353;
//CONSTANTS
const vec2 eps=vec2(0.0005,0.);
const float i32=1./32.;
const float SAFram=0.24145316170843;
const float SASida=0.18443362850791;
const float i9=1./0.999;
const vec3 Offsets[3]=vec3[3](vec3(1.,0.,0.),vec3(0.,1.,0.),vec3(0.,0.,1.));
const vec2 Offsets2[9]=vec2[9](vec2(0.,0.),vec2(0.25,0.25),vec2(0.,0.25),vec2(-0.25,0.25),
                              vec2(0.25,0.),vec2(-0.25,0.),vec2(0.25,-0.25),vec2(0.,-0.25),vec2(-0.25,-0.25));
//Resolution
#define ires 1./iResolution.xy
#define Aspect vec2(iResolution.x/iResolution.y,1.)
//Sun
#define SunColor vec3(1.,0.9,0.7)*4.5
//Sky
#define SkyColor vec3(0.1,0.3,0.8)

struct DF { lowp vec3 c; highp float d; float Mat; };
struct Hit { vec3 P; vec3 N; vec3 C; float D; float Mat; };

float Box(vec3 p, vec3 b) {
    vec3 d=abs(p-b*0.5)-b*0.5;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float BoxC(vec3 p, vec3 b) {
    vec3 d=abs(p)-b;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

vec2 Rotate(vec2 p, float ang) {
    float c=cos(ang), s=sin(ang);
    return vec2(p.x*c-p.y*s,p.x*s+p.y*c);
}

vec2 Repeat(vec2 p, float n) {
    float ang=2.*3.14159/n;
    float sector=floor(atan(p.x,p.y)/ang+0.5);
    p=Rotate(p,sector*ang);
    return p;
}

float Plane(vec3 p, vec3 n, float offs) {
  return dot(p,n)-offs;
}

float Line(vec3 p, vec3 a, vec3 b) {
    vec3 ba=b-a;
    float k=dot(p-a,ba)/dot(ba,ba);
    return length((a+clamp(k,0.,1.)*(b-a))-p);
}

float smin(float a, float b, float k) {
    float h=clamp(0.5+0.5*(b-a)/k,0.,1.);
    return mix(b,a,h)-k*h*(1.-h);
}

void minn(inout DF df, DF a) {
    df.d=((a.d<=df.d)?a.d:df.d);
    df.c=((a.d<=df.d)?a.c:df.c);
    df.Mat=((a.d<=df.d)?a.Mat:df.Mat);
}

void maxx(inout DF df, DF a) {
    if (a.d>=df.d) df=a;
}

DF SDF(vec3 p, float Time) {
    DF df=DF(vec3(1.),p.y-1.,0.);
    //Yttre väggar
 	df.d=min(df.d,Box(p-vec3(0.,1.,0.),vec3(1.,6.,18.))); //Sida
    df.d=min(df.d,Box(p-vec3(0.,1.,0.),vec3(32.,10.,1.))); //Bakre sida
    df.d=min(df.d,Box(p-vec3(31.,1.,0.),vec3(1.,6.,18.))); //Andra sida
    df.d=min(df.d,Box(p-vec3(13.,1.,18.),vec3(32.-13.,6.,1.))); //Främre sida vit
    //Grönt rum
    df.d=min(df.d,Box(p-vec3(0.,1.,18.),vec3(8.,6.,1.))); //Framför grön
    df.d=min(df.d,Box(p-vec3(7.,1.,8.),vec3(1.,6.,10.))); //Bredvid grön
    	df.d=min(df.d,Box(p-vec3(7.,1.,1.),vec3(1.,6.,5.))); //Bredvid grön liten
    	//Stänger
    	df.d=min(df.d,Box(p-vec3(0.,7.,14.),vec3(8.,1.,1.)));
    	df.d=min(df.d,Box(p-vec3(0.,7.,11.),vec3(8.,1.,1.)));
    	df.d=min(df.d,Box(p-vec3(0.,7.,8.),vec3(8.,1.,1.)));
    	df.d=min(df.d,Box(p-vec3(0.,7.,5.),vec3(8.,1.,1.)));
    	//Objekt på golvet
    	if (Box(p-vec3(2.,1.,8.),vec3(6.,3.,6.))<0.) {
            df.d=min(df.d,Box(p-vec3(3.,1.,9.),vec3(1.,1.,1.)));
            df.d=min(df.d,Box(p-vec3(4.,1.,12.),vec3(1.,2.,1.)));
    	}
    //Closed rum
    df.d=min(df.d,Box(p-vec3(20.,1.,12.),vec3(1.,6.,6.))); //Sida
    df.d=min(df.d,Box(p-vec3(19.,6.,9.),vec3(12.,1.,10.))); //Tak
        //df.d=min(df.d,Box(p-vec3(2.,12.,2.),vec3(28.,1.,20.)));
    //Sfär linje
    vec3 rp=p-vec3(14.,5.,1.);
    minn(df,DF(vec3(1.,0.1,0.1),length(vec3(rp.x,rp.y,fract(rp.z*0.125)*8.-4.))-3.5,0.));
    //Färgade väggar
    minn(df,DF(vec3(0.,1.,0.),Box(p-vec3(1.,1.,17.),vec3(6.,6.,1.)),0.)); //Främre sida grön
    	//Bord
    	minn(df,DF(vec3(0.8,0.5,0.3),Box(p-vec3(3.,1.,3.),vec3(1.,2.,1.)),0.));
    	minn(df,DF(vec3(0.8,0.5,0.3),Box(p-vec3(2.,3.,2.),vec3(3.,1.,3.)),0.));
   	minn(df,DF(vec3(0.,1.,1.),Box(p-vec3(30.,1.,12.),vec3(1.,3.,6.)),1.)); //Emissive
    	minn(df,DF(vec3(1.),Box(p-vec3(28.,4.,12.),vec3(3.,1.,6.)),0.)); //Blocker över
    	minn(df,DF(vec3(1.),Box(p-vec3(27.,1.,14.),vec3(1.,2.,2.)),0.)); //Blocker framför
    //Return
	return df;
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

vec3 NT(vec3 N, out vec3 Bit) {
    if (abs(N.y)>0.999) {
        Bit=vec3(1.,0.,0.);
        return vec3(0.,0.,1.);
    } else {
    	Bit=normalize(cross(N,vec3(0.,1.,0.)));
    	return normalize(cross(Bit,N));
    }
}

vec3 StoreV(vec3 a, vec3 b) {
    a=clamp(a,0.,1.); b=clamp(b,0.,1.); //Behövs?
    return floor(a*1000.)+b*0.999;
}

vec3 ReadV(vec3 v, out vec3 NC) {
    NC=fract(v)*i9;
    return floor(v)*0.001; //returnerar positiva sidans färg
}

vec3 ReadVP(vec3 v) { return floor(v)*0.001; }
vec3 ReadVN(vec3 v) { return fract(v)*i9; }

vec2 PToUV(vec3 p) {
    float ZZ=((p.z<16.)?0.:32.);
    return vec2(floor(p.x)+floor(mod(p.z,16.))*32.,floor(p.y)+ZZ)+0.5;
}

float boxfar(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin=(bmin-origin)*dir;
    vec3 tMax=(bmax-origin)*dir;
    vec3 t2=max(tMin,tMax);
    return min(min(t2.x,t2.y),t2.z);
}

vec2 box(vec3 origin, vec3 dir, vec3 bmin, vec3 bmax) {
    vec3 tMin=(bmin-origin)*dir;
    vec3 tMax=(bmax-origin)*dir;
    vec3 t1=max(tMin,tMax);
    vec3 t2=min(tMin,tMax);
    return vec2(max(max(t2.x,t2.y),t2.z),min(min(t1.x,t1.y),t1.z));
}