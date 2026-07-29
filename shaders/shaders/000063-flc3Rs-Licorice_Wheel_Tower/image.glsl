// Image (image) — Licorice Wheel Tower by Tater
// https://www.shadertoy.com/view/flc3Rs

// Fork of "Spiral SDF testing 4" by Tater. https://shadertoy.com/view/Nl3Gzj
// 2021-11-10 02:34:13

// Fork of "Spiral SDF testing 3" by Tater. https://shadertoy.com/view/Nlc3Rj
// 2021-11-08 02:08:11

// Fork of "Spiral SDF testing 2" by Tater. https://shadertoy.com/view/fs3Xzf
// 2021-11-08 02:05:42

// Fork of "Spiral SDF testing" by Tater. https://shadertoy.com/view/fs3SzX
// 2021-10-07 08:34:52

//Inspiration:
//https://twitter.com/smjtyazdi/status/1457290470497869824
//https://www.brucescandy.com/products/red-licorice-wheels


#define MDIST 150.0
#define STEPS 128.0

#define pmod(p,x) (mod(p,x)-0.5*(x))
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
vec3 rdg;
vec3 hsv(vec3 c){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
//iq extrude
float ext(vec3 p, float s, float h){
  vec2 b = vec2(s,abs(p.y)-h);
  return min(max(b.x,b.y),0.)+length(max(b,0.));
}

float diplane(vec3 p,vec3 b,vec3 rd){
    vec3 dir = sign(rd)*b;   
    vec3 rc = (dir-p)/rd;
    return rc.z+0.01;
}
float lim(float p, float s, float lima, float limb){
    return p-s*clamp(round(p/s),lima,limb);
}
float idlim(float p, float s, float lima, float limb){
    return clamp(round(p/s),lima,limb);
}



//This is a large mess :)
vec2 spiral(vec2 p, float t, float m, float scale, float size, float expand, float pz,float timeOffset){
    
    size-=expand-0.01;
    float R1 = (sqrt(m*(m*pi+4.0*t*pi)))+m*sqrt(pi)/(2.0*m*sqrt(pi)) -1.0;
    float RT1 = R1;
    float R2 = (sqrt(m*(m*pi+4.0*max(-t+timeOffset,0.)*pi)))+m*sqrt(pi)/(2.0*m*sqrt(pi)) -1.0;
    float RT2 = R2;
    R1 = R1*m-m*0.5;
    R2 = R2*m-m*0.5;
    float centDist = 22.0*3.5*scale+sin(t*0.5+pi)*1.25;

    float L = sqrt(centDist*centDist-(R2+R1)*(R2+R1));
    
    p.x+=L*0.5*sin(t);
    p*=rot(-(RT2-RT1)*pi*1.0);
    p*=rot(-atan((R2+R1)/L)-0.13);
    p.x-=L*0.5;
    p.y-=R2;

    vec2 po3 = p;
    float s = sign(p.x);
    p.x = abs(p.x);
    
    float c = max(p.x+0.125+expand,abs(p.y)-(R2+R1)*2.0);
    
    p.x-=L*0.5;

    p.y*=s;
    float to2 = t;
    t*=s;
    
    //if(s<0.0)t+=timeOffset;
    
    t = max(t,0.);
    float to = t;

    if(s>0.)t=RT1;
    else t = RT2;
    vec2 po = p;
    p.y+=-t*m-m*0.5;

    p*=rot(t*pi*2.+pi/2.);
    
    float theta = atan(p.y,p.x);
    theta = clamp(theta,-pi,pi);
    p = vec2(theta,length(p));
    
    p.y+=theta*scale*0.5;

    float py = p.y;
    float id = floor((p.y+m*0.5)/m);
    p.y = lim(p.y,m,0.,floor(t));
    float py2 = p.y;
    float hel = -(theta+pi)/(2.*pi)+id; 
    
    float a = abs(p.y)-size;
    
    p.y = py;
    p.x -= pi;
    p.y -= (floor(t)+1.5)*m-m*0.5;
    float b = max(abs(p.y),abs(p.x)-(pi*2.)*fract(t)+size );
    
    if(a>b-size){
        a=b-size;
        py2=p.y;
    }
    b = abs(po.y)-size;
    b = max(po.x*30.,b);
    
    if(b<a) {
        id = ceil(t);
        py2=-po.y;
        hel*=id;
    }
    else hel*=max(id,0.4);
    
    float strip = (sin(hel*pi*20.)*0.5+0.5);
    vec3 p2 = vec3(hel,py2+hel*0.1,pz)*7.0+to2*0.2;
    p2.xy*=rot(0.4);
    //Taken from https://www.shadertoy.com/view/tsBSzc
    strip =  smoothstep(-.05,.05,  length(p2 - (floor(p2) + cos(floor(p2.zxy) * 10.) * .25 + .5)) - .25);
    
    if(b<a){
        hel = (po3.x*(0.04/scale)-to2/(sqrt(pi)*(0.04/scale)))*1.1;
        p2 = vec3(hel,po3.y,pz*0.8+hel*0.01)*8.0+to2*0.2;
        p2.xy*=rot(0.4);
        float strip2 = smoothstep(-.05,.05,  length(p2 - (floor(p2) + cos(floor(p2.zxy) * 10.) * .25 + .5)) - .3);
        strip = mix(strip,strip2,1.0-smoothstep(-0.4,0.,po.x));
       // strip = strip2;
    }
    a = min(a,b);
    a = min(a,c); 
    return vec2(a,strip);
}
vec4 map(vec3 p){
    float t = iTime;
    vec3 rd2 = rdg;
    
    p.yz=p.zy;
    rd2.yz=rd2.zy;
    
    p.zx*=rot(sin(t)*0.125);
    rd2.zx*=rot(sin(t)*0.125);
    p.zx*=rot(cos(t)*0.125);
    rd2.zx*=rot(cos(t)*0.125);
    p.xy*=rot(pi);
    rd2.xy*=rot(pi);
    p.xy*=rot(t);
    rd2.xy*=rot(t);
    
    vec3 po = p;
    vec2 a = vec2(1);
    
    float timeOffset = 30.0;
    
    float scale = 0.05;
    float m = pi*scale;
    float size = 0.07;
    float expand = m*0.5;
    float count = 14.0;
    float thick = 0.075;
    
    float id = idlim(p.z,m+scale+thick*1.5,-count,count);
    p.z = lim(p.z,m+scale+thick*1.5,-count,count);
    t*=0.25;
    t+=id*0.025;
    //timeOffset+=id*1.0;
    t = (tanh(sin(t)*1.2)*0.55+0.5)*timeOffset;
    
    p.xy*=rot(id*pi/30.0);
    
    vec2 b = spiral(p.xy, t, m, scale, size, expand, po.z,timeOffset);
    a.x = ext(p.yzx,b.x,thick)-expand;
    a.x*=0.9;
    vec2 c= vec2(diplane(p,vec3(m+thick-scale),rd2)*0.9,5.0);
    
    a.y+=b.y;
    float nsdf = a.x;
    a=(a.x<c.x)?a:c;
    return vec4(a,nsdf,id);
}
vec3 norm(vec3 p){
    vec2 e = vec2(0.005,0);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    vec3 col = vec3(0);
    vec3 ro = vec3(0,7,-5)*1.1;
    ro.yz*=rot(0.2);
    if(iMouse.z>0.){
    ro.yz*=rot(3.0*(iMouse.y/iResolution.y-0.2));
    ro.zx*=rot(-7.0*(iMouse.x/iResolution.x-0.5));
    }
    vec3 lk = vec3(0,0,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = normalize(f*(0.55)+uv.x*r+uv.y*cross(f,r));  
    rdg = rd;
    vec3 p = ro;
    float dO = 0.;
    bool hit = false;
    vec4 d= vec4(0);
    for(float i = 0.; i<STEPS; i++){
        p = ro+rd*dO;
        d = map(p);
        dO+=d.x;
        if(abs(d.x)<0.001){
            hit = true;
            break;
        }
        if(dO>MDIST){
            dO = MDIST;
            break;
        }
    }
    vec3 bg = mix(vec3(0.710,0.310,0.792),vec3(0.184,0.031,0.286)*0.75,length(uv));
    if(hit&&d.y!=5.0)
    {
        vec3 ld = normalize(vec3(0,1,0));
      
        //sss from nusan
        float sss=0.15;
        for(float i=1.; i<10.; ++i){
            float dist = i*0.05;
            sss += smoothstep(0.,1.,map(p+ld*dist).z/dist)*0.055;
        }
        vec3 al = vec3(0.25,0.25,0.373)*0.8;
        vec3 n = norm(p);
        vec3 r = reflect(rd,n);
        float diff = max(0.,dot(n,ld));
        float amb = dot(n,ld)*0.45+0.55;
        float spec = pow(max(0.,dot(r,ld)),40.0);
        //blackle ao
        #define AO(a,n,p) smoothstep(-a,a,map(p+n*a).z)
        float ao = AO(.3,n,p)*AO(.5,n,p)*AO(.9,n,p);

        col = al*
        mix(vec3(0.169,0.000,0.169),vec3(0.984,0.996,0.804),mix(amb,diff,0.75))
        +spec*0.3;
        col+=sss*(hsv(vec3(fract(d.w*0.5)*0.45+0.75,1.,1.35)));
        col=pow(col,vec3(mix(1.2,1.0,d.y-1.0)));
        col*=mix(0.8,1.0,d.y-1.0);
        col*=mix(ao,1.,0.6);
        col = pow(col,vec3(0.7));
    }
    else{
    col = bg;
    }
    col = clamp(col,0.,1.);
    
    fragColor = vec4(col,1.0);
}