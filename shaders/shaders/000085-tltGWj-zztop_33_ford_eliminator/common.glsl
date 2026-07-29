// Common (common) — zztop '33 ford eliminator by flockaroo
// https://www.shadertoy.com/view/tltGWj

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// zztop ford eliminator

// helper functions

//uncomment to precalc logo as texture
//#define ZZT_AS_TEX

#define PI2 6.283185

#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 vec2(textureSize(iChannel1,0))

vec3 getLightDir() { return normalize(1.*vec3(cos(1.+/*iTime+*/vec2(0,1.6)),.81)); }

vec2 scuv(vec2 uv) {
    float zoom=1.;
    return (uv-.5)*1.2*zoom+.5; 
}

vec2 uvSmooth(vec2 uv,vec2 res)
{
    // no interpolation
    //return uv;
    // sinus interpolation
    return uv+1.*sin(uv*res*PI2)/(res*PI2);
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
    return (v + 2.0 * cross( q.xyz, cross( q.xyz, v ) + q.w*v ));
}

vec4 angVec2Quat(vec3 ang)
{
    float lang=length(ang);
    return vec4(ang/lang,1) * sin(vec2(lang*.5)+vec2(0,PI2*.25)).xxxy;
}

vec4 axAng2Quat(vec3 ax, float ang)
{
    return vec4(normalize(ax),1)*sin(vec2(ang*.5)+vec2(0,PI2*.25)).xxxy;
}

/////////////// iq's distance funs

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - (b-r);
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdRoundRect( vec2 p, vec2 b, float r )
{
  vec2 q = abs(p) - (b-r);
  return length(max(q,0.0)) + min(max(q.x,q.y),0.0) - r;
}

vec2 sdRoundRect2( vec4 p, vec4 b, vec2 r )  // variation - eval 2 boxes at once
{
  vec4 q = abs(p) - (b-r.xxyy);
  vec4 qp=max(q,0.0);
  return sqrt(qp.xz*qp.xz+qp.yw*qp.yw) + min(max(q.xz,q.yw),vec2(0)) - r;
}

float sdHalfRoundBox( vec3 p, vec3 b, float r )   // variation - clamped box
{
  vec3 q = abs(p) - (b-r);
  return max((length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r),-p.z);
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

// iq's exponantial smooth-min func
float smin( float a, float b, float k )
{
    k=3./k;
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

// iq's polynomial smooth-min func
float smin_( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
#if 0
bool intersectBox(vec3 p, vec3 dir, vec3 size)
{
    //vec3 n=cross(cross(dir,p),dir);
    //return length(p-dot(p,n)*n/dot(n,n))<size.y;

    //return true;
    
    size*=.5;
    float tmin, tmax, tymin, tymax, tzmin, tzmax; 
    
    vec3 s=sign(dir);
    vec3 invdir=1./dir;

    tmin  = (-size.x*s.x - p.x) * invdir.x; 
    tmax  = ( size.x*s.x - p.x) * invdir.x; 
    tymin = (-size.y*s.y - p.y) * invdir.y; 
    tymax = ( size.y*s.y - p.y) * invdir.y; 
 
    if ((tmin > tymax) || (tymin > tmax)) return false; 
    if (tymin > tmin) tmin = tymin; 
    if (tymax < tmax) tmax = tymax; 
 
    tzmin = (-size.z*s.z - p.z) * invdir.z; 
    tzmax = ( size.z*s.z - p.z) * invdir.z; 
 
    if ((tmin > tzmax) || (tzmin > tmax)) return false; 
    if (tzmin > tmin) tmin = tzmin; 
    if (tzmax < tmax) tmax = tzmax; 
 
    return true; 
}
#endif
bool intersectBox(vec3 p, vec3 dir, vec3 size)
{
    size*=.5*sign(dir);

    vec3 vmin = (-size-p)/dir;
    vec3 vmax = ( size-p)/dir;
    
    float tmin=vmin.x, tmax=vmax.x;
    
    if ((tmin > vmax.y) || (vmin.y > tmax)) return false; 
    tmin=max(tmin,vmin.y);
    tmax=min(tmax,vmax.y);
 
    if ((tmin > vmax.z) || (vmin.z > tmax)) return false; 
    tmin=max(tmin,vmin.z);
    tmax=min(tmax,vmax.z);
 
    return true; 
}

float zmask(vec2 p)
{
    float skew=1.;
    p.x += skew*p.y;
    return step(p.y,step(-.35,p.x)-.5+.1)
          -step(p.y,step( .35,p.x)-.5-.1);
}

vec4 zztop(vec2 p, float s_)
{
    float s=-1.;
    p.x=-p.x;
    vec2 p0=p;
    p0*=-s_;
    float s1=step(-12.6+2.9+2.9*s,-s_*((p.x)+s*.17*p0.y));
    float z1 = zmask(p0+vec2(.25,.1))*step(-3.5,-p0.x-p0.y)*s1;
    float d1=-.25*p.y+z1;
    float z2 = zmask(p0-vec2(.25,.1))*step(-6.,-p0.x-p0.y)*s1;
    float d2=.25*p.y+z2;
    float bgm=step(0.,-s_*s*p.x)*step(-.7,-abs(p.y));
    p.y=abs(p.y);
    bgm=max(bgm,step(.5,exp(-(p.y-.8)*(p.y-.8)/.017)));
    bgm*=step(-29.,-s_*(s*(p.x)-30.*p0.y));
    bgm*=step(-15.,-s_*(s*(p.x)+15.*p0.y));
    bgm*=step(-12.75,-s_*(-s*(p.x)-.17*p0.y));
    vec4 bg=vec4(.5);
    bg=clamp(bg,0.,1.);
    vec4 col=vec4(.5,0,0,1);
    if(d2<d1) col=vec4(1,.8,0,1);
    col = mix(vec4(bgm),col,max(z1,z2));
    col.w=max(bgm,max(z1,z2));
    return col;
}

