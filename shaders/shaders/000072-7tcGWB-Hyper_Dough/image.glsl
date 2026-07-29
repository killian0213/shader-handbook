// Image (image) — Hyper Dough by Tater
// https://www.shadertoy.com/view/7tcGWB

//very inspired by this work from halfprism
//https://twitter.com/halfprism_/status/1434909264951263243
#define GLOW
#define STEPS 200.0
#define MDIST 50.0
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define sat(a) clamp(a,0.0,1.0)
#define range(a,b,r,x) (smoothstep(a-r,a+r,x)*smoothstep(b+r,b-r,x))
#define s(a) smoothstep(0.0,1.0,a)
#define pmod(p,x) (mod(p,x)-0.5*(x))

//smin & smax, probably based on IQ's version idk 
float smin(float a,float b, float k){ 
    float h=max(0.,k-abs(a-b));
    return min(a,b)-h*h*.25/k;
}

float smax(float d1,float d2,float k){
    float h=clamp(0.5-0.5*(d2+d1)/k,0.,1.);
    return mix(d2,-d1,h)+k*h*(1.0-h);
}

//https://www.shadertoy.com/view/3tjGWm
vec3 hs(vec3 c, float s){
    vec3 m=vec3(cos(s),s=sin(s)*.5774,-s);
    return c*mat3(m+=(1.-m.x)/3.,m.zxy,m.yzx);
}

//iq box sdf
float ebox(vec3 p, vec3 b){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec2 moda (vec2 p, float per){
    float a = atan(p.y,p.x);
    a = mod(a-per/2.,per)-per/2.;
    return vec2 (cos(a),sin(a))*length(p);
}

float box(vec2 p, float r){
  vec2 d = abs(p);
  return max(d.x,d.y)-r;
}

float superGon(vec2 p, float r){
  float a = box(p,r);
  p*=rot(pi/4.);
  float b = box(p,r);
  a = max(a,b);
  p*=rot(pi/8.);
  b = box(p,r);
  a = max(a,b);
  p*=rot(pi/4.);
  b = box(p,r);
  a = max(a,b);
  return a;
}

float octGon(vec2 p, float r){
  float a = box(p,r);
  p*=rot(pi/4.);
  float b = box(p,r);
  a = max(a,b);
  return a;
}

float glow = 0.;
float glow2 = 0.;
vec2 map(vec3 p){
    float t = iTime*0.85;
    vec3 po2 = p;
    p.xz*=rot(pi/4.0);
    vec3 po = p;
    
    vec2 a = vec2(1);
    vec2 b = vec2(1);
    a.x = 999.;
    float ballscl = 3.4;
    
    for(float i = 0.; i<13.0; i++){
        p.x+=tanh(cos(t*2.0+i*1.4)*8.0)*ballscl;
        p.x+=tanh(cos(t*1.0+i*2.0)*20.0)*ballscl;
        p.z+=tanh(sin(t*2.0+i*0.5)*8.0)*ballscl;
        p.z+=tanh(sin(t*1.0+i*3.5)*8.0)*ballscl;
        p.y+=sin(t*0.33+i*2.3+tanh(sin(t*1.1)*8.)*1.5)*7.5;

        b.x = length(p)-1.7;
        a.x = smin(a.x,b.x,1.3);
        p = po;
    }
    
    p.xy*=rot(pi/4.);
    float wv = 0.6;
    float disp = sin(p.x*wv+t*2.0)*sin(p.z*wv);
    p+=disp;
    p.xz = abs(p.xz)-2.6;
    
    float size = 2.75;
    b.x = ebox(p, vec3(size,0.,size))-1.7;
    b.x = smax(a.x-0.2,b.x,2.);
    a.x = min(a.x,b.x);
    
    glow+=0.6/(2.9+a.x*a.x);
    #ifdef GLOW
    //outer lines
    p = po2;
    
    p.xy*=rot(0.8);
    float space = .3;
    float width = .2;
    p.y+=t*0.75;
    vec2 c = vec2(a.x,3.0);
    
    p.y = pmod(p.y,space+width);
    float cut = abs(p.y)-space*0.5;
    
    c.x-=.3;
    c.x = abs(c.x)-0.15;
    c.x = max(c.x,-cut);
    if(c.x<0.01){
    glow2+=1.3/(2.9+c.x*c.x);
    glow-=0.5/(2.9+c.x*c.x);
    }
    glow-=0.05/(0.4+c.x*c.x);
    c.x = max(0.03,abs(c.x));

    a=(a.x<c.x)?a:c;
    #endif
    return a;
}

vec3 norm(vec3 p){
    vec2 e = vec2(0.01,0);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    
    vec3 col = vec3(0);

    vec3 ro = vec3(0,0,-28.0);
    if(iMouse.z>0.){
    ro.yz*=rot(2.0*(iMouse.y/iResolution.y-0.5));
    ro.zx*=rot(-7.0*(iMouse.x/iResolution.x-0.5));
    }
    vec3 lk = vec3(0,0.1,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = normalize(f*(1.0)+uv.x*r+uv.y*cross(f,r));  
    vec3 p = ro;
    vec2 d = vec2(0);
    bool hit = false;
    float dO = 0.;
    float blueNoise = texelFetch(iChannel0, ivec2(fragCoord)% textureSize(iChannel0, 0) , 0).r;
    ro+=rd*(blueNoise*min(10.0,map(ro).x*0.8)-0.5);

    for(float i = 0.; i<STEPS; i++){
        p = ro+rd*dO;
        d = map(p);
        dO+=d.x;
        if(abs(d.x)<0.005){
            hit = true;
            break;
        }
        if(dO>MDIST){
            break;
        }
    }
    vec3 red = vec3(0.957,0.176,0.310);
    vec3 redish = vec3(0.706,0.094,0.278);
    if(hit){
        vec3 n = norm(p);
        vec3 rr = reflect(rd,n);
        vec3 ld = normalize(vec3(-1,1.6,-0.1));
        ld.xz*=rot(0.3);
        vec3 h = normalize(ld - rd);
        float diff = max(0.0,dot(n,ld));
        float amb = dot(n,ld)*0.5+0.5;
        float fres = pow(dot(rd,rr)*0.4+0.6,1.0);
        float spec = pow(max(dot(n, h),0.), 20.);
        float diff2 = dot(n,ld)*0.7+0.3;

        vec3 diffcol = vec3(0);
        
        //Base top red color
        diffcol+=mix(red,redish,0.5);
        //Sorta shift yellow towards top of diff but keep bottom end
        float bias = 0.3;
        //Base Top Yellow 
        vec3 top1=vec3(diff2*0.5,pow(diff2,0.9),diff2*0.1)*smoothstep(0.0,0.4+bias,dot(n,ld)+0.15);
        //Second version of Top Yellow 
        vec3 top2 =vec3(diff2*0.6,diff2*0.9,diff2*-0.3)*smoothstep(0.0,0.5+bias,dot(n,ld));
        //Idk I liked both of them
        diffcol+=mix(top1,top2,0.6);
        //White top hightlight
        diffcol+=vec3(0,0,1)*smoothstep(0.75,1.15,diff)*0.3;
        //Saturate 
        diffcol=pow(diffcol,vec3(1.05));
        //Add diffcol
        col+=diffcol;
        //Transition between dark and light
        float cutdiff = smoothstep(0.3,0.55,amb)+0.1;
        //Remove previous lighting in dark
        col*=cutdiff;
        //add purple fresnal in dark area
        col+=mix(fres,1.0,0.3)*pow(redish,vec3(1.3))*sat(1.0-cutdiff)*0.8;
        //I think the hueshift breaks without this idk
        col = sat(col);
        //col = vec3(amb);
    }
    else {
        float px = 2.5/min(iResolution.x,iResolution.y);
        
        col+=sat(min(glow*0.05,0.3)*2.5)*redish;
        uv-=vec2(-0.9,0.6);
        col+=redish*length(uv)*smoothstep(0.5,5.8,length(uv));

        
        uv+=vec2(0.08,-0.06);
        vec2 uv2 = uv;
        uv2*=rot(-iTime*0.02);
        col+=0.55*mix(vec3(0.973,0.004,0.369),vec3(0.537,0.200,0.910),uv.y+0.5)
        *smoothstep(0.5+px,0.5-px,superGon(uv2,-0.01));


        vec2 uvo = uv;
        uv.xy*=rot(iTime*0.0075);
        uv=moda(uv,0.18);
        uv.x-=0.55;

        col+=0.3*vec3(0.973,0.004,0.369)*smoothstep(0.025+px,0.025-px,octGon(uv,0.0));

        uv = uvo;
        uv.xy*=rot(iTime*0.0125);
        uv=moda(uv,0.17);
        uv.x-=0.62;

        uv=moda(uv,2.);
        uv.x-=0.03;

        col+=0.3*vec3(0.973,0.004,0.369)*smoothstep(0.0125+px,0.0125-px,octGon(uv,0.0));
    
    }  
    col +=min(glow2*0.06,0.7)*pow(redish,vec3(0.5));

    //Hue Shift
    col = hs(col,0.3);
    
    fragColor = vec4(col,1.0);
}