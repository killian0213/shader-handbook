// Buffer A (buffer) — Year of Truchets #022 by byt3_m3chanic
// https://www.shadertoy.com/view/dtGGWw

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #022
    05/20/2023  @byt3_m3chanic
    
    All year long I'm going to just focus on truchet tiles and the likes!
    Truchet Core \M/->.<-\M/ 2023 
    
*/


#define R           iResolution
#define M           iMouse
#define T           iTime

#define PI          3.14159265358
#define PI2         6.28318530718

#define MIN_DIST    .0001
#define MAX_DIST    75.

// globals & const
vec3 hit,hp;
mat2 flip,turn,r90;

const vec3 size = vec3(1.25);
const vec3 hlf = size/2.;
const vec3 bs = hlf;
const vec3 grid = vec3(4.);
const vec3 lrid = vec3(3.);
const float thick = .055;

vec3 hue(float t){ return .5 + .4*cos(PI2*t*(vec3(.95,.97,.98)*vec3(0.957,0.439,0.043))); }
mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){return fract(sin(dot(p,vec2(23.43,84.21)))*4832.3234); }

float box(vec3 p,vec3 b){
    vec3 q = abs(p)-b;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float cap(vec3 p,float r,float h){
    vec2 d = abs(vec2(length(p.xy),p.z))-vec2(h,r);
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}
 
float trs( vec3 p,vec2 t){
    vec2 q = vec2(length(p.zx)-t.x,p.y);
    return length(q)-t.y;
}
float glow = 0.;

vec2 map(vec3 p, float sg){
    vec2 res = vec2(1e5,0);
  
    //@mla inversion
    float k = (9.+2.*sin(T*.1))/dot(p,p); 
    p *= k;

    p.yz*=flip; p.xz*=turn;

    vec3 q = p;
    vec3 r = p+hlf;
    
    vec3 id = floor((q + hlf)/size)-grid;
    vec3 ir = floor((r + hlf)/size)-lrid;
    
    float chk2 = mod(id.y+mod(id.z+id.x,2.),2.)*2.-1.;
    
    q = q-size*clamp(round(q/size),-grid,grid);
    r = r-size*clamp(round(r/size),-lrid,lrid);

    float hs = hash21(id.xz+id.y);
    float hf = hash21(ir.xz+ir.y+floor(T*.75));
    
    if(hs>.5) q.xz*=r90;
    if(chk2>.5) q.zy*=r90;

    float xhs = fract(2.31*hs+id.y);
    float trh = 1e5, trx = 1e5, srh = 1e5, dre = 1e5, jre=1e5;

    vec2 qv = vec2(q.xy-hlf.xy);
    trh = trs(vec3(q+vec3(0,hlf.x,-hlf.y)).yxz,vec2(hlf.x,thick));
    trx = trs(q+vec3(hlf.x,0,hlf.z),vec2(hlf.x,thick));
    jre = trs(vec3(q-vec3(hlf.xy,0)).yzx,vec2(hlf.x,thick));

    srh = min(trh,jre);
    srh = min(srh,trx);
    srh=max(srh,box(q,bs));

    if(srh<res.x ) {
        float mt = mod(floor(xhs*20.),4.)+2.;
        res = vec2(srh,mt);
    } 

    float crt = cap(vec3(q.xy,abs(q.z))-vec3(0,0,hlf),thick*.85,thick*1.5);  
    crt = min(cap(vec3(q.zy,abs(q.x))-vec3(0,0,hlf),thick*.85,thick*1.5),crt);
    crt = min(cap(vec3(q.xz,abs(q.y))-vec3(0,0,hlf),thick*.85,thick*1.5),crt);

    if(crt<res.x) {
       res = vec2(crt,12.);
    } 
    
    float gb = length(r)-(hlf.x*.25); 
    if(sg==1.  && hf>.85 ) { glow += .0001/(.0001+gb*gb);}
    if(gb<res.x && hf>.85) {
       res = vec2(gb,11.);
    } 
    
    // compensate for the scaling that's been applied
    float mul = 1./k;
    res.x = res.x* mul / 1.25;
    return res;
}

// Tetrahedron technique @iq
// https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = 1e-4*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e,0.).x+
             h.yyx * map(p+h.yyx*e,0.).x+
             h.yxy * map(p+h.yxy*e,0.).x+
             h.xxx * map(p+h.xxx*e,0.).x;
    return normalize(n);
}

void mainImage( out vec4 O, in vec2 F )
{
    vec2 uv = (2.* F.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0,0,12);
    vec3 rd = normalize(vec3(uv,-1));
    
    // mouse //
    float x = M.xy==vec2(0) ? .35 : (M.y/R.y * 2.-1.)*PI;
    float y = M.xy==vec2(0) ? .06 : (M.x/R.x * 2.-1.)*PI;

    float fl = y+(T*.135)+180./PI;
    float fx = .28*cos(fl*2.);
    flip=rot(fx);
    turn=rot(fl);
    
    r90=rot(1.5707);

    vec3 C = vec3(.0), p = ro;
    float m = 0., d = 0.;
    
    for(int i=0;i<128;i++) {
        p = ro + rd * d;
        vec2 ray = map(p,1.);
        if(ray.x<d*1e-4||d>MAX_DIST)break;
        d += i<42? ray.x*.3: ray.x * .8;
        m  = ray.y;
    } 

    if(d<MAX_DIST)
    {

        vec3 n = normal(p,d);
        vec3 lpos =  vec3(-10,10,10);
        vec3 l = normalize(lpos-p);
        
        float diff = clamp(dot(n,l),0. , 1.);
        float spec = pow(max(dot(reflect(l, n), rd ), .1), 32.)*.75;

    }

    vec3 Fog = mix(vec3(.05),vec3(.75),(uv.y+.45)*.25);
    
    C = mix(C,Fog,1.-exp(-.0001*d*d*d));
    C = mix(C,vec3(.49,.98,.52),clamp(glow*.75,0.,1.));
    
    float vw = .6+.5*sin(d*.5+T*.85);
    float fade = clamp((d*.01)+vw,0.,1.);
    vec3 clr = m==4.? vec3(.62,.36,.95): m==2. ? vec3(.95,.36,.87) : vec3(.36,.66,.95);
    if(m!=11.&&m!=12.) C = mix(C,clr,smoothstep(.35,.1,fade)); 
    
    C = pow(C, vec3(.4545));
    O = vec4(C,1.);
}
