// Image (image) — Dice Game | Die Die Die by byt3_m3chanic
// https://www.shadertoy.com/view/Nl23Rw

/**

     _____     __     ______     ______        ______     ______     __    __     ______    
    /\  __-.  /\ \   /\  ___\   /\  ___\      /\  ___\   /\  __ \   /\ "-./  \   /\  ___\   
    \ \ \/\ \ \ \ \  \ \ \____  \ \  __\      \ \ \__ \  \ \  __ \  \ \ \-./\ \  \ \  __\   
     \ \____-  \ \_\  \ \_____\  \ \_____\     \ \_____\  \ \_\ \_\  \ \_\ \ \_\  \ \_____\ 
      \/____/   \/_/   \/_____/   \/_____/      \/_____/   \/_/\/_/   \/_/  \/_/   \/_____/ 
                                                                                           

    @byt3_m3chanic | 06/13/2021
    
    more typography stuff | die = 1 dice

*/

#define R   iResolution
#define M   iMouse
#define T   iTime
#define PI  3.14159265359
#define PI2 6.28318530718

#define MAX_DIST    100.
#define MIN_DIST    .001

float sampleFreq(float freq) { return texture(iChannel0, vec2(freq, 0.25)).x;}
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }
mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float vmax(vec3 p){ return max(max(p.x,p.y),p.z); }

float box(vec3 p, vec3 b)
{
	vec3 d = abs(p) - b;
	return length(max(d,vec3(0))) + vmax(min(d,vec3(0)));
}
//@iq
float box(vec3 p, vec3 b, in vec4 r )
{   r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
	vec3 d = abs(p) - b+vec3(r.x,0,0);
	return length(max(d,vec3(0))) + vmax(min(d,vec3(0)));
}
float box( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
float box( in vec2 p, in vec2 b, in vec4 r )
{
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}
// Letters from 2D to 3D extruded SDF's
float getD(vec2 uv)
{
    float letd = box(uv,vec2(.125,.25),vec4(.125,.125,.00,0));
    letd=abs(letd)-.05;
    letd=min(box(uv+vec2(.125, .0),vec2(.05,.3)),letd);
    return letd;
}
float getI(vec2 uv)
{
    uv.y=abs(uv.y);
    float leti = box(uv,vec2(.05,.3));
    leti = min(box(uv-vec2(.0, .25),vec2(.20,.05)),leti);
    return leti;
}
float getC(vec2 uv)
{
    float letc = box(uv-vec2(.125,0),vec2(.25,.25),vec4(0,0,.2,.2));
    letc=abs(letc)-.05;
    letc=max(letc,-box(uv-vec2(.715 , .0),vec2(.5,.5)));
    return letc;
}
float getE(vec2 uv)
{
    uv.y=abs(uv.y);
    float lete = box(uv-vec2(.0, .0),vec2(.05,.3));
    lete = min(box(uv-vec2(.1, .0),vec2(.10,.05)),lete);
    lete = min(box(uv-vec2(.125, .25),vec2(.15,.05)),lete);
    return lete;
}
//@iq
float opx(in float sdf, in float pz, in float h){
    vec2 w = vec2( sdf, abs(pz) - h );
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}
vec3 hit=vec3(0),hitPoint=vec3(0);
float glow=0.,g_hs,s_hs;
float mtime,time;
mat2 turn,r90,r180;

float dice(vec3 p)
{
    vec3 p3 = vec3(abs(p.x),p.y,abs(p.z));
    vec3 p2 = vec3(abs(p.x),p.yz);
    
    float dz = .1;
    float ox = .35;
    float cz = .575;
    
    float base = box(p,vec3(.5,.5,.5))-.075;
    // has to be a better way - I dont know it yet
    float dots;
    dots = length(abs(p)-vec3(ox,ox,cz))-dz;
    dots = min(length(p2-vec3(cz,ox,ox))-dz,dots);
    dots = min(length(p2-vec3(cz,-ox,-ox))-dz,dots);
    dots = min(length(p3-vec3(ox,-cz,ox))-dz,dots);
    dots = min(length(p3-vec3(ox,-cz,0))-dz,dots);
    dots = min(length(p-vec3(cz,0,0))-dz,dots);
    dots = min(length(p-vec3(0,cz,0))-dz,dots);
    dots = min(length(p-vec3(0,0,cz))-dz,dots);
    
    base = max(base,-dots);
    
    return base;
}

vec2 map(vec3 pos, float sg)
{
    pos.y+=.85;
    vec2 res = vec2(1e5,0.);
    vec3 q = pos-vec3(0.,.75,0.);
    vec3 p = pos-vec3(0.,.5,0.);

    q.xz*=turn;

    float amount = 8.;
    float a = atan(q.z, q.x);
    //@shane rep
    float ia = floor(a/6.2831853*amount);
    ia = (ia + .5)/amount*6.2831853;
    //id and wave
    float id = -mod(ia,.0);
    float cy = sin( id*2. + (iTime * .5) * PI) * 0.5;
    q.y +=cy;
    q.xz *= rot(ia);
    q.x -= 3.65;
  
    float hs = hash21(vec2(id,3.34));
    int pk = int(floor(hs*10.));
    //turn dice to random side
    vec3 dp = q;
    dp.yx*=turn;
    dp.zx*=turn;
    if(pk==1) dp.yz*=r90;
    if(pk==2) dp.yz*=-r90;
    if(pk==3) dp.xy*=r90;
    if(pk==4) dp.xy*=-r90;
    if(pk==5) dp.xy*=r180;

    float d1 = dice(dp);
    if(d1<res.x){
        res = vec2(d1,2.);
        hit=p;
        g_hs=hs;
    }

    p.yz+=vec2(-1.5,.0);
    p*=.35;
    
    float ld=getD(p.xz+vec2(.70,0.));
    ld=abs(abs(ld)-.025)-.0075;
    float td = opx(ld,p.y,.025);
    
    float li=getI(p.xz+vec2(.20,0.));
    li=abs(abs(li)-.025)-.0075;
    float ti = opx(li,p.y,.025);    

    float lc=getC(p.xz-vec2(.30,0.));
    lc=abs(abs(lc)-.025)-.0075;
    float tc = opx(lc,p.y,.025); 
    
    float le=getE(p.xz-vec2(.70,0.));
    le=abs(abs(le)-.025)-.0075;
    float te = opx(le,p.y,.025); 
    
    td=min(ti,td);
    td=min(tc,td);
    td=min(te,td);
    
    if(td<res.x)
    {
        res=vec2(td,3.);
    	hit=pos;
    }
    
    if(sg>0.) glow += .0001/(.01+td*td);

    float flr = pos.y+1.5;
    if(flr<res.x)
    {
        res=vec2(flr,1.);
    	hit=pos;
    }
    
    return res;
}

vec3 normal(vec3 p, float t)
{
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e,0.).x+
             h.yyx * map(p+h.yyx*e,0.).x+
             h.yxy * map(p+h.yxy*e,0.).x+
             h.xxx * map(p+h.xxx*e,0.).x;
    return normalize(n);
}

vec2 marcher(vec3 ro, vec3 rd, int maxsteps, float sg){
	float d = 0.;
    float m = 0.;
    for(int i=0;i<maxsteps;i++){
    	vec2 ray = map(ro + rd * d, sg);
        if(ray.x<MIN_DIST*d||d>MAX_DIST) break;
        d += ray.x * .75;
        m  = ray.y;
    }
	return vec2(d,m);
}

vec4 FC = vec4(0.078,0.078,0.078,0.);

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, bool last, inout float d, vec2 uv) {

    vec3 C = vec3(0);
    vec2 ray = marcher(ro,rd,192, 1.);

    hitPoint = hit;
    s_hs=g_hs;
    d = ray.x;
    float m = ray.y;
    float alpha = 0.;
    if(d<MAX_DIST)
    {
        vec3 p = ro + rd * d;
        vec3 n = normal(p,d);
        vec3 lpos =vec3(3,8,-8);
        vec3 l = normalize(lpos-p);
        
        vec3 h = vec3(.5);


        float diff = clamp(dot(n,l),0.,1.);
        float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 5.);
        fresnel = mix(.01, .7, fresnel);

        float shdw = 1.0;
        for( float t=.01; t < 12.; )
        {
            float h = map(p + l*t,0.).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 16.*h/t);
            t += h * .95;
            if( shdw<MIN_DIST || t>32. ) break;
        }
        
        diff *= shdw;
        
        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec =  0.5 * pow(max(dot(view, ret), 0.), (m==2.||m==4.)?24.:64.);

        if(m==1.){
        vec3 clr =mix(vec3(0.000,0.502,0.016),vec3(0.043,0.529,0.596),uv.y+.5);
            h=vec3(.15);
            //big back visualizer
            vec2 uv = (hitPoint.xz-vec2(0,0))*1.5;
            vec2 f = fract(uv)-.5;
            vec2 fid = floor(uv)+.5;
            float ht = sampleFreq(abs(fid.x)*.05);
            float ff = box(f,vec2(.45));
            ff=smoothstep(.011,.01,ff);
            
            if(ht>abs(fid.y*.095)) h=mix(h,clr,ff);
            
            ref = vec3(.8)-fresnel;
            C+=diff*h;
        }
        
        if(m==2.){
            vec3 hp = hitPoint;
            h=s_hs>.5?vec3(0):vec3(1);
            ref = vec3(.6)-fresnel;
            C+=(diff*h)+spec;
        }
  
        if(m==3.){
            h=vec3(.95);
            ref = vec3(.6)-fresnel;
            C+=diff*h;
        }

        ro = p+n*.01;
        rd = reflect(rd,n);
    
    } else {
        C = FC.rgb;ref=vec3(.35);
    }

    C = mix(FC.rgb,C,  exp(-.000025*d*d*d));     
    
   // 
    return vec4(C,alpha);
}

void mainImage( out vec4 O, in vec2 F )
{   
    r90=rot(90.*PI/180.);
    r180=rot(180.*PI/180.);
    mtime=floor(abs(T));
    turn = rot(T*20.*PI/180.);
    
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0,0,6.25);
    vec3 rd = normalize(vec3(uv,-1));
    // camera //
    mat2 rx =rot(-1.4);
    mat2 ry =rot(-.2);
    ro.zy*=rx;rd.zy*=rx;
    ro.xz*=ry;rd.xz*=ry;
    // camera //
    
    vec3 C = vec3(0);
    vec3 ref=vec3(0), fil=vec3(1);
    float d =0.;
    float numBounces = 3.;
    for(float i=0.; i<numBounces; i++) {
        vec4 pass = render(ro, rd, ref, i==numBounces-1., d, uv);
        C += pass.rgb*fil;
        fil*=ref;
        // first bounce - get fog layer
        if(i==0.) FC = vec4(FC.rgb,exp(-.000015*d*d*d));
    }
    
    //glow 
    glow=clamp(glow,0.,.85);
    vec3 clr =mix(vec3(0.024,0.878,0.733),vec3(0.337,0.839,0.000),uv.y+.5);
    C = mix(C,clr,glow);
    //layer fog in   
    C = mix(C,FC.rgb,1.-FC.w);
    // gamma
    C = pow(C, vec3(.4545));
    O = vec4(C,1.0);
}


