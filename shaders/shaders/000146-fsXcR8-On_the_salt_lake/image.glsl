// Image (image) — On the salt lake by iapafoto
// https://www.shadertoy.com/view/fsXcR8

//-----------------------------------------------------
// Created by sebastien durand - 2021
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------
// inspired by nguyen nhut work https://twitter.com/nguyenhut_art
// Teapot alone: https://www.shadertoy.com/view/XsSGzG
//-----------------------------------------------------

#define ZERO (min(0, iFrame))
#define PI 3.141592
#define U(a,b) (a.x*b.y-b.x*a.y)

float gTime;

//---------------------------------------------------------------------
//    Animation
//---------------------------------------------------------------------

//                       Contact           Down               Pass               Up      

int[27] HEAD = int[27](50,24,0, 73,30,0, 94,20,0, 117,15,0,135,24,0, 158,30,0,  179,20,0,  202,15,0, 218,24,0);
int[27] SHOULDER = int[27](44,47,16,66,53,16, 91,43,16, 115,38,16,136,50,16, 158,55,16, 176,43,16, 85+111,37,16, 212,47,16);
int[27] ELBOW = int[27](25,64,25, 46,67,25, 88,70,25, 120,65,25,139,72,25,172,67,25, 176,71,25, 177,61,25, 193,64,25);
int[27] WRIST = int[27](20,85,15, 35,76,20, 88,100,25, 128,89,25,164,85,15, 187,81,20,85+88,98,25,85+82,81,20, 188,85,15);
int[27] HIP = int[27](42,90,10,  62,95,10, 83,88,10, 107,83,10, 127,92,10, 147,94,10,  168,91,10,  192,85,10, 210,90,10);
int[27] KNEE = int[27](29,118,7, 48,120,8, 97,117,10, 130,107,10, 144,120,7, 167,118,7,  167,118,7,  181,111,7, 197,118,7);
int[27] ANKLE = int[27](5,134,5, 22,132,6, 71,122,10, 113,127,10, 162,146,5, 164,146,5,  164,146,5,  168,137,5, 173,134,5);
int[27] FOOT = int[27]( 14,150,10, 16,150,10, 63,139,10, 119,143,10, 178,139,10,182,150,10, 182,150,10, 182,150,10, 182,150,10);
    

    // Teapot body profil (8 quadratic curves) 
float[30] A = float[30] (0.,0.,.64,0.,.64,.03,.8,.12,.8,.3,.8,.48,.64,.9,.6,.93,.56,.9,.56,.96,.12,1.02,0.,1.05,.16,1.14,.2,1.2,0.,1.2);
vec2[5] T1 = vec2[5] (vec2(1.16, .96),vec2(1.04, .9),vec2(1,.72),vec2(.92, .48),vec2(.72, .42));
vec2[5] T2 = vec2[5] (vec2(-.6, .78),vec2(-1.16, .84),vec2(-1.16,.63),vec2(-1.2, .42),vec2(-.72, .24));

vec3 shoulder1, elbow1, wrist1, head,
     shoulder2, elbow2, wrist2,
     foot1, ankle1, knee1, hip1,
     foot2, ankle2, knee2, hip2;

mat2 rot, rot1, rot2;
mat3 baseArm1, baseArm2, baseBag, baseFoot1, baseFoot2;

float smin(float a, float b, float k){
    float h = clamp(.5+.5*(b-a)/k, 0., 1.);
    return mix(b,a,h)-k*h*(1.-h);
}

vec2 min2(vec2 a, vec2 b) {
    return a.x<b.x ? a:b; 
}

float sdSpiral(vec3 p, vec2 sz){
    float d = length(p.xy)/sz.x + atan(-p.y,p.x)*.5;  
    d -= PI*clamp(round(d/PI),1.,4.);
    return max(sz.x*(abs(d)-.77), abs(p.z)-sz.y); 
}

// Adated from gaz [Bones] https://www.shadertoy.com/view/ldG3zc
vec2 sdBone(in vec3 p) {
    p.x -= 80.;
    float d,n, m = 200.,
    scale = .5 + floor(abs(p.x)/m);
    p.x = mod(p.x+m*.5,m)-m*.5;
    p.xz *= rot;
    p /= scale;
    p -= vec3(0.,.05,2.5);
    d = length(p-vec3(1.2,.2,-.35)) - .2;
    p.y -= .2*p.x*p.x;
    p.y *= cos(atan(.6*p.x));
    n = clamp(p.x,-.7,1.);
    vec2 sg = vec2(length(p.xy-vec2(n,0)),(n+.7)/1.7),
         p0 = pow(abs(vec2(sg.x, p.z)), vec2(3));
    d = smin(d,pow(p0.x+p0.y, 1./3.) -(.3*pow(sg.y-.5,2.)+.2), .3);
    return vec2(.7*scale*d, 9.);
}
//-----------------------------------------------------------------------------------
// iq - https://www.shadertoy.com/view/ldj3Wh
vec2 sdBezier(in vec3 p,in vec3 b0,in vec3 b1,in vec3 b2 ) {
    b0 -= p; b1 -= p; b2 -= p;
    vec3 g,b01 = cross(b0,b1), b12 = cross(b1,b2), b20 = cross(b2,b0),
         n =  b01+b12+b20;
    float t,a = -dot(b20,n), b = -dot(b01,n), d = -dot(b12,n), m = -dot(n,n);
    g =  (d-b)*b1 + (b+a*.5)*b2 + (-d-a*.5)*b0;
    t = clamp((a*.5+b-.5*(a*a*.25-b*d)*dot(g,b0-2.*b1+b2)/dot(g,g))/m, 0., 1.);
    return vec2(length(mix(mix(b0,b1,t), mix(b1,b2,t),t)),t);
}

vec2 sdBezier(vec2 m, vec2 n, vec2 o, vec3 p) {
    return sdBezier(p, vec3(m,0), vec3(n,0), vec3(o,0));
}

// Distance to Teapot --------------------------------------------------- 
float sdTeapot(vec3 p) {
	vec2 h = sdBezier(T1[2],T1[3],T1[4], p);
	float a = 99., 
		b = min(min(sdBezier(T2[0],T2[1],T2[2], p).x, sdBezier(T2[2],T2[3],T2[4], p).x) - .06, 
                max(p.y - .9,
                    min(abs(sdBezier(T1[0],T1[1],T1[2], p).x - .07) - .01, 
                        h.x * (1. - .75 * h.y) - .08)));
    vec3 qq= vec3(sqrt(dot(p,p)-p.y*p.y), p.y, 0);
	for(int i=ZERO;i<2*13;i+=4) 
		a = min(a, (sdBezier(qq, vec3(A[i],A[i+1],0),vec3(A[i+2],A[i+3],0), vec3(A[i+4],A[i+5],0)).x - .035) * .9); 
	return smin(a,b,.02);
}

// Interpolate pos of articulations
vec3 getPos(int arr[27], int it, float kt, float z) {
    it = 3*(it%8);
    vec3 p = mix(vec3(arr[it],arr[it+1],arr[it+2]),
                 vec3(arr[it+3],arr[it+4],arr[it+5]), kt);
	return .02*vec3(p.x+floor(gTime/8.)*168., 150.-p.y, p.z*z);
}

//---------------------------------------------------------------------
//    HASH functions (iq)
//---------------------------------------------------------------------

vec2 hash22(vec2 p) {
    p = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p + vec2(21.5351, 14.3137));
    return fract(p.x*p.y*vec2(95.4337, 97.597));
}

float n2D(vec2 p) {
	vec2 i = floor(p); p -= i; //p *= p*(3. - p*2.);  
    p *= p*p*(p*p*6. - p*15. + 10.); 
    return dot(mat2(fract(sin(mod(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)), 6.2831853))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );
}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }


//---------------------------------------------------------------------
//   Modeling Primitives
//   [Inigo Quilez] https://iquilezles.org/articles/distfunctions
//---------------------------------------------------------------------

float sdCap(vec3 p, vec3 a, vec3 b) {
    vec3 pa = p - a, ba = b - a;
    return length(pa - ba*clamp( dot(pa,ba)/dot(ba,ba), 0., 1.) );
}

float sdCap2(vec3 p, vec3 a, vec3 b, float r1, float r2) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1. );
    return length(pa - ba*h) - mix(r1,r2,h);
}

float udRoundBox(vec3 p, vec3 b, float r) {
  return length(max(abs(p)-b,0.))-r;
}

float sdCappedCylinder(vec3 p, vec2 h ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}

// approximated
float sdEllipsoid( in vec3 p, in vec3 r ) {
    float k0 = length(p/r);
    return k0*(k0-1.)/length(p/(r*r));
}

float sdEar(in vec3 p) {
    vec3 p_ear = 1.5*p;
    return smin(max(p_ear.z,
                max(-sdEllipsoid(p_ear-vec3(.005,.015,.02), vec3(.07,.1,.07)), 
                     sdEllipsoid(p_ear,vec3(.08,.12,.09)))), 
                     sdEllipsoid(p_ear+vec3(.035,.045,.01), vec3(.04,.04,.018)), .01)/1.5;
}


vec2 sdMan(in vec3 pos){
    vec3 p0 = pos;
    vec2 res = vec2(999,0);
    // Legs
    float dSkin = min(
        min(sdCap(pos, ankle1, knee1), 
            sdCap(pos, knee1, hip1)),
        min(sdCap(pos, ankle2, knee2),
            sdCap(pos, knee2, hip2)))-.1;
            
    // Foot1 flat part - vector base linked to leg 1
    float dShoes1 = max(sdCap(pos, foot1, ankle1) - .15, -dot((pos-ankle1)*baseFoot1-vec3(0,0,-.13), vec3(0,0,1))),
          dShoes2 = max(sdCap(pos, foot2, ankle2) - .15, -dot((pos-ankle2)*baseFoot2-vec3(0,0,-.13), vec3(0,0,1)));  
    
    vec3 ep0 = mix(shoulder1,shoulder2,.5),
         ha0 = mix(hip1,hip2,.5),
    // Head
         h1 = vec3(0,.17,0), h2 = vec3(.02,-.11,0),
         h = mix(h1,h2,.2);
    dSkin = min(dSkin, sdCap(pos, head - h, head - h2)-.25);
    
    vec3 posHead = pos-head;
    posHead.xz *= rot1;
    vec3 posEar = posHead;
    posEar.z = abs(posEar.z);
    posEar-=vec3(0.,-.08,.29);
    posEar.zx *= rot;
 
     // ear / noze
    dSkin = smin(dSkin, min(sdEar(posEar.zyx),
                            sdCap(posHead, - mix(h1,h2,.4), - mix(h1,h2,.4) + vec3(.28,0,0))- .04),.02);
    // Torso
    vec3 a = mix(ha0,ep0,.15), b = mix(ha0,ep0,.78);
    
    // Neck
    float dNeck = sdCap(pos, ep0-vec3(.08,0,0), head-vec3(.08,.1,0))- .1;
    dSkin = smin(dSkin, dNeck,.06);
  
    float dTorso = smin(sdCap(pos,shoulder1,shoulder2)-.11, sdCap2(pos, a, b, .23,.28),.095);
    dSkin = min(dSkin, dTorso);
   
    dTorso = smin(dTorso, sdCap(pos, shoulder1, mix(shoulder1,elbow1,.3))- .1,.05);

    // Arm 1
    dSkin = smin(dSkin, sdCap(pos, shoulder1, elbow1)- .1,.05);
    dSkin = min(dSkin, sdCap2(pos, elbow1, wrist1-.05*normalize(wrist1-elbow1), .1, .08));
   
    vec3 p2 = (pos-wrist1)*baseArm1; // change to hand base
    float d2 = sdCap(p2,vec3(-.1,.12,.04),vec3(-.04,.18,.06))-.05;
    p2.z -= 1.5*p2.x*p2.x;
    d2 = min(d2,sdEllipsoid(p2-vec3(.02,.05,0), vec3(.17,.14,.07)));

    // Arm 2
    dTorso = smin(dTorso, sdCap(pos, shoulder2, mix(shoulder2,elbow2,.3))- .1,.05);
    dSkin = min(smin(dSkin, sdCap2(pos, shoulder2, elbow2, .11,.1),.05),
                sdCap2(pos, elbow2, wrist2-.105*normalize(wrist2-elbow2), .1, .08));
    
    p2 = (pos - wrist2)*baseArm2; // change to hand base
    d2 = min(d2,sdCap(p2,vec3(-.1,.12,.04),vec3(-.04,.18,.06))-.05);
    p2.z -= 1.5*p2.x*p2.x;
    d2 = min(d2,sdEllipsoid(p2-vec3(.02,.05,0), vec3(.17,.14,.07)));
    
   	dSkin = smin(d2, dSkin, .1);

    // Short
    float dShort = min(sdCap(pos, hip1, mix(hip1,knee1,.7)), 
                       sdCap(pos, hip2, mix(hip2,knee2,.7)))-.14;  
    dShort = min(dShort, smin(dShort, sdEllipsoid(pos-ha0-vec3(.01,.06,0),vec3(.23,.3,.3)), .05));
 
    // Belt
    vec3 p3 = p0;
    p3.y -= ha0.y+.2;
    float dBelt = max(max(min(dTorso-.05,dShort-.02), p3.y), -p3.y-.16);
    dShoes1 = min(dShoes1, dBelt); 

    float dMetal = mix(dBelt,sdCappedCylinder((p0-ha0-vec3(.2,.11,0)).zxy, vec2(.07,.14)),.5),
          dNeck2 = length(pos - ep0)-.25;
    dTorso = max(max(max(dTorso-.03, -dNeck2), -dSkin + .005), -pos.y + a.y);

    pos.x += .2;
    pos = pos - ep0;
    pos *= baseBag;
    vec3 pos0 = pos;
    
    // Backpack
    float ta = cos(2.8+.25*PI*gTime);

    // Water
    vec3 p = pos - vec3(-.5,-.5,-.4);
    p.xy *= rot2;
    dMetal = min(dMetal, min(sdCap(p,vec3(0), vec3(0,-.4-.04*ta,-.04*ta))- .1,
                             sdCap(p,vec3(0,.1,.01*ta), vec3(0,.15,.015*ta))-.07)); 
    pos.z = abs(pos.z);
    float dPack = sdBezier(pos, vec3(-.2,.2,.17),vec3(.9,.2,.36),vec3(-.2,-.6,.3)).x-.04;
   
    dPack = mix(dPack, dTorso,.2);

    pos = pos0;
  
    float ta2 = cos(2.5+.25*PI*gTime);
    pos.y += .15*ta2*ta2;
    pos.z += .06*ta2*ta2*ta2;
    float dBed = sdSpiral(pos-vec3(-.35-.14,.5-.16,0), vec2(.015,.5));

    // Teapot
    vec3 posTeapot = 3.*(pos - vec3(-.9,.25,.4)).yxz;
    posTeapot.xy *= rot2;
    posTeapot.yz *= rot;
    posTeapot.yx *= -1.;
    
    float dTeapot = .7*sdTeapot(posTeapot-vec3(1.,-1.,0))/3.;
    
    dPack = min(dPack, sdCappedCylinder(pos-vec3(-.75,.23,.26), vec2(.05,.03))); 
    pos.z = abs(pos.z);
    dPack = smin(min(min(dPack, sdCappedCylinder(pos.yzx-vec3(.35,.25,-.5), vec2(.22,.05))),
                    udRoundBox(pos0-vec3(-.33,-.25,-.35), vec3(.08,.1,.1),.04)), 
                    udRoundBox(pos0-vec3(-.33,-.2,0), vec3(.1,.3,.2), .15), .12);
    
    // Little box
    dBed = min(dBed, udRoundBox(pos0-vec3(-.33,-.1,-.35), vec3(.08,.1,.1),.0)); 
    
    // Cap
    pos = posHead + h2;
    float d = pos.x*.2-pos.y+.15*cos(5.*pos.z)-.12,
          dHat = max(min(max(sdCap(pos, vec3(0), vec3(.2,0,0))-.27, -d), 
                          mix(dSkin, sdCappedCylinder(pos, vec2(.25,.23)),.4)-.01),d-.02);
    dPack = min(dPack, dHat);

    // Asssociate distance to materials
    res = min2(res, min2(min2(min2(vec2(dTeapot, 6.), min2(vec2(dTorso, 5.), vec2(dShort, 3.))),
                              min2(vec2(dShoes1, 2.), vec2(dShoes2, 2.5))),
                         min2(min2(vec2(dSkin, 1.), vec2(dMetal, 8.)), 
                              min2(vec2(dPack, 4.), vec2(dBed, 7.)))));
    // Distance field is not percise for cap, teapot and hands
    res.x *= .75;
    return res;
}


vec2 map(vec3 p0){
    // Little stones    
    vec2 size = vec2(35.,20.),
         id = floor((p0.xz + size*0.5)/size);
    vec3 pos = p0;
    pos.xz = mod(p0.xz + size*0.5,size) - size*0.5;
    vec2 h = 1.-2.*hash22(id);
    float r = .15+.25*abs(h.x),
          d = length(pos - vec3(h.x*5.,-r*.4,7.*h.y))-r;
    vec2 res = vec2(d,0.);
    res = min2(res, sdBone(p0));
    d = length(p0-hip1)-2.;
    return min2(d<0.?sdMan(p0): vec2(d+.1,999.), res);
}

//---------------------------------------------------------------------
//   Ray marching scene if ray intersect bbox
//---------------------------------------------------------------------

vec2 Trace( in vec3 ro, in vec3 rd) {
    vec2 h,res = vec2(999,0);
    float t = .5;
    for( int i=ZERO; i<128 && t<100.; i++ ) {
        h = map( ro+rd*t);
        if( abs(h.x)<1e-3*t ) { 
            res = vec2(t,h.y); 
            break;
        }
        t += h.x;
    }
    return res;
}

//------------------------------------------------------------------------
// [Shane] - Desert Canyon - https://www.shadertoy.com/view/Xs33Df
//------------------------------------------------------------------------

// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
float tex3D(vec3 p, vec3 n){
    n = max(n*n, .001);
    n /= (n.x + n.y + n.z );  
	return fbm(p.yz)*n.x + fbm(p.zx)*n.y + fbm(p.xy)*n.z;
}

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total.
vec3 doBumpMap(vec3 p, vec3 n, float k){
    const float ep = .001;
    vec3 grad = vec3( tex3D(vec3(p.x-ep, p.y, p.z), n),
                      tex3D(vec3(p.x, p.y-ep, p.z), n),
                      tex3D(vec3(p.x, p.y, p.z-ep), n));
    grad = (grad - tex3D(p, n))/ep;             
    grad -= n*dot(n, grad);          
    return normalize(n + grad*k);
}

//---------------------------------------------------------------------
//   Ambiant occlusion
//---------------------------------------------------------------------

float calcAO( in vec3 pos, in vec3 nor ){
	float dd, hr, sca = 1., totao = 0.;
    vec3 aopos; 
    for( int aoi=ZERO; aoi<5; aoi++ ) {
        hr = .01 + .05*float(aoi);
        aopos = nor * hr + pos;
        totao += -(map(aopos).x-hr)*sca;
        sca *= .75;
    }
    return clamp(1. - 4.*totao, 0., 1.);
}

float textureInvader(vec2 uv) {
	float y = 7.-floor((uv.y)*12.+4.);
	if (y<0. || y>7.) return 0.;
	float x = floor((abs(uv.x))*16.),
	      v=y>6.5? 6.:y>5.5? 40.:y>4.5? 47.:y>3.5?63.:
			y>2.5? 27.:y>1.5? 15.:y>0.5? 4.:8.;
	return floor(mod(v/pow(2.,x), 2.0)) == 0. ? 0.: 1.;
}


vec3 doColor(in vec3 p, in vec3 rd, in vec3 n, in vec2 res){
    // sky dome
    vec3 pFoot, skyColor = vec3(.25,.3,.65),
         col = skyColor - max(rd.y,0.)*.5;
  
    float ss = .5, sp = 0.;
    if (res.y == 0. || res.y == 9.) {
        col = .7+.5*vec3(fbm(3.*p.zx));
        col.r *= .8;
        n = doBumpMap(p, n, .1*smoothstep(40.,15.,res.x));
        ss = 0.;
        sp = .3;
    } else if (res.y == 2.) {
        sp = .1;
        pFoot = (p-ankle1)*baseFoot1;
        col = mix(vec3(.1,.1,0), vec3(0,0,.1), smoothstep(-.1,-.09,pFoot.z));
    } else if (res.y == 2.5) {
        col = vec3(0,0,.1);
        sp = .1;
        pFoot = (p-ankle2)*baseFoot2;
        col = mix(vec3(.1,.1,0), vec3(0,0,.1), smoothstep(-.1,-.09,pFoot.z));
    } else if (res.y == 1.) {
        col = vec3(.87,.7,.56);
        ss = 1.;
        sp = .1;
        if (p.x>head.x) {
			// Draw simple face
            vec3 phead = (p - head);
            phead.xz *= rot1;
			vec2 p2 = phead.zy;
            p2.x = abs(p2.x);
            float d = length(p2-vec2(.1,0))-.02;
            d = min(d, max(length(p2-vec2(0.,-.18))-.05, -length(p2-vec2(0.,-.14))+.07))            ;
            col = mix(vec3(0), col, smoothstep(.0,.01,d));
		}
    } else if (res.y == 8.) {
        col = vec3(.8,.9,1.);
        sp = 2.;
    } else if (res.y == 3.) {
        col = vec3(.35,.7,.85);
    } else if (res.y == 4.) {
        col = vec3(.3,.5,.2);
        sp = .1;
    } else if (res.y == 5.) {
        col = vec3(.3,.4,.5);
        vec2 p2 = p.zy;
        p2.y -= mix(mix(shoulder2,shoulder1,.5),
                    mix(hip2,hip1,.5),.5).y;
        col *= 1.-.5*textureInvader(p2*1.9-vec2(0,.3));
        ss = .2;
    } else if (res.y == 6.) {
        col = vec3(1.,.01,.01);
        sp = .5;
    } else if (res.y == 7.) {
        col = vec3(1.,.5,.01);
        ss = 1.;
        sp = .3;
    }// else return col;
    if (res.y == 9.) {
        ss = 1.;
        sp = 1.;
    }

    vec3 ld = normalize(p-vec3(5,10,-10));
    // IQ sss version
    float sss = ss*0.2*clamp(.5+.5*dot(ld,n),0.0,1.0)*(2.0+dot(rd,n));
    vec3 r = reflect(rd,n);
    float diff = max(0.,dot(n,ld)),
         amb = dot(n,ld)*.45+.55,
         spec = pow(max(0.,dot(r,ld)),40.),
         fres = pow(abs(.7+dot(rd,n)),3.),   
         ao = calcAO(p, n);
    // ligthing     
    col = col*mix(1.2*vec3(.25,.08,.13),vec3(.98,.99,.8), mix(amb,diff,.75)) + 
          spec*sp+fres*mix(col,vec3(1),.7)*.4 +
    // kind of sub surface scatering      
        + sss*vec3(1.,.3,.2)
    // sky light reflected from the ground
        + max(0.,dot(vec3(0,-1,0), n))*skyColor;
    // ambiant occusion & fade in distance
    return mix( col*(.3+.7*ao), skyColor, smoothstep(15.,60., res.x) );
}


//---------------------------------------------------------------------
//   Calculate normal
// inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
//---------------------------------------------------------------------
vec3 normal(in vec3 pos, vec3 rd, float t ) {
    vec3 n = vec3(0);
    for(int i=ZERO; i<4; i++) {
        vec3 e = .5773*(2.*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.);
        n += e*map(pos+.002*e).x;
    }
	return normalize(n - max(0., dot(n,rd ))*rd);
}

//---------------------------------------------------------------------
//   Camera
//---------------------------------------------------------------------

mat3 setCamera( in vec3 ro, in vec3 ta, in float r) {
	vec3 w = normalize(ta-ro),
         u = normalize(cross(w, vec3(sin(r), cos(r),0.)));
    return mat3(u, normalize(cross(u,w)), w);
}

mat2 Ro(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

//---------------------------------------------------------------------
//   Entry point
//---------------------------------------------------------------------
//#define iTime (iTime + 250.) // Direct to big Bone
void mainImage(out vec4 fragColor, vec2 fragCoord) {

    gTime = iTime*6.;
   
    // Animation
    int it = int(floor(gTime));
    float kt = fract(gTime), dz = 1.;
   
    head = getPos(HEAD, it, kt, dz);

    shoulder1 = getPos(SHOULDER, it, kt, -dz);
    elbow1 = getPos(ELBOW, it, kt, -dz);
    wrist1 = getPos(WRIST, it, kt, -dz);
    
    foot1 = getPos(FOOT, it, kt, dz);
    ankle1 = getPos(ANKLE, it, kt, dz);
    knee1 = getPos(KNEE, it, kt, dz);
    hip1 = getPos(HIP, it, kt, dz);
    
    shoulder2 = getPos(SHOULDER, it+4, kt, dz);
    elbow2 = getPos(ELBOW, it+4, kt, dz);
    wrist2 = getPos(WRIST, it+4, kt, dz);

    foot2 = getPos(FOOT, it+4, kt, -dz);
    ankle2 = getPos(ANKLE, it+4, kt, -dz);
    knee2 = getPos(KNEE, it+4, kt, -dz);
    hip2 = getPos(HIP, it+4, kt, -dz);
    
    float dx = it%8 < 4 ? -85.*.02 : 85.*.02; 
    
    foot2.x += dx;
    ankle2.x += dx;
    knee2.x += dx;
    hip2.x += dx;
    shoulder2.x += dx;
    elbow2.x += dx;
    wrist2.x += dx;
    
    vec3 v2, v1 = normalize(wrist1-elbow1),
    v0 = normalize(wrist1-shoulder1),
    v3 = normalize(cross(v1,v0));
    baseArm1 = mat3(v0,cross(v1,v3),-v3);
    
    v1 = normalize(wrist2-elbow2),
    v0 = normalize(wrist2-shoulder2),
    v3 = normalize(cross(v1,v0));
    baseArm2 = mat3(v0,cross(v1,v3),v3);
    
    v1 = normalize(shoulder1-shoulder2);
    v0 = normalize(mix(hip1,hip2,.5)-mix(shoulder1,shoulder2,.5));
    v2 = normalize(cross(v1,v0));
    v3 = normalize(cross(v1,v2));
    baseBag = mat3(-v2,v3,v1);
    
    v2 = normalize(knee1 - ankle1);
    v1 = normalize(ankle1 - foot1-v2*.1);
    v3 = cross(v1,v2);
    baseFoot1 = mat3(v1,v3,-cross(v1,v3));
    
    v2 = normalize(knee2 - ankle2);
    v1 = normalize(ankle2 - foot2-v2*.1);
    v3 = cross(v1,v2);
    baseFoot2 = mat3(v1,v3,-cross(v1,v3));
    
    rot = Ro(-1.5708*.4);
    rot1 = Ro(.2*cos(.4*iTime) + .3*cos(.05*iTime));
    rot2 = Ro(pow(.5*cos(.5*3.141592*gTime),2.));
    
// ------------------------------------
 
    // Screen 
    vec2 R = iResolution.xy,
         q = fragCoord.xy/R, 
         m = iMouse.xy/R.y - .5,
         p = (2.*fragCoord.xy-R)/R.y;
      
    // Camera	
    vec3 rd, ro = vec3(  hip1.x+12.*cos(PI*(.05*iTime+m.x)),
                4.5+2.*(sin(.1*iTime))+4.*(m.y+.3),
                hip1.z+12.*sin(PI*(.05*iTime+m.x)));
    rd = setCamera(ro, vec3(hip1.x+1.2, 1.2, hip1.z), 0.) * normalize(vec3(p.xy,4.5) );
  
    // Ray intersection with scene
    vec2 res = Trace(ro, rd);
    res = min2(res, rd.y >= 0. ? vec2(999.,100.) : vec2(-ro.y / rd.y,0.));
    
    // Rendering
    vec3 pos = ro + rd*res.x;
    vec3 n = pos.y<.02 ? vec3(0,1,0) : normal(pos, rd, res.x);
    vec3 col = doColor(pos, rd, n, res);
    col = pow( col, vec3(.4545) );                 // Gamma    
    col *= pow(16.*q.x*q.y*(1.-q.x)*(1.-q.y), .1); // Vigneting
     
	fragColor = vec4(col,1);
}
