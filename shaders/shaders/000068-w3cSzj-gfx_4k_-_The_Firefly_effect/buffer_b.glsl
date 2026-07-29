// Buffer B (buffer) — gfx 4k - The Firefly effect by iapafoto
// https://www.shadertoy.com/view/w3cSzj

#define ZERO min(0,iFrame)

#define BOUNCE 3

float seed, dhaloLight;
int sh, ii;


// --------------------------------------
// Rotations Functions
// --------------------------------------

// FabriceNeyret2
mat2 rot(float a) { return mat2(cos(a-vec4(0,1.57,11,0)));}

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}


// --------------------------------------
// Hash and Rand Functions
// --------------------------------------

float hashid(float s) {
    float p=fract(s*.1031);
	p+=p*(p+19.19)*3.;
	return fract(2.*p*p);    
}

float hash() {
	return hashid(seed++);    
}

vec2 hash2() { return vec2(hash(),hash());}

const uint k = 1103515245U;  // GLIB C
vec3 hash33u( uvec3 x) {
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k; 
    return vec3(x)/float(0xffffffffU);
}

vec3 hash33(vec3 c) {
    return hash33u(uvec3(33.33 + 128567.*cos(1347.713*c)));
}

vec2 randCircle() {
    float a = 6.28*hash();
    return .5*sqrt(hash())*cos(a+vec2(0,1.57));
}
/*
vec2 randHex() {
    return .5*rot(floor(hash()*6.)*1.047)*(sqrt(hash())*cos(hash()*1.047-vec2(0,1.57)));
}
*/
// --------------------------------------
// Noise Functions
// --------------------------------------

float noise3D(vec3 p){
	vec3 s = vec3(113, 157, 1), ip = floor(p); 
    vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
	p -= ip; 
    p = p*p*(3. - 2.*p);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float fbm(in vec3 p){
    return .5333*noise3D(p) + .2667*noise3D(p*2.02 ) + .1333*noise3D(p*4.03) + .0667*noise3D(p*8.03);
}

/* 2* faster but some regularity
uvec4 rndU44(uvec4 u) { return u.yzwx * u.zwxy ^ u; }
uvec4 h44uvc(vec4  c) { return uvec4(33.33 + 22.33*c); }
vec3  hash33(vec3  c) { return smoothstep(0.4, 0.6, vec4(rndU44(rndU44(uvec4(33.33 + 22.33*100.*c,1234))))/ 43e8).xyz; }
*/

// BigWIngs (adaptation)
float wnoise(vec3 p, float n) {
    // https://www.shadertoy.com/view/wsBfzK
    float z = 3., k = 1.15;
    float d=0.,s=1.,m=0., a;
    for(float i=float(ZERO); i<n; i++) {
        vec3 q = p*s, g = fract(floor(q)*vec3(123.34,233.53,314.15));
    	g += dot(g, g+23.234);
		a = fract(g.x*g.y)*1e3 +z*(mod(g.x+g.y, 2.)-1.); // add vorticity
        //random rotation in 3d. the +.1 is to fix the rare case that g == vec3(0)
        //https://suricrasia.online/demoscene/functions/#rndrot
        q = erot(fract(q)-.5, normalize(tan(g+.1)), a);
        d += sin(q.x*10.+z)*smoothstep(.25, .0, dot(q,q))/s;
        p = erot(p, vec3(-.71,.71,0),.955)+i; //rotate along the magic angle
        m += 1./s;
        s *= k; 
    }
    return d/m+.5;
}

// --------------------------------------
// Cool usefull geometry stuff
// --------------------------------------

float voronoi(vec3 x) {
    vec3 b,r,p = floor(x), f = x-p;
	float d = 99.;  
    for(int k=ZERO-1; k<=1; k++)
    for(int j=ZERO-1; j<=1; j++)
    for(int i=ZERO-1; i<=1; i++) {
        b = vec3(i,j,k);
        r = b - f + hash33(p + b);
        d = min(d, dot(r, r));
    }
    return sqrt(d);
}

// Super cool function for gaussian blured reflexions
vec3 gaussianReflect(vec3 r, vec3 n, float k) {
    float a = 6.28*hash();
    r = reflect(r, n);
    n = normalize(vec3(-r.z,0,r));
    return normalize(r + k*.1* sqrt(-2. * log(hash())) * (cos(a) * n + sin(a) * cross(r, n)));
}

mat3 basisMatrix(vec3 ww) {
    ww = normalize(ww);
    vec3 uu = normalize(vec3(ww.z,0,-ww.x));
    return mat3(-uu, normalize(cross(ww,uu)), ww);
}    

// --------------------------------------
// Distance field util functions
// --------------------------------------

float opRep(float p, float s, float b) {
    return p-s*clamp(round(p/s),0.,b);
}

vec2 min2(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

// SmoothMinMax  (k<0 ? maximum : minimum)
float smm(float a, float b, float k) {
    b = k<0.?-b:b;
    float h = clamp(.5 + .5*(b-a)/k, 0., 1.);
    return mix(b, a, h) - h*(1.-h)*k;
}


// --------------------------------------
// Distance field primitives (iq)
// --------------------------------------

float sdBox(vec3 q, vec3 b) {
  q = abs(q) - b;
  return min(max(q.x,max(q.y,q.z)),0.) + length(max(q,0.));
}

float sdEllipsoid(vec3 p, vec3 r) {
  float k = length(p/r);
  return k*(k-1.)/length(p/r/r);
}

vec2 sdCapsule(vec3 p, vec3 a, vec3 b) {
  p -= a; b -= a;
  float k = clamp(dot(p,b)/dot(b,b), 0., 1.);
  return vec2(length(p - b*k),k);
}

// capsule with bump in the middle -> use for arms and legs
vec2 sdBumpCapsule(vec3 p, vec3 a, vec3 b, float r, float k) {
    vec2 v = sdCapsule(p,a,b);
    v.x -= r + k*sin(3.141592*v.y);
    return v;
}

// --------------------------------------
// Distance field modeling (iapafoto)
// --------------------------------------

vec2 sdCroco(vec3 p00) {
    vec3 p0 = p00;
    p0.xz *= rot(.7);

    vec3 pEye = vec3(3.5,.2,.4);

    vec3 p = p0;
    p.z = sqrt(p.z*p.z+.002); // sabs(p.z,.002);
    vec3 pe = p;
    
    p.x -= .1;
    p.xz *= rot(.22);
    p.yz *= rot(.2);
    
    p.z += .2*cos(p.x)-.03*cos(12.*p.x)/(1.+p.x*p.x); // head and teeth bumps
    p.y += .17*sin(3.*p.z);
    
    // head
    float d = sdBox(p-vec3(2.7,-.2,-1.2), vec3(2.5,0,1.6))-.25;
    // muzzle
    d = smm(d, sdCapsule(p, vec3(.3,-.05,.3), vec3(4,-.1,-1.)).x-.2, .2);
    d = smm(d, sdCapsule(p, vec3(1.5,-.1,0), vec3(5,-.1,-2.)).x-.2, .3);
    // eyes
    float dEye = length(pe - pEye);   
    dEye = smm(dEye-.5, length(pe - pEye - vec3(-.4,.2,.45))-.45, -.3);
    d = smm(d,dEye,.3);
    // scales
    float n = ii==0 && d<.1 ? .07*smoothstep(-.2,-.08,p0.y)*voronoi(15.*p) : .06;   
 
    // Water
    float dw = 34.54*d + 3.768; // sinc(d+.2,11.);
    vec2 r = vec2(p00.y +.2 + .2*sin(dw)/dw/dw,5.); // wave of crocodile sinc(d+.2,11.)

    d += .3*n;
    // noze bump
    d = smm(d, length(p -vec3(.3,.1,.35)) - .18,.1); 
    // noze hole
    d = smm(d, sdEllipsoid(p - vec3(.25,.22,.32), vec3(.035,.15,.05)), -.1) 
    + .3*n;  
    
    if (length(p0-vec3(.35,-.2,0))<.4) {
         d += .004*smoothstep(.4,-.2, voronoi(160.*p0)); // skin pores
         d += .002*wnoise(42.*p0,2.);
    }
    r = min2(r, vec2(d,4));
    r = min2(r, vec2(length(pe - pEye-vec3(-.15,-.2,.05))-.4,2));
    return r;
}


vec2 sdFrog(vec3 p0) {

    float mf = 0.,
         sgn = sign(p0.z),
         dr = length(p0-vec3(-.5,1.3,0))-3.5;
    
    if (sh==0 && dr > 0.) return vec2(dr+.01,0);
    
    vec3 p = p0;
    p.z = sqrt(p.z*p.z+.01);// sabs(p.z,.01);
    
    vec3 pr = p;
    pr.xy *= rot(-.3);

    float d = sdEllipsoid(pr-vec3(-.5,1.2,0), vec3(2.8,1.2,2)); // main part of the body
    float fb = 2.*fbm(3.*p);

    d += .03*fb;
    
    mf = .9*smoothstep(.0,.3, d);
        
    // mouth hole
    pr.y -= .05*cos(3.6*pr.z);
   
    float dd = sdBox(pr-vec3(-3.,.85,0), vec3(.45,max(.0,.05*cos(1.6*pr.z)),2.4));
      
    d = smm(d,dd,-.1); // mouth

    // modeling
    dd = max(dot(pr-vec3(3.,1.3,0), normalize(vec3(1,2,1))), 
                  max(dot(pr-vec3(-3.4,1.8,-.1), normalize(vec3(-1.9,1,2))),
                      min(.65-pr.y, dot(pr-vec3(-.5,.3,2.), normalize(vec3(-1.5,-2.2,1))))));
    
    float dEye = length(p-vec3(-1.6,2.3,1.)) - .65;
     
    d = smm(d, -dd, -.15);
    d = smm(d, dEye, .2);
       
    // hole noze
    d = smm(d, length(p - vec3(-2.6,2.2,.3))-.05, -.08);

     // eyelids
    d = smm(d, length(p-vec3(-1.9,2.4,1.2))-.5,-.3);
  
    // remove regularity
    pr += .05*fb;
  
    // bump under mouth
    d = smm(d, sdEllipsoid(pr-vec3(-1.5,.65-.06,0), mix(vec3(.95,.15,.9), vec3(1.2), .3)), .25);
    
    // legs
    p += vec3(0,.9,0);
    vec2 le = sdBumpCapsule(p,vec3(2.1,1.4,.5),vec3(-.2,1.7, 2.9),.2,.3);
    float dLeg = smm(le.x,
                     smm(sdBumpCapsule(p,vec3(-.2,1.6,3.),vec3(2,.5,1.18),.15,.2).x,
                           sdCapsule(p,vec3(2,.5,1.2),vec3(1.2,.3,1.6)).x-.2,.05),.05);
                          
    float dFeet =  min(sdCapsule(p,vec3(1.1,.25,1.55),vec3(.2,.6,1.5)).x,
                       min(sdCapsule(p,vec3(1.2,.25,1.6),vec3(0,.5,2.)).x,
    					   sdCapsule(p,vec3(1.1,.25,1.75),vec3(.3,.3,2.3)).x))-.08;
                           
    float dFinger = min(min(length(p-vec3(.3,.6,1.5)),
                        length(p-vec3(.1,.5,2))),
                        length(p-vec3(.4,.3-.1,2.3))) - .12;
  
    p -= vec3(0,.9,0);
    
    dFeet = smm(dFinger, dFeet,.2);
    dLeg = smm(dLeg, dFeet, .1);
    d = smm(d, dLeg, mix(-.03,-.49,smoothstep(.3,.6,le.y)));
    d = smm(d, dLeg + .02*fb, .1);
    
    p += vec3(-.1,.7,.1);
    
    vec3 pFinger = p;
    float g = -.2, gy = -.2;
  
    // arms
    le = sdBumpCapsule(p,vec3(-1.,1.8,1.6),vec3(-.3-.3,.9, 2.35),.2,.1);
    float dLeg2 = smm(le.x, sdBumpCapsule(p,vec3(-.3-.3,.9,2.4),vec3(-1.,.3-.2,2.-.2),.2,.1).x,.1);
    
    float dFeet2 =  smm(sdCapsule(pFinger,vec3(-1.,0,1.8),vec3(-1.6,-.45,1.8)).x,
                       smm(sdCapsule(pFinger,vec3(-1.,0,1.8),vec3(-1.6,-.1,1.1)).x,
    				       smm(sdCapsule(pFinger,vec3(-1.,0,1.8),vec3(-1.3,.3,.9)).x,
                               sdCapsule(pFinger,vec3(-1.,0,1.8),vec3(-.85,.3,1)).x
                              ,.2),.2),.2)-.08;
                              
    float dFinger2 = smm(smm(length(pFinger-vec3(-1.6,-.45,1.8)),
                             length(pFinger-vec3(-1.6,-.1,1.1)),.2),
                         smm(length(pFinger-vec3(-1.3,.3,.9)),
                             length(pFinger-vec3(-.85,.3,1)),.2),.2) - .1;
    p -= vec3(-.1,.7,.1);
    
    dFeet2 = smm(dFinger2, dFeet2,.2); 
    dLeg2 = smm(dLeg2, dFeet2,.2);
  
    d = smm(d, dLeg2+.015*fb,  mix(.25,.0,smoothstep(.2,.6, le.y)));

    // bumps on skin   
    if (ii==0)
        d += .003*smoothstep(.0,.6,voronoi(18.*p0));  

    vec2 r = vec2(d,1.+mf);
    r = min2(r,vec2(dEye+.16, 2));
    
    // tongue
    r = min2(r,vec2(sdEllipsoid(pr-vec3(-.85,.9,0), vec3(2.2,.3,.7)), 3));
    return r;
}


vec2 sdFirefly(vec3 p) {
    float h = hashid(float(iFrame)),
          s = 2.,
          dl; 

    p *= s;
    p.xz *= rot(3.4);
    p.yx *= rot(.5+.02*h);
    p.z = abs(p.z);
    
    p.x += .03*cos(20.*p.y); 
    
    vec2 lu = sdCapsule(p,vec3(0,-.2,0),vec3(0));
    
    vec3 pr = p - vec3(0,-.06,.01);
    pr.xz *= rot(-.25);
    pr.y += .02*cos(20.*pr.x)+5e-4*cos(1e3*pr.z); 
   
    dl = sdCapsule(pr,vec3(.15,0,0),vec3(-.15,0,0)).x-.02;
    dl = max(abs(dl)-.001, .002-pr.y);
    dl = max(dl, p.x+.02);
    dl = min(dl,lu.x-.03+.01*step(.66,lu.y)+.005*abs(cos(25.*lu.y)));
    
    dhaloLight = min(dhaloLight, lu.y<.45?dl:99.); // huggly cut distance field but best like this !
   
    vec2 r = vec2(dl/s,6.+.99*lu.y);
  
    dl = length(p-vec3(.012,.018,.016))-.016; // eyes
    
    // antennas
    dl = min(dl, sdCapsule(p,vec3(0),vec3(0,.15,.1)).x-.002);
    // mandibles
    dl = min(dl, sdCapsule(p,vec3(.005,.01,0),vec3(.04,.02,.01)).x-.003);
    // legs
    pr = p+vec3(-.015,.07,0);
    float dd = .01*(.5+.5*cos(10.*round(pr.y/.015)));
    pr.y = opRep(pr.y, .015, 2.);
    dl = min(dl, sdCapsule(pr,vec3(0),vec3(.01+dd,0,.05)).x-.003);
    dl = min(dl, sdCapsule(pr,vec3(.01+dd,0,.05),vec3(.02+2.*dd,0,.01+dd)).x-.003);

    r = min2(r, vec2(dl/s,7)); 
    p -= vec3(-.02,-.08,0);
   
    vec3 ail = vec3(-.1,0,.2); // wings moving
   
    ail.xy *= rot(.3+cos(2.*h-1.));
    ail.yz *= rot(1.6*h-1.2);
   
    dl = sdCapsule(p,vec3(0),ail).x-.02;
    
    r = min2(r, vec2(dl/s,8)); 
    return r;
}


vec2 map(vec3 p) {
        vec2 r = vec2(p.y+.7,5); // water
    if (p.x<3.7) {
        r = min2(r, sdFirefly(p-vec3(-.6,.58,.03)));
        r = min2(r, sdFrog((p-vec3(.45,0,-.2))/.15)*vec2(.15,1)); 
        r = min2(r, sdCroco(p-vec3(.05,-.12,-.5))); 
    }
    return r;
}


//------------------------------------------------------------------------
// Normal and Curvature (adapted from Shane shader)
//------------------------------------------------------------------------
/*
// iapafoto version (46s to compile)
vec3 calcNormal(vec3 p, inout float crv) { 
    vec2 ec = vec2(.03, 0);
    float d = map(p).x,   
	      d1 = map(p + ec.xyy).x, d2 = map(p - ec.xyy).x,
          d3 = map(p + ec.yxy).x, d4 = map(p - ec.yxy).x,
          d5 = map(p + ec.yyx).x, d6 = map(p - ec.yyx).x;
    crv = (d1 + d2 + d3 + d4 + d5 + d6 - d*3.)/(ec.x)
    vec3 e, n = vec3(0);
    for(int i=ZERO; i<4; i++) {
        e = .57735*(2.*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1)) - 1.);
        n += e*map(p + 1e-4*e).x;
    }
    return normalize(n);
}
*//*
// pyBlob version (7s) (-17ch)
vec3 calcNormal(vec3 p, inout float crv) { 
    vec2 c = vec2(.03, 0), x = .57735 * vec2(1,-1);
    vec3 e, n = vec3(0);
    crv = 0.;
    for (int i=ZERO ; i<7+4 ; i++)
    {
        e = vec3[](x.xyy,x.yyx,x.yxy,x.xxx)[i-7];
        float d = map(p + vec3[](vec3(0), c.xyy, -c.xyy, c.yxy, -c.yxy, c.yyx, -c.yyx, 1e-4*e, 1e-4*e, 1e-4*e, 1e-4*e)[i]).x;
        if (i < 7)
            crv += d * (i == 0 ? -3. : i < 7 ? 1. : 0.);
        else
            n += e * d;
    }
    crv /= ec.x;
    return normalize(n);
}
*/

// iq version (10s) (-96ch)
vec3 calcNormal(vec3 p, inout float crv)
{ 
    vec3 e, n = vec3(0);
    // Curvature
    crv = 0.;
    for(int i=ZERO; i<6; i++) {
        e = n;
        e[i>>1] = (i&1)==0?1.:-1.;
        crv += map(p+.03*e).x/.03;
    }
    // Normal
    for(int i=ZERO; i<4; i++) {
        e = .57735*(2.*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1)) - 1.);
        n += e*map(p + 1e-4*e).x;
    }
    return normalize(n);
}

// --------------------------------------
// Ray marching (iq)
// --------------------------------------

vec2 trace(vec3 ro, vec3 rd){
    float t = 0.;
    vec2 d;
    for(int i = ZERO; i<250; i++){
        d = map(ro + rd*t);
        if(abs(d.x)<1e-6 || t > 25.) break;
        t += d.x;
    }
    return min2(vec2(25,0),vec2(t,d.y));
}

float calcAO(vec3 p, vec3 n) {
	float hr, sca = 4., occ = 0.;
    for(float i=float(ZERO+1); i<6.; i++ ) {
        hr = .036*i;       
        occ += (hr - map(p + hr*n).x)*sca;
        sca *= .75;
    }
    return clamp(1.-occ, 0., 1.);   
}

float softShadow(vec3 ro, vec3 rd ) {
    float res=1., t=.001, h=t;
    for(int i=ZERO; i<28 && h>1e-5; i++) {
        h = map(ro + rd*t).x;
        res = min(res, 8.*h/t );
		t += clamp( h, 1e-4, .03);
    }
    return min(max(res,0.)+.1,1.);
}

// --------------------------------------
// Environement Sky colors (based on Shane one)
// --------------------------------------
vec3 envMap(vec3 rd){
    vec3 sunDir = normalize(vec3(-5.2, 3.5, -3.9));
	float sun = max(dot(rd, sunDir), 0.), // Sun strength.
	 horiz = pow(1.-max(rd.y, 0.), 3.)*.35; // Horizon strength.
	// The blueish sky color. Tinging the sky redish around the sun. 		
	vec3 sc, col = mix(vec3(.25, .35, .5), vec3(.4, .375, .35), sun/**.75*/);//.zyx;
    // Mixing in the sun color near the horizon.
	col = mix(col, vec3(1, .9, .7), horiz);
    // Add a touch of speckle, to match up with the slightly speckly ground.
    col = clamp(col + hashid(rd.x+123.4*rd.y+.32*rd.z)*.05 - .025, 0., 1.);
	// Clouds. Render some 3D clouds far off in the distance.
	sc = rd; 
    sc.y *= 3.;
    // Mix the sky with the clouds, whilst fading out a little toward the horizon (The rd.y bit).
	return pow(mix(col, vec3(1,.95,1), smoothstep(.5, 1., fbm/*wnoise*/(7.*sc))*clamp(rd.y*8., 0., 1.) ), vec3(4.));
}


// --------------------------------------
// One light contribution
// --------------------------------------

vec3 doLighting(int m, vec3 sp, vec3 rd, vec3 sn, vec3 li, vec3 lightCol, vec3 objCol){
    vec3 diff = lightCol * max(dot(sn, li), 0.);
    vec3 spec = lightCol * pow(max(dot(reflect(-li, sn), -rd), 0.), 32.) * (m==2?4.:1.);
    return (objCol * diff + spec) * softShadow(sp + sn*.001, li);
}




// --------------------------------------
// Parametrizable camera
// --------------------------------------
void camera(inout vec3 ro, // in: from => out: ro
        inout vec3 rd, // in: to => out: rd 
        float focusDistance, 
        float focalLen, 
        float aperture, 
        vec2 uv) 
{
    mat3 camMat = basisMatrix(rd - ro);
    rd = ro + camMat[2]*focusDistance;
    ro += camMat * vec3(randCircle() * aperture, 0); // Circular bokeh
                     // randHexa()                   // Hexa bokeh
    rd = normalize(basisMatrix(rd - ro) * vec3(uv, focalLen));
}

// --------------------------------------
// Main fonction (3 light bounces)
// --------------------------------------
void mainImage(out vec4 fragColor, vec2 fragCoord) {
    vec2 t,w = fragCoord.xy;
   
	seed = float(((iFrame*73856093)^int(w.x)*19349663^int(w.y)*83492791)%38069);
      
    float refContrib = 1.; // stack light reflexions
    
    vec2 uv = (2.*(w + hash2()-.5)-iResolution.xy)/iResolution.y;
   
    // camera	
    vec3 rd = vec3(.24,.04,.4),
         ro = vec3(-1.75,.74,-3);
    
    camera(ro,rd, .72*4.7, 4.8,.1, uv);

    // ray direction
   vec3  pos, nor, 
         ctot = vec3(0);

    // light bounces
    for(int i=ZERO; i<BOUNCE; i++) {
        dhaloLight = 999.;

        ii = i;
        sh=0;
        t = trace(ro, rd);
        sh=1;

        float dl = dhaloLight;
        
        // Background
        vec3 skyCol, sceneCol = skyCol = envMap(rd);

        int m = int(t.y);
        float mf = fract(t.y);
         
        if (m > 0){
            pos = ro + rd*t.x;

            float crv = 1.;
            nor = calcNormal(pos, crv);

            // 1 Frog
            // 2 Eye
            // 3 Tongue
            // 4 Crocodile
            // 5 Water
            // 6 Firefly

            // Crocodile's lower eyelid
            if (m==2 && pos.x >1. && pos.y<.05) m = 4;
            
            vec3 col = m == 1 ? vec3(.21,.33,.14) : 
                       m == 3 ? vec3(1.1,.5,.5) : 
                       m == 4 ? vec3(.4,.35,.25) :
                       m == 5 ? vec3(.05,.15,.1) :
                       vec3(m == 7 ? 0 : 1);    // wings           
           
           if (m == 6) { // firefly
                col = vec3(1.2,.4,0) * smoothstep(.65,1.,mf);
           }
                
           if (m == 2) { // eyes
               if (pos.x > 1.) { // croco
                  vec3 pe = pos-vec3(.05,-.17,-.5);
                  pe.xz *= rot(.7);
                  pe.z = abs(pe.z);
                  pe -= vec3(3.5,.35,.655) + vec3(-.5,-.05,-.09);
                  pe.z = abs(pe.z);                 
                  col = vec3(9,3.6,0)*smoothstep(.35,.36,length(pe+vec3(-.1,0,.3)));
           
               } else { // frog
                   vec3 p = (pos-vec3(.45,0,-.2))/.15;
                   p.z = abs(p.z);
                   p -= vec3(-1.6,2.3,1.);

                   float d = length((p-vec3(-.6,.3,.0))*vec3(.8,1.2,.8)); 
                   d += .1*wnoise(10.*pos,7.);
                   col = mix(vec3(.5,.15,.005), vec3(1,.5,0), smoothstep(.5,.6,wnoise(80.*pos,2.)));
                   col = mix(vec3(1.5,1,0), col, smoothstep(.2,.3,abs(d)-.1));
                   col *= 1.5*smoothstep(.3,.32,d);
               }
           }
           
           if (m == 1 || m == 4) {
                // color variation on frog and croco skins
                col = mix(col, vec3(3,3,.3),.25*crv); 
                col = mix(col, vec3(2,1.2,.4), (1.-mf)*smoothstep(.0,-.05, pos.y-.65+.35*pos.x +.37));
                col = mix(col, vec3(1,.4,.01), mf*smoothstep(.05,-.05, pos.y));
            }
            
            if (m == 4) { // croco body
                float k = smoothstep(-.11,-.3,pos.y);
                col = mix(col, vec3(6,5,3), smoothstep(-.2,-.4,pos.y));
                // black dots
                col = mix(col*.3, vec3(.02,.05,.01), (1.-.3*k)*smoothstep(.8-.35*k,.3-.25*k, voronoi(50.*pos)));
                // nazeaux
                vec3 pe = pos-vec3(.05,-.12,-.5);
                pe.xz *= rot(.7);
                pe.z = abs(pe.z);
                col = mix(col, vec3(1.1,.5,.5), smoothstep(.25,.22,length(pe-vec3(.435,-.16,.1))));
            }

            vec3 nlu = vec3(-.6,.5,.03)-pos;
            vec3 c = col * vec3(.15,.18,.3);  // ambiant

            c += doLighting(m, pos, rd, nor, vec3(.69, .72, .1), vec3(.2,.26,.66), col);
            c += doLighting(m, pos, rd, nor, normalize(nlu), smoothstep(1.3,.8,length(nlu))*vec3(1,.52,.01), col);
            sceneCol =  c * calcAO(pos, nor);

            if (i == 0) { // very thin rim effect (yellow light arround the frog to unify with firefly)
                sceneCol += vec3(1,.8,.4)*pow(1. - max(0.,dot(nor, -rd)), 16.);
            }  
        }
        
        // fog to hide crocodile
        sceneCol = mix(sceneCol, skyCol, smoothstep(2., 8., t.x));
   
        // halo on firefly
        if (dl < t.x-.1) {
 		    sceneCol += vec3(1,.52,.01)/(1.+dl*dl*2e3);
        }
        
        ctot = mix(ctot, clamp(sceneCol,0.,1.), refContrib);

            // 1 Frog
            // 2 Eye
            // 3 Tongue
            // 4 Crocodile
            // 5 Water
            // 6 Firefly
        // coeff of relexion and blur for each materials    
            //                 76543210
        refContrib *= float((0x00731110>>(4*m))&0xF)*.1;
           //                                  76543210
        rd = gaussianReflect(rd, nor, float((0x10169550>>(4*m))&0xF)*.2);
        
        if(t.x>24.||refContrib <= 0.|| dot(rd,nor)<0.) break;           
        ro = pos + rd*1e-4;        
    }

    vec4 col4 = vec4(ctot,1); 
    // To stack picture on BufferB
    if (iFrame > 0 && iMouse.z <= 0.) {
       vec4 lastCol = texelFetch(iChannel3, ivec2(fragCoord.xy), 0);
       col4 = mix(lastCol, col4, .005);
    }
    
    fragColor = col4; 
}
