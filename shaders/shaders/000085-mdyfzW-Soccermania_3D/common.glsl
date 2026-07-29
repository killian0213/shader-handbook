// Common (common) — Soccermania 3D by kastorp
// https://www.shadertoy.com/view/mdyfzW

#define R iResolution
#define PC vec2(.95,.52) //pitch size 
#define F_START 180 //waiting time before kick off
#define tk .004 //line thickness
#define CORNERS 2 //0=disabled, 2= enable corners & throw-ins
//#define ZERO min(iFrame, 0)
#define SIZE 20.
#define coord(p) (p*min(R.y/PC.y/2.,R.x/PC.x/2.)/1.05 + R.xy*.5)
#define position(U) ((U - R.xy*.5) /min(R.y/PC.y/2.,R.x/PC.x/2.)*1.05)
#define score(s,p,b,d) s*(.2 +b.x)*(.03+  smoothstep(.05,.2,abs( d.w-d.y))*2.)*smoothstep(PC.y*.95,PC.y*.6,abs(p.y))*step(.03,length(b.xy-p.xy))
#define TDIST .7 
//------------sdf functions 
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0))  + min(max(d.x,d.y),0.0);
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

//----------------------------------
// from https://www.shadertoy.com/view/3tyfzV
void drawChar(sampler2D ch, inout vec3 color, in vec3 charColor, in vec2 p, in vec2 pos, in vec2 size, in int char) {
    p = (p - pos) / size + 0.5;
    if (all(lessThan(abs(p - 0.5), vec2(0.5)))) {
        float val = textureGrad(ch, p / 16.0 + fract(vec2(char, 15 - char / 16) / 16.0), dFdx(p / 16.0), dFdy(p / 16.0)).r;
        color = mix(color, charColor, val);
    }
}

                    
//-----------Intersection functions--------------------

//@Blackle
vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}
                    
#define NOHIT 1e5
vec3 oFuv; 
vec3 oNor;
vec2 iSphere( in vec3 ro, in vec3 rd, float ra )
{
    vec3 oc = ro ;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0. ) return vec2(NOHIT); // no intersection
    h = sqrt( h );
    oNor =normalize(ro-(b+h)*rd); oFuv=vec3(0.,atan(oNor.y,length(oNor.xz)),atan(oNor.z,oNor.x))*ra*1.5708  ;
    return h-b < 0. ? vec2(NOHIT) : -b-h>=0. ?  vec2(-b-h,+b-h): vec2(0.);

}

vec2 iBox( in vec3 ro, in vec3 rd, vec3 boxSize) 
{

    vec3 m = 1./rd; 
    vec3 n = m*ro;   
    vec3 k = abs(m)*boxSize;

    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.) return vec2(NOHIT); // no intersection
    oNor = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz); 
    oFuv=vec3( dot(abs(oNor),vec3(1,5,9)+ oNor)/2.,dot(ro+rd*tN,oNor.zxy),dot(ro+rd*tN,oNor.yzx));   
    return tN<0.? vec2(0.): vec2(tN,tF);

}

vec2 iPlane( in vec3 ro, in vec3 rd, in vec3 n ,float h)
{

    float d= -(dot(ro,n)+h)/dot(rd,n);
    oFuv.yz=(ro+d*rd).xz;
    oNor=n;
    return d>0.?vec2(d,NOHIT):vec2(NOHIT);

}