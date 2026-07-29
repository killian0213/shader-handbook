// Buffer A (buffer) — Fractal Computer by byt3_m3chanic
// https://www.shadertoy.com/view/sstXR8

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    09/28/21 @byt3_m3chanic 
    Fractal Computer

*/

#define R iResolution
#define M iMouse
#define T iTime

#define PI  3.14159265359
#define PI2 6.28318530718

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21( vec2 p ) { return fract(sin(dot(p,vec2(23.43,84.21))) *4832.3234); }
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }
float eoc(float t) { return (t = t - 1.0) * t * t + 1.0; }

float tmod,ga1,ga2,ga3,ga4,ga5,ca1;

//@iq thanks for the sdf's!
float cap( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdbox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdframe( vec3 p, vec3 b, float e ) {
  p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

// polar mod
float modPolar(inout vec2 p, float rep) {
    float angle = 2.*PI/rep;
    float a = atan(p.y, p.x) + angle/2.;
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*length(p);
    return (abs(c) >= (rep/2.)) ? abs(c) : c;
} 

//globals
mat2 tprot, rx, ry;

//folds
void siepr(inout vec4 p, float k1, float k2, float k3, float k4) {
	if (p.x + p.y<0.0) p.xy = -p.yx;
	if (p.x + p.z<0.0) p.xz = -p.zx;
	if (p.y + p.z<0.0) p.zy = -p.yz;
	p.xyz = p.xyz*k1 - vec3(k2, k3, k4)*(k1 - 1.0);
	p.w *= k1;
}

const float zoom = 10.;

vec2 map(vec3 p) {
    vec2 res =vec2(1e5,0.);
    vec3 pp = p;
    
    p.x+=(ga5*14.5)-2.5;
    p.y+=.75;
    
    p.x=mod(p.x+7.25,14.5)-7.25;
    vec4 P = vec4(p.xyz, 1.0);

    P.yz*=rot(ga2*PI);
    P.xz*=rot(ga1*PI);
    P.x+=1.75; 
    siepr(P,1.,1.,1.,1.); 
    
    vec3 q = P.xyz;
    
    float fw = 2.75+1.25*sin(ga4);
    q.x=abs(q.x)-((ga3*5.));
    q.z=abs(q.z)-((ga2*2.5)+1.);
    q.y+=1.;
    
    float mainbox = sdbox(q-vec3(0,1.1,0),vec3(1.5,3,.75));
    float cutbox =  sdbox(q-vec3(0,2.50,.775),vec3(1.3,1.,1.1));
    float cutbox_lower = sdbox(vec3(q.xy,abs(q.z))-vec3(0,-.225 ,.775),vec3(.75,1.5,.3 ));

    cutbox = min(cutbox_lower, cutbox);
    mainbox = max(mainbox, -cutbox);

    vec3 fq = vec3(q.y,abs(q.x),q.z);
    float frame = sdframe(q-vec3(0,1.1,0),vec3(1.6,3.1,.82),.075)-.0125;
    frame = min(sdbox(fq-vec3(.020,.835,.1),vec3(1.675,.05,.75)),frame);
    frame = min(sdbox(fq-vec3(-.20,.425,.6),vec3(1.6,.05,.15)),frame);

    float screen = sdbox(q-vec3(0,2.50,.825),vec3(1.4,1.1,.05));
    screen = max(screen, -cutbox);
    frame = min(screen-.0125,frame);
    
    // parts
    vec3 cq = vec3(q.y,q.z,abs(q.x));
    //frame = min(sdbox(q-vec3(0,2.05,.5),vec3(.45,.195,.06)),frame);
    frame = min(cap(cq-vec3(2.8,-.1,.625),.25,.6),frame);
    frame = min(cap(cq-vec3(1.95,.15,.725),.125,.15),frame);
    frame = min(cap(cq-vec3(2.05,.15,1.05),.075,.15),frame);
    frame = min(sdbox(q-vec3(0,1.3,.6),vec3(.445,.35,.15)),frame);

    mainbox = min(mainbox, frame);

    float tapeB = cap(vec3(q.y,q.z,abs(q.x))-vec3(2.8,.55,.65),.225,.1);
    tapeB = min(  cap(vec3(q.y,q.z,abs(q.x))-vec3(1.95,.5,.65),.100,.1),tapeB);

    vec3 tq1 = q.yzx-vec3(2.8,.25,.65);
    vec3 pq1 = tq1;
    pq1.xz*=tprot;
    modPolar(pq1.xz,3.);
    float tcbx = sdbox(pq1-vec3(.4,0,0),vec3(.09,.09,.075));
    
    float tape1 = cap(tq1,.575,.05);
    tape1=max(tape1,-tcbx);

    vec3 tq2 = q.yzx-vec3(2.8,.25,-.65);
    vec3 pq2 = tq2;
    pq2.xz*=tprot;
    modPolar(pq2.xz,2.);
    float tcby = sdbox(pq2-vec3(.4,0,0),vec3(.09,.09,.075));
    float tape2 = cap(tq2,.575,.05);
    tape2=max(tape2,-tcby);
    
    tape1 = min(tape1, tape2);
    
    if(tape1<res.x) res = vec2(tape1/P.w,3.);

    // buttons
    vec3 bq = q-vec3(.0,3.85,.65);
    bq.x=abs(abs(bq.x)-.5)-.25;
    bq.y=abs(bq.y)-.1;
    float btn1 = sdbox(bq,vec3(.2,.05,.25))-.0125;
    btn1 = min(sdbox(q-vec3(0,2.05,.5),vec3(.45,.195,.06))-.0125,btn1);
    if(btn1<res.x) res = vec2(btn1/P.w,2.);

    if(mainbox<res.x) res = vec2(mainbox/P.w,1.);

    return res;
}

//Tetrahedron technique
//https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t, float mindist) {
    float e = mindist*t;
    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
					  h.yyx*map( p + h.yyx*e ).x + 
					  h.yxy*map( p + h.yxy*e ).x + 
					  h.xxx*map( p + h.xxx*e ).x );
}

vec3 render(vec3 p, vec3 rd, vec3 ro, float d, float m, inout vec3 n, inout float fresnel) {
    n = normal(p,d,.5);
    vec3 lpos =  vec3(8,10,-8);
    lpos.xz*=ry;
    vec3 l = normalize(lpos-p);
    float diff = clamp(dot(n,l),0.,1.);
    
    fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 9.);
    fresnel = mix(.0, .9, fresnel);

    vec3 h = vec3(.3);
    
    if(m==1.) h=mix(vec3(.05),vec3(.3),clamp((p.y+4.)*.1,0.,1.));

    if(m==2.) {
        vec3 h2=mix(vec3(0.596,0.110,0.690),vec3(0.129,0.467,0.831),clamp((p.x+4.)*.07,0.,1.));
        h=mix(vec3(0.016,0.431,0.008),h2,clamp((p.z+4.)*.07,0.,1.));
    }
    if(m==3.) {
        vec3 h2 = h=mix(vec3(0.639,0.596,0.000),vec3(0.165,0.698,0.180),clamp((p.x+4.)*.1,0.,1.));
        h=mix(h2,vec3(0.169,0.569,0.871),clamp((p.y+4.)*.1,0.,1.));
    }
    
    return diff*h;
}

void mainImage( out vec4 O, in vec2 F )
{
    // precal
    float time = T;
    
    tprot=rot(T*75.*PI/180.);
    //all the timing stuff
    tmod = mod(time, 16.);
    float t1 = lsp(0.0, 2.0, tmod);
    float t2 = lsp(6.0, 7.0, tmod);
    
    float t3 = lsp(2.0, 3.5, tmod);
    float t4 = lsp(9.0, 10.0, tmod);
    
    float t5 = lsp(4.0, 5.0, tmod);
    float t6 = lsp(9.0, 10.0, tmod);

    float t7 = lsp(4.0, 6.0, tmod);
    float t8 = lsp(14.0, 16.0, tmod);
    float t9 = lsp(11.0, 15.0, tmod);
    
    ga1 = eoc(t1-t2);
    ga1 = ga1*ga1*ga1;
 
    ga2 = eoc(t3-t4);
    ga2 = ga2*ga2*ga2;
    
    ga3 = eoc(t5-t6);
    ga3 = ga3*ga3*ga3; 
    
    ga4 = eoc(t7-t8);
    ga4 = ga4*ga4*ga4;
    
    t9 = eoc(t9);
    t9 = t9*t9*t9;  
    ga5 = (t9);//+floor(time*.1);
    
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);

    //orthographic camera
    vec3 ro = vec3(uv*zoom,-zoom-15.);
    vec3 rd = vec3(0,0,1.);

    float x = M.xy == vec2(0) ? 0. : -(M.y/R.y * .125 - .0625) * PI;
    float y = M.xy == vec2(0) ? 0. : -(M.x/R.x * .125 - .0625) * PI;
   
    float msw = mod(time*.5,32.);
    float m1 = lsp(0.0, 4.0, msw);
    float m2 = lsp(16.0, 20.0, msw);
    ca1 = eoc(m1-m2);
    ca1 = ca1*ca1*ca1; 
    
    x += mix(-.38539816339,-.78,ca1);
    y += mix(2.35,.64,ca1);
    
    rx = rot(x);
    ry = rot(y);

    ro.yz *= rx; ro.xz *= ry;
    rd.yz *= rx; rd.xz *= ry;

    vec3 C = vec3(.0075);
    vec3  p = ro + rd;
    float atten = .95;
    float k = 1.;
    float d = 0.;
    //@blackle's transparent 
    //marcher modified
    for(int i=0;i<128;i++)
    {
        vec2 ray = map(p);
        vec3 n=vec3(0);
        float m = ray.y;

        d = i<48 ? ray.x*.25 : ray.x;
        p += rd * d *k;
        
        if (d*d < 1e-7) {
  
            float fresnel=0.;
            C+=render(p,rd,ro,d,ray.y,n,fresnel)*atten;
  
            atten *= .575;
            p += rd*.075;
            k = sign(map(p).x);

            vec3 rr = vec3(0);

            if(m==3.) {
                rd=reflect(-rd,n);
                p+=n*.05;
            } else {
                rr = refract(rd,n,.55);
                rd=mix(rr,rd,.5-fresnel);
            }

        } 
       
        if(distance(p,rd)>35.) { break; }
    }

    if(C.r<.008&&C.g<.008&&C.b<.008) C = hash21(uv)>.5 ? C+.005 : C;
    //C = pow(C, vec3(.4545));
    O = vec4(C,1.0);
}