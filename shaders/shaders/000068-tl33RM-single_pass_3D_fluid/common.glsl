// Common (common) — single pass 3D fluid by flockaroo
// https://www.shadertoy.com/view/tl33RM

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// single pass 3D fluid dynamics

// same fluid as in "molten bismut" but generalized to 3 dimensions
// ...but with self-consistent-ish velocity field
// the previous method was just defined implicitely by the rotations on multiple scales
// here the calculated velocity field is put back into the stored field

//...helper funcs

//#define OBSTACLE

#define PI2 6.283185

#define Res0 vec2(1024)
#define Res1 vec2(textureSize(iChannel1,0))

vec2 uvSmooth(vec2 uv,vec2 res)
{
    // no interpolation
    //return uv;
    // sinus interpolation
    //return uv+.8*sin(uv*res*PI2)/(res*PI2);
    // iq's polynomial interpolation
    vec2 f = fract(uv*res);
    return (uv*res+.5-f+3.*f*f-2.0*f*f*f)/res;
}

vec4 inverseQuat(vec4 q)
{
    //return vec4(-q.xyz,q.w)/length(q);
    // if already normalized this is enough
    return vec4(-q.xyz,q.w);
}

vec4 multQuat(vec4 a, vec4 b)
{
    return vec4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz));
}

vec3 transformVecByQuat( vec3 v, vec4 q )
{
    return v + 2.0 * cross( q.xyz, cross( q.xyz, v ) + q.w*v );
}

vec4 axAng2Quat(vec3 ax, float ang)
{
    return vec4(normalize(ax),1)*sin(vec2(ang*.5)+vec2(0,PI2*.25)).xxxy;
}

//////// Fluid lookup funcs

const vec3 FRes=vec3(70,100,50);
//const vec3 FRes=vec3(90);

vec4 coord3to2(vec3 p)
{
    p.z-=.5;
    p=mod(p+FRes+FRes,FRes);
    p.xy=clamp(p.xy,vec2(.5),FRes.xy-.5);
    ivec2 N=ivec2(Res0/FRes.xy);
    int z1=int(p.z)%int(FRes.z);
    int z2=(z1+1)%int(FRes.z);
    vec2 xy1 = p.xy + vec2( float(z1%N.x)*FRes.x, float(z1/N.x)*FRes.y );
    vec2 xy2 = p.xy + vec2( float(z2%N.x)*FRes.x, float(z2/N.x)*FRes.y );
    return vec4(xy1,xy2);
}

vec3 coord2to3(vec2 c)
{
    ivec2 N=ivec2(Res0/FRes.xy);
    vec2 cr=c/FRes.xy;
    vec2 indXY=floor(cr);
    vec2 cm=(cr-indXY)*FRes.xy;
    //vec2 cm=mod(c,FRes.xy);
    return vec3(cm,indXY.x+indXY.y*float(N.x)+.5);
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - (b-r);
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdRoundedCylinder( vec3 p, float R, float r, float h )
{
  vec2 d = vec2( length(p.xz)-R, abs(p.y) - h*.5 );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - r;
}

float distTorus(vec3 p, float R, float r)
{
    return length(p-vec3(normalize(p.xy),0)*R)-r;
}

float sdCone( vec3 p, vec2 c )
{
  // c is the sin/cos of the angle
  float q = length(p.xy);
  return dot(c,vec2(q,p.z));
}

float dDirLine(vec3 p, vec3 c, vec3 dir, float l)
{
    p-=c;
    dir=normalize(dir);
    float dp=dot(p,dir);
    //return length(p-dp*dir);
    return max(max(length(p-dp*dir),-dp),dp-l);
}

vec3 fluidPos(vec3 p)
{
    float lmin=min(FRes.x,min(FRes.y,FRes.z));
    return p*lmin*.5+FRes*.5;
}

vec3 distPos(vec3 p)
{
    float lmin=min(FRes.x,min(FRes.y,FRes.z));
    return (p-.5*FRes)/(lmin*.5);
}

#define WheelFR vec3( 0.8, 1.2,-0.1)
#define WheelRadius 0.45
#define ObjBoundRadius 3.5

// smoothed minimum - copied from iq's site (https://iquilezles.org/articles/smin)
float smin2( float a, float b, float k ) { return -log2( exp2( -k*a ) + exp2( -k*b ) )/k; }

float distCar(vec3 pos)
{
    pos.x=abs(pos.x);
    if(dot(pos,pos)>ObjBoundRadius*ObjBoundRadius) return length(pos)-ObjBoundRadius*0.5;
    float dist = 100000.0;
    dist = min(dist, sdRoundBox(pos-vec3(0.0,-0.5,0.7),vec3(0.75-0.15,1.1-0.15,0.5-0.15)*1.2,0.15));
    pos.y=abs(pos.y);
    dist = smin2(dist, sdRoundBox(pos-vec3(0.0, 0.0,0.3),vec3(0.8-0.1, 1.8-0.1,0.35-0.1)*1.2,0.1),10.0);
    dist = max(dist, -(length((pos-WheelFR).yzx)-WheelRadius*1.2));
    dist = min(dist, distTorus((pos-WheelFR).yzx,WheelRadius-0.15,0.15));
    return dist;
}

float obstacleDist(vec3 p)
{
    //// car
    return distCar((p*vec3(1,-1,1)-vec3(0,0,-.2))*1.8)/1.8;
    ////// sphere
    //float d=length(p)-.35;
    //// cylinder
    //float d=length(p.yz)-.35;
    //// plane
    float d=sdRoundBox( transformVecByQuat(p-vec3(0,0,-0.1),axAng2Quat(vec3(1,0,0),.6)), vec3(.45,.45,.05), 0.02 );
    //d=max(d,p.y);
    return d;
}

vec3 obstacleGrad(vec3 p,float delta)
{
    float v=obstacleDist(p);
    vec2 d=vec2(delta,0); return vec3( obstacleDist(p+d.xyy)-v,
                                       obstacleDist(p+d.yxy)-v,
                                       obstacleDist(p+d.yyx)-v )/delta;
}

