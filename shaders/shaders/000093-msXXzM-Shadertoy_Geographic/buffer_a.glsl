// Buffer A (buffer) — Shadertoy Geographic by iapafoto
// https://www.shadertoy.com/view/msXXzM

// Created by Sebastien Durand - 11/2022
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//-----------------------------------------------------
// Sounds based with minor changed on
//     Dave Hoskins [Frozen wasteland] https://www.shadertoy.com/view/Xls3D2
// ------------------------------------------------------------
// Many part of shading based on 
//     iq [Bridge] https://www.shadertoy.com/view/Mds3z2
// ------------------------------------------------------------
// Penguin feets and texture bedes on
//     kuvkar [AngryBird] https://www.shadertoy.com/view/ldKXRz
// ------------------------------------------------------------
//#define iTime (iTime + 120.)


#define FAR 30.

#define  GROUND 0.
#define  BODY 1.
#define  BROW 2.
#define  BEAK 3.
#define  EGG 4.
#define  HEAD 5.
#define  FEET 6.
#define  AILE 7.
#define  COU 8.

#define PI 3.141592653592

#define WITH_SHADOW

float gTime;

int sceneId = 0;
bool withBBox = true;
bool isStanding = true;
bool isWalking = false;


float fogmap(in vec3 p, in float d) {
    float time = 5.*iTime;
    p.xz -= time*7.+(sin(p.z)+1.2+cos(p.x))*3.;
    p.y -= time*.5;
    return (max(noise3D(p*.008+.1),.0)*noise3D(p*.1))*.3;
}


// b(t) = (1-t)^2*A + 2(1-t)t*B + t^2*C
vec3 bezier( vec3 A, vec3 B, vec3 C, float t ) {
    return (1.-t)*(1.-t)*A + 2.*(1.-t)*t*B + t*t*C;
}
// b'(t) = 2(t-1)*A + 2(1-2t)*B + 2t*C
vec3 bezier_dx( vec3 A, vec3 B, vec3 C, float t ) {
    return 2.*((t-1.)*A + (1.-2.*t)*B + t*C);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,-s,s,c);
}

vec2 opSunFlowerRep(in vec2 p, inout vec2 id, bool norot, vec2 k) {
    float a = atan(p.x, p.y);
    vec2 b = vec2(0, length(p))/k.y + a/(2.*PI);
    b.x = ceil(b.y) - b.x;
    b.x *= b.x * 2.*1.618/k.x;
    id = vec2(floor(b)); // x: pos from center, y: id of circle
    b = k.y*(fract(b)-.5); // [-1:1] o n y and y
    b.x *= k.x;
    if (norot) b *= rot(a);
    return b;
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
float pModInterval1(inout float p, float size, float start, float stop) {
	float halfsize = size*.5,
	      c = floor((p + halfsize)/size);
	p = mod(p+halfsize, size) - halfsize;
	if (c > stop) {
		p += size*(c - stop);
		c = stop;
	}
	if (c < start) {
		p += size*(c - start);
		c = start;
	}
	return c;
}

//////////////
// distance functions from from https://iquilezles.org/articles/distfunctions
/////////////

float smin(float a, float b , float s){
    float h = clamp(.5 + .5*(b-a)/s, 0. , 1.);
    return mix(b, a, h) - h*(1.-h)*s;
}

float smax(float a, float b, float s){
    float h = clamp(.5 + .5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1.-h)*s;
}

// iq - https://www.shadertoy.com/view/Wdjfz3
float sdEgg(vec3 q, float sz) {
    const float k = sqrt(3.);
    float r = sz*(.6 - .3);
    vec2 p = vec2(length(q.xz), .9*q.y);    
    return (p.y<0. ? length(p) - r : k*(p.x+r)<p.y ? length(vec2(p.x,  p.y-k*r)) : length(vec2(p.x+r,p.y)) - 2.*r) - sz*.3;
}

// iq - https://www.shadertoy.com/view/ldj3Wh
vec2 sdBezier(vec3 p, vec3 b0, vec3 b1, vec3 b2) {
    b0 -= p; b1 -= p; b2 -= p;
    vec3 b01 = cross(b0,b1), b12 = cross(b1,b2), b20 = cross(b2,b0),
         n =  b01+b12+b20;
    float a = -dot(b20,n), b = -dot(b01,n), d = -dot(b12,n), m = -dot(n,n);
    vec3  g =  (d-b)*b1 + (b+a*.5)*b2 + (-d-a*.5)*b0;
    float t = clamp((a*.5+b-.5*(a*a*.25-b*d)*dot(g,b0-2.*b1+b2)/dot(g,g))/m, 0., 1.);
    return vec2(length(mix(mix(b0,b1,t), mix(b1,b2,t),t)),t);
}

vec3 sdBezierUV(vec3 p, vec3 a, vec3 b, vec3 c, vec2 h) {
    vec3 bb = normalize(cross(b-a,c-a)),
         qq = bezier(a,b,c,h.y),
         tq = normalize(bezier_dx(a,b,c,h.y));  
    return vec3(dot(p-qq, normalize(cross(bb,tq))), h.y, dot(p-qq,bb));
}   

float sdSegment(vec3 p, vec3 a, vec3 b) {
    vec3 pa = p - a, ba = b - a;
    return length(pa - ba*clamp(dot(pa,ba)/dot(ba,ba), 0., 1. ));
}

float sdEllipsoid( in vec3 p, in vec3 r) {
    float k0 = length(p/r), k1 = length(p/(r*r));
    return k0*(k0-1.)/k1;
}

vec3 bend(vec3 p, float angle){
	float c = cos(angle*p.z), s = sin(angle*p.z);
    return vec3(mat2(c,-s,s,c)*p.yz,p.x);
}

float hGround(vec3 p) {
    p.zx = p.xz;
    p.y *= 1.5;
    float tx = .1*(cos(p.x*.03))*(textureLod(iChannel1, p.xz/16. + p.xy/80., 0.0).x);
    vec3 q = p*.25;
    float h = tx + .5*(dot(sin(q)*cos(q.yzx), vec3(.222))) + dot(sin(q*1.3)*cos(q.yzx*1.4), vec3(.111));
    return (sceneId == -1 ? -2.7 : sceneId == 3 ? -.5 : -1.) * smin(0.,smoothstep(.2,3., abs(p.z))*h*5.,.2);
}


///////////////////////////
///////////////////////////
///////////////////////////


// kuvkar [AngryBird] https://www.shadertoy.com/view/ldKXRz
float sdToes( vec3 p, vec2 h) {
  p.x += sin(p.x * 40.) * .007 + cos(p.y * 600.) * .001;
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}

// kuvkar [AngryBird] https://www.shadertoy.com/view/ldKXRz
float sdFeet(vec3 rp, inout float body, float dfeet, float side) {
    vec3 legpos = vec3(side*.055, -.16, 0.),
     nFeet = vec3(0., .12, .01);
    float a = -.5*dfeet;
    nFeet.yz *= rot(a);
    vec3 footpos = legpos - nFeet;
    float leg = sdSegment(rp, -legpos, mix(legpos, footpos,.45)) - .03;
    body = smin(body, leg,.02);
    vec3 pFeet = rp - footpos;
    pFeet.yz *= rot(-a);
    float d = sdToes( (pFeet + vec3(0, -.03, -.01)), vec2(.012, .01)) - .008;
    pFeet.x = abs(pFeet.x); 
    d = smin(d, sdToes( bend (pFeet + vec3(0, -.02, .01) , 4.), vec2(.01, .045)), .01);
    pFeet = bend(pFeet + vec3(-0.015, -.02, .02), 12.);
    pFeet.zy *= rot(-.4);
    return smin(d, sdToes(pFeet, vec2(.009, .03)), .01);
}


float sdPenguin(in vec3 rp, in vec3 p0, float hG, float id, inout vec4 r) {
    rp.y -= hG + .27;
  
    float Time = (sceneId ==-2 || sceneId == 3 ? .3*iTime : iTime) + .2*id,
         t = 1.85*Time,
         k = cos(PI*t);

    if (!isStanding) {
        rp.z = -rp.z;
    }
    if (isWalking) {   
        rp.z += .02*cos(1.57+PI*t*2.);  // avance de la marche
        rp.x += .1*hash11(10.*id); // position decalle suivant id
    }
    rp.x *= .9+.2*hash22(vec2(id,id)).x; // +/- gros et grands suivant id

    if (!isStanding) {
        rp.xyz = rp.xzy + vec3(0,0,.22);
    }
    
    // Fastest thanks to this bounding box
    if (withBBox) {
        float dBox = sdEllipsoid(rp-vec3(0,.025,0), isStanding?vec3(.3,.35,.2):vec3(.5,.4,.3));
        if (dBox > 0.) return dBox + .005+.01*hash12(p0.xz+p0.y);
    }
    
    vec3 headPos = vec3(0, .26, -.05), 
         peak = - .14 * vec3(0.,0.,1.),
         legpos1 = vec3(.055, -0.16, -.02),
         legpos2 = vec3(-.055, -0.16, -.02),
         nFeet1 = vec3(0., .12, .01),
         nFeet2 = vec3(0., .12, .01);
    float up = 0., dfeet = 0., dfeet1 = 0., dfeet2 = 0.,
          k0 = cos(PI*t), k1 = cos(PI*t+.25), k2 = cos(PI*t-.25);
    
    if (isWalking) {    
         dfeet = .5*sign(k)*pow(abs(k),1.5);
         dfeet1 = .5*sign(k1)*pow(abs(k1),1.5);
         dfeet2 = .5*sign(k1)*pow(abs(k2),1.5);
         up = rp.x>0. ? .2 - .2*dfeet : .2 + .2*dfeet; 
         nFeet1.yz *= rot(.5*(.6+dfeet1));
         nFeet2.yz *= rot(-.5*(.6-dfeet2));
    }
    
    float body = 999.; 
        
    if (isWalking) {    
        vec3 rotPos = mix(legpos1 - nFeet1, legpos2 - nFeet2, .5+.5*k);
        rp -= rotPos; 
        rp.yz *= rot(-.1);  // penche en avant pendant la marche
        rp.xy *= rot(.25*.25*dfeet); // penche sur le coté
        rp.xz *= rot(-.5*dfeet); // tourne autour du pied
        rp += rotPos;
    }
    
    vec3 rpHead = rp - headPos;
    if (!isStanding) {
        headPos.z += .15;
        rpHead.yz *= rot(4.84);
        rpHead.y -= .15;
    }    
    if (sceneId == 4) {
        rpHead.yz *= rot(1.+.05*cos(.3*iTime)); // rotation haut bas
        rpHead += vec3(0,-.025,.035);
        
    } else if (sceneId == 5) {
        rpHead.xz *= rot(-.5*cos(2.*Time)); // droite gauche
        rpHead.yz *= rot(.5+.2*cos(Time)); // rotation haut bas
        rpHead += vec3(0,-.01,.02);
    } else {        
        rpHead.yz *= rot(-.06*cos(5.*Time+cos(Time))); // rotation haut bas
        rpHead.xz *= rot(-.5*cos(2.*Time)); // droite gauche
    }
   // rpHead.zy += .02*headup;
    
    vec3 rp_real = rp;
	rp.x = -abs(rp.x); // most of the stuff is just mirrored

    // body
    body = min(body, sdEllipsoid(rp, vec3(.12,.22,.1)));
    // pectoraux
    body = smin(body, sdEllipsoid(rp-vec3(-0.0,.105,-.03), vec3(0.1-.005*up,.08,.055-.005*up)), .02);
    // queu
    body = smin(body, sdSegment(rp, vec3(0,-.18,.05), vec3(0,-.28,.12)) + .3*(rp.z -.12)-.01, .05);

    float body0 = body;
    
    // aile
    vec3 pa = rp - vec3(-.1,.125,.02);
    pa.xz *= rot(.2); // rotation axe 
    
    if (sceneId == 4) {
        pa.zy *= rot(.3+.3*cos(.5*iTime+id));
        pa.xy *= rot(.5-.03*cos(.41*iTime+2.*id)); // Leves
    } else {
        pa.zy *= rot((isStanding ? -1.5*up : 0.) +.3);//+.1*cos(8.*Time)); // Avant arriere
        pa.xy *= rot(isStanding ? .3 : .5-.3*k1); // Leves
    }
    pa += vec3(-.01+.02*up,.16,.0);  
     
    float aile = sdEllipsoid(pa, vec3(.025,.15,.06));
    aile = smin(aile, -sdEllipsoid(pa-vec3(.04,-.037,.03), vec3(.054,.17,.08)), -.03);
    body = smin(body, aile, .03*smoothstep(.07,.15,pa.y));
    
    // head
    float head = sdEllipsoid(rpHead, vec3(.04,.04,.06));
    body = min(body, head);
    // bec
    vec2 bez = sdBezier(rpHead, .4*peak, peak, peak + vec3(0,-.02,-.001));
    body = smin(body, (bez.x - .002-.01*smoothstep(1.,.3, bez.y)), .03);
   
    // oeil
    rpHead.x = abs(rpHead.x);
    vec3 eyePos = vec3(.019, .01, -.04);
   
    float dEye = length(rpHead - eyePos-vec3(-.007,0,0)) - .012;
     
    vec3 uvEye = rpHead - eyePos;
    float dEyeHole = max(length(rpHead - eyePos-vec3(0,.007,0)), 
                         length(rpHead - eyePos+vec3(0,.007,0)))- .015;  
    
    // cou
    vec2 cou = sdBezier(rp_real, headPos, vec3(0, .2,.02), vec3(.0, .15,.03));
   
    body = smin(body, cou.x-.04,.01);
    body = max(body, -dEyeHole);
    body = min(body, dEye);
     // legs
    float feet = min(sdFeet(rp_real, body, .6+dfeet1, 1.), sdFeet(rp_real, body, .6-dfeet2, -1.)); 
    
    float d = body0;
    r = vec4(BODY, rp);

    if (head < d) {
        d = head; r = vec4(HEAD, rpHead);
    }
    if (aile < d) {
        d = aile; r = vec4(AILE, pa);
    }
    if (feet < d) {
        d = feet; r = vec4(FEET, rp);
    } 
    if (cou.x-.04<d) {
        vec3 uvCou = sdBezierUV(rp_real, headPos, vec3(0, .2,.02), vec3(.0, .15,.03), cou);
        d = cou.x-.04; 
        r = vec4(COU, isStanding ? uvCou : vec3(-uvCou.x, uvCou.y, uvCou.z));
    } 

    return min(feet, body);
}


vec4 rColor;


float mapGround(in vec3 p0) {
    return p0.y - hGround(p0);
}

float map(in vec3 p0) {
    float hG = hGround(p0),
          dGround = p0.y - hG;

    vec3 p = p0;
    float id = 0.;
    if (sceneId == 4) {
        p.z +=.1;
        id = sign(p.z);
        p.z = abs(p.z);
        p.z -=.16;
        p.x += .01*id;
        
    } else if (sceneId == 3) {
        vec2 id3 = vec2(0);
        vec3 p1 = p0;
        p1.xz += 20.;
        p.xz = opSunFlowerRep(p1.xz, id3, false, vec2(2.5,1.1));
        // Couples
        if (mod(id3.y,2.) <.5) p.z = -p.z;
        p.z += .35*smoothstep(25.,35., gTime);
        id = id3.x;
        
    } else if (sceneId == 5) {
        vec2 id3 = vec2(0);
        vec3 p1 = p0;
     //   p1.xz -= vec2(3.,9.);
        if (length(p1.xz)>5.2) return 999.;
        p.xz = opSunFlowerRep(p1.xz, id3, false, vec2(.7,.4));
        p.xz = p.zx;
        //p.x += .05;
        id = id3.x;
        if (id < 5. /*|| id>700.*/) return 1.;
        
    } else if (sceneId != -2) {
         float dz = sceneId == -1 || sceneId == 6 ? .29*gTime-2. : .14*gTime;
         if (sceneId == 1) {
             p = p0;
             p.x -= 5.;
             dz *= 6.;  // 6 fois plus rapide en glissades
         }
        
         if (sceneId == 6) {
             p.z = -p.z + dz;
         } else {
             p.z += dz;
         }
         float id2 = 0.;
         if (sceneId == 2) {
             p.x += .8*cos(.5*p.z+cos(.1*p.z));
             id2 = pModInterval1(p.x, .45, -1.,1.);
             p.z += .6*hash11(id2+1.2);
         }

//p.z = mod(p.z +.45, .9) - .45;
         id = id2*100.+ pModInterval1(p.z, sceneId == -1 ? 16. : sceneId == 6 ? 3.8 : .9, -58.,58.);
         if (sceneId == 6) p.xz += vec2(3,2)*(.5-hash22(vec2(id, id2)));
         if (sceneId == 1 || id>2. && id<4.) isStanding = false;
     }
          
     float d = sdPenguin(p, p0, hG, id, rColor);
     isStanding = true;
     if (sceneId == 4) {
        float d0 = sdEgg(p0-vec3(-.04,.085,-.04),.075);
        if (d0<d) {
            d = d0;
            rColor = vec4(EGG,p0);
        }
     }
     return d * (sceneId == 3 ? .45 : .7);

}

//-------------------------------------------------------------
//     Textures 3D (Shane)
//-------------------------------------------------------------

vec3 tex3D(in vec3 p, in vec3 n){
    p += 10.;
    p *= 100.;
    n = max(n*n, .001);
    n /= (n.x + n.y + n.z );  
	return noised(p.yz)*n.x + noised(p.zx)*n.y + noised(p.xy)*n.z;
}

// Grey scale.
float grey(vec3 p) { return dot(p, vec3(.299, .587, .114)); }

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total.
vec3 doBumpMap(vec3 p, vec3 n, float k){
    const float ep = .001;
    vec3 grad = vec3(grey(tex3D(vec3(p.x-ep, p.y, p.z), n)),
                     grey(tex3D(vec3(p.x, p.y-ep, p.z), n)),
                     grey(tex3D(vec3(p.x, p.y, p.z-ep), n)));
    grad = (grad - grey(tex3D(p, n)))/ep;             
    grad -= n*dot(n, grad);          
    return normalize(n + grad*k);
}

//---------------------------------------------------------------------
//   Calculate normal
// inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
//---------------------------------------------------------------------
vec3 normal(in vec3 pos, vec3 rd, float t, float k) {
    withBBox = false;
    vec3 n = vec3(0);
    for( int i=ZERO; i<4; i++) {
        vec3 e = .5773*(2.*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.);
        n += e*map(pos+k*e);
    }
	return normalize(n - max(0., dot(n,rd))*rd);
}

vec3 normalGround(in vec3 pos, vec3 rd, float t, float k) {
    vec3 n = vec3(0);
    for( int i=ZERO; i<4; i++) {
        vec3 e = .5773*(2.*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.);
        n += e*mapGround(pos+k*e);
    }
	return normalize(n - max(0., dot(n,rd))*rd);
}

#ifdef WITH_SHADOW

float softshadow( in vec3 ro, in vec3 rd, float k ) {
    withBBox = false;
    float res=1., t=.05+.1*hash22(rd.xy).x, h=1.;
    for(int i=ZERO; i<48; i++ ) {
        h = min(map(ro + rd*t), mapGround(ro + rd*t));
        res = min( res, k*h/t );
		t += clamp( h, .01, .1);
		if (h<.005) break;
    }    
    return clamp(res,0.,1.);
}

#endif

vec3 skyColor(vec3 col, vec3 ro, vec3 rd, float sun) {
    vec2 cuv = ro.xz + rd.xz*(100.-ro.y)/rd.y;
    float cc = texture( iChannel1, .0003*cuv + .1+ .0023*iTime ).x;
    cc = .65*cc + .35*texture( iChannel1, .0006*cuv + .00115*iTime ).x;
    cc = smoothstep( .3, 1., cc );        
    return mix( col, vec3(.95+.20*(1.-cc)*sun), .7*cc );
}


float trace(vec3 ro, vec3 rd, inout vec3 col) {
   // vec3 ro = rp;

	float d, precis = .006, t = 0., tg = 0., m = -1., fog = 0.;

    for (int i=ZERO; i<200; i++) {
        t += d;
	    d = map(ro+rd*t);     
        if (sceneId>4) fog += fogmap(ro+rd*t, t);
        if (abs(d) < 1e-2*t*precis || t>FAR) 
            break;
    }

    for( int i=ZERO; i<300; i++) {
	    d = mapGround(ro+rd*tg);
        tg += d;
        if (abs(d) < 1e-2*tg*precis || tg>t) 
            break;        
    }
    fog = min(1., .05*fog);
    
    vec3 pos, nor;
    
    if (tg < t) {
        pos = ro+rd*tg;
        rColor = vec4(GROUND, pos);
        t = tg;
        nor = normalGround(pos, rd, t, .05);
    } else {
        pos = ro+rd*t;
        withBBox = false;
        map(pos); // To get Color in rColor
        nor = normal(pos, rd, t, .007);
    }
 
    vec3 lig = normalize(vec3(-.5,.25,-.3));
    col = .9*(2.5*vec3(.18,.33,.45) - rd.y*1.5);
    
    float sun = clamp( dot(rd,lig), 0., 1.);
	col += vec3(2,1.5,0)*.8*pow( sun, 32.);
    
    vec3 bgcol = col, color = bgcol, mate2 = vec3(0);
    bool isSea = false;

    if (t<FAR) {
        vec3 ch = vec3(.04), cb = vec3(.1), cw = vec3(1),
             uvw = rColor.yzw;
       
        float kspe = .1; // coeff specularity
        if (rColor.x == BEAK) {
            kspe = 1.;
        }
        if (rColor.x != BEAK && rColor.x != EGG && rColor.x != GROUND) {
            nor = doBumpMap(rColor.yzw*3.1*vec3(1,.2,1)+2., nor, .0005); 
            cb += .05*tex3D(5.*rColor.yzw*vec3(1.,.25,1.), nor).x;
        }
       
        color = vec3(.7);
        
        if (rColor.x == EGG) {
            color = vec3(.9,1.,.8);
            
        } else if (rColor.x == HEAD) {
            color = mix(ch, .5*vec3(1,.55,.5), smoothstep(.03,.025, length(vec2(9.,1.)*(rColor.zw-vec2(-.008,-.107)))));
            
            vec2 eyePos = rColor.zw - vec2(.014,-.038);
            float dEye = max(length(eyePos-vec2(.003,0)), length(eyePos+vec2(.003,0)))- .007;  
            kspe = dEye < 0. ? 2. : .1; 
            vec3 colEye = mix(vec3(0), .1*vec3(1,.7,.5), .6+.4*smoothstep(.0,.001, length(eyePos+vec2(0,.006))-.004));
            color = mix(colEye, color, smoothstep(.0,.001, dEye));
            
        } else if (rColor.x == AILE) {
            color = mix(cb, cw, smoothstep(.001,.02,rColor.y+.1*(rColor.w-rColor.z)));
           
        } else if (rColor.x == BODY) {
            
            color = vec3(1);
          
            color = mix(color, vec3(1,.5,0), smoothstep(.14,.2, rColor.z));
            color = mix(color, vec3(1,1.,0), smoothstep(.17,.2, rColor.z));
            
            color = mix(cb, color, smoothstep(.03,.04,-rColor.w+.03 -.024*sin(.7+12.*uvw.y)));
            
            color = mix(mix(vec3(1,1,0),vec3(1,1,1), smoothstep(.0,.01, length(rColor.z)-.199)),
            color, smoothstep(.039,.042, length(rColor.zw-vec2(.235,0))+.003));
            // le petit trait noir des epaules
            color = mix(ch, color, smoothstep(.0,.005, sdSegment(vec3(0,rColor.z,rColor.w), vec3(0,.1,-.024), vec3(0,.195,-.01))-.05*(rColor.z-.1)));
            
        } else if (rColor.x == COU) {
        
            color = .5+.5*cos(vec3(200,20,200)*rColor.yzw);
            vec3 uv = vec3(200,20,200)*rColor.yzw - vec3(0,8,0);

            color = mix(cw, vec3(1,1,.001), smoothstep(-2.,2., -uv.y));
            color = mix(color, vec3(1,.5,.001), smoothstep(-1.,5., -uv.y));
            color = mix(color, mix(ch,cb, smoothstep(-4.,8.,uv.y)), smoothstep(.4,.0, 4.+uv.y+1.8*cos(.6*uv.z)-20.*smoothstep(.1,8.,-uv.x)));
       
       } else if (rColor.x == FEET) {
            color = vec3(.3);
            kspe = .2;
            
        } else if (rColor.x == GROUND) {
            color = vec3(.97);
            float dSea = pos.y - (.02 + .005+.005*cos(1.5*iTime+length(pos.xz)));
            isSea = (sceneId == -2 && pos.z>-3. && dSea<.007);

            if (isSea) {
               color = mix(color,.2*vec3(.5,.7,.9), smoothstep(.012, .0, dSea));
           //  color = mix(color+.1*vec3(0,1,1), color, smoothstep(.0, .01, dSea+.02+.001*cos(iTime)));
            }
           
            kspe = .5;
            nor = doBumpMap(rColor.yzw*.7, nor, .0003); 

            float iss = smoothstep( .5, .9, nor.y );
            iss = 2.*mix( iss, .9, .75*smoothstep( .1, 1., noise3D(.25*pos)));
            vec3 cnor = normalize( -1. + 2.*texture( iChannel2, .25*pos.xz).xyz );
            cnor.y = abs(cnor.y);
            float spe2 = max(0., pow( clamp( dot(lig,reflect(rd,cnor)), 0., 1.), 16.));
            mate2.y = spe2*iss*(.5+.5*cos(20.*iTime+6.28*hash12(pos.xz)));
        }

		// lighting
        float sky = .6 + .4*nor.y,
             bou = clamp(-nor.y,0.,1.),
             dif = max(dot(nor,lig),0.),
             bac = max(.2 + .8*dot(nor,normalize(vec3(-lig.x,0,-lig.z))),0.);
		
#ifdef WITH_SHADOW
        float sha = 0.;
        if (dif > 0.) {
            sha = softshadow( pos+.075*nor*hash12(10.*pos.xy+1.234*pos.z), lig, 4.);
        }
#else         
        float sha = 1.;
#endif
        float fre = pow(clamp(1.+ dot(nor,rd), .01, 1. ), 3. ),
              spe = pow(max( dot( reflect(-lig, nor), -rd ), 0.), 16.); // Specular term.
		// lights
		vec3 lin = dif*vec3(1.7,1.15,.7)*pow(vec3(abs(sha)),vec3(1.,1.2,2.));
		lin += 1.2*bou*vec3(.15,.2,.2);
        lin += fre*vec3(1,1.25,1.3)*.5*(.5+.5*dif*sha)
                    +sky*vec3(.05,.20,.45)
					+bac*vec3(.2,.25,.25);
 
        lin += mate2.y*vec3(1,.6,.5)*4.*dif*(.1+.9*sha);
        col = color*lin + (.5+.5*color)*spe*kspe;//*sha;
    
        if (rColor.x == GROUND) {
            vec3 ref = reflect(rd, nor);
            col += .2*col*skyColor(bgcol, pos, ref, clamp(dot(ref,lig), 0.0, 1.0 )); 
        }
        col = mix( col, bgcol, smoothstep(15.,FAR,t) );

        if (isSea) {
           col += skyColor(col, pos, reflect(rd, nor), sun);
        }
    } else {
        col = skyColor(col, ro, rd, sun);
    }

	// sun glow
    col += vec3(1,.6,.2)*.4*pow( abs(sun), 4.);
  
    if (sceneId >= 5) {
       col = mix(.7*col, vec3(0.6, .65, .7), sqrt(fog));
       col = length(col)*.2 + .8*col;
    }
    
    return t;
}

mat3 lookat(vec3 from, vec3 to) {
    vec3 f = normalize(to - from),
         u = normalize(cross(normalize(cross(f, vec3(0,1,0))), f));
    return mat3(normalize(cross(u, f)),u,f);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord) {
    rColor = vec4(0);

	vec2 q = fragCoord.xy / iResolution.xy,
         uv = q-.5;
    uv.y /= iResolution.x / iResolution.y;

    vec3 rd = normalize(vec3(uv, 1)),
         rp = vec3(0, 1, -2.2);
    
    vec2 im = iMouse.xy / iResolution.xy;
    
    gTime = iTime - 40.;
    
    sceneId = 6; 
   
    if (gTime < -20.) sceneId = -2;
    else if (gTime < 1.)  sceneId = -1;
    else if (gTime < 20.) sceneId = 0;
    else if (gTime < 25.) sceneId = 1;
    else if (gTime < 44.) sceneId = 2;
    else if (gTime < 70.) sceneId = 3;
    else if (gTime < 85.) sceneId = 4;
    else if (gTime < 105.) sceneId = 5;
    else sceneId = 6;
    
    isWalking = true;

    if (sceneId == 5) {
        float dd = smoothstep(135.,145., iTime);
        if (uv.x<mix(.7,-.7,dd)-uv.y*.25) { 
            uv *= mix(1.,2.,dd);
        } else {
            uv.x -= mix(.5,0.,dd);
            sceneId = 6;         
        }
    }
    
    if (sceneId == -2) { 
        gTime = iTime;
        isWalking = false;
        gTime = iTime;
        withBBox = false;
        rp = vec3(.0,.57,-.15) + mix(.2,.7,gTime/20.)* vec3(-cos(.1*gTime), -.05, sin(.1*gTime));
        rp.y = max(rp.y, hGround(rp) + .1);
        rd = lookat(rp, vec3(.0,.57,-.15)) * normalize(vec3(uv, 1.));
        
    } else if (sceneId == -1) { 
        gTime = iTime-20.;
        rp = mix(vec3(2.7,.5,-4.), vec3(20,7.,33), smoothstep(7.,27.,gTime));
        rp.y = max(rp.y, hGround(rp) + .1);
        rd = lookat(rp, vec3(0,1.,-2)) * normalize(vec3(uv, 1.));
        
    } else if (sceneId == 0) {
        // Marche petit groupe
        if (sceneId == 6) gTime = iTime - 145.;
        rp = vec3(2.7-.05*gTime,-1.+.035*gTime,1.7);
        rp.y = max(rp.y, hGround(rp) + .1);
        rd = lookat(rp, vec3(0,0.5,0)) * normalize(vec3(uv, 1.));
        
    } else if (sceneId == 6) {
        // Marche petit groupe retour
        gTime = iTime - 145.;
        rp = vec3(.7,.7+.035*gTime,-36.+.39*gTime);
        rp.y = max(rp.y, hGround(rp) + .1);
        rd = lookat(rp, vec3(0,0.5,-38.+.39*gTime)) * normalize(vec3(uv, 1.));

    } else if (sceneId == 1) {
        // Glissades
        rp = vec3(3.7,1.,-18.7);
        rp.y = max(rp.y, hGround(rp) + .1);
        rd = lookat(rp, vec3(5,0.5,-15.)) * normalize(vec3(uv, 1.));
        
    } else if (sceneId == 2) {
        // Marche en grand groupes
        rp = vec3(12.7,3.5+.035*gTime,.7-.5*gTime); 
        rp.y = max(rp.y, hGround(rp) + .1);
        rd = lookat(rp, vec3(-2.,.5,10.-1.*gTime)) * normalize(vec3(uv, 1.));
        
    }  else if (sceneId == 3) {
        // Rassemblement + rencontre
        gTime = iTime - 58.;
        rp = vec3(27.7+.3*gTime+5.*sin(.2*gTime), 8.+cos(.31*gTime),1.7-.5*gTime+5.*cos(.2*gTime));
        rp.y = max(rp.y, hGround(rp) + .1);
        
        vec3 ta = vec3(-16.-.5*gTime,.05, -23.+.3*gTime),
        rp2, ta2 = vec3(1.3,.45,17.1);
        rp2 = ta2 + vec3(cos(.6*gTime+1.7),-.05+.05*cos(iTime), sin(.6*gTime+1.7)); 
        rp = mix(rp,rp2,smoothstep(20.,40.,gTime));
        ta = mix(ta,ta2,smoothstep(20.,40.,gTime));
        rd = lookat(rp, ta) * normalize(vec3(-uv.x, uv.y, 1.1));
        
     } else if (sceneId == 4) {
        gTime = iTime-70.;
        isWalking = false;
        withBBox = false;
        rp = vec3(0,.5,-.15) + (1.25+.05*gTime)*vec3(-cos(-.1*gTime), .01, sin(-.1*gTime));
        rp.y = max(rp.y, hGround(rp) + .1);
        rd = lookat(rp, vec3(0,.5,-.15)) * normalize(vec3(uv, 1.));
        
     } else if (sceneId == 5) {
        // froid
        gTime -= 70.;
        isWalking = true;
        rp = vec3(4.*sin(-.02*gTime), 1.2, 5.*cos(-.02*gTime));
        rp.y = hGround(rp) + 1.1+.1+.2*cos(.2*iTime);
        vec3 ta = vec3(2.5*sin(-.02*gTime-1.)-1.6+.1*gTime, .5, 2.5*cos(-.02*gTime-1.));
        rd = lookat(rp, ta) * normalize(vec3(-uv.x, uv.y, 1.1));
     } 
    
    vec3 col; 
    float dist = trace(rp, rd, col);
    fragColor = vec4(col, dist);
}

// undersea
// https://www.shadertoy.com/view/llcSz8