// Image (image) — Decorated Christmas Spiral by sylvain69780
// https://www.shadertoy.com/view/3dVfDc

/*
    Decorated Christmas Spiral
    --------------------------

    Happy Christmas to you all the great Shadertoy community !
    
    It seems that the archimedian spiral can be used as a distance field with coordinates
    a quite neat way to create a repetition domain where you can put blinking balls and ribbons.

    Spirals are commonly use in art, and we may find this figure frequently in the nature.
    Of course there is several kinds of spirals. For example, the Logarithmic Spiral that IQ  
    used in his awesome Snail shader and the ones built using arc of circles (multiple center spirals).
    
    Related references:    

    Nyarchimedes Spiral - kibble
    https://www.shadertoy.com/view/lsS3WV
    
    Quick Lighting Tech - blackle 
    https://www.shadertoy.com/view/ttGfz1
    
    soft shadows in raymarched SDFs - IQ
    https://iquilezles.org/articles/rmshadows
    
    outdoors lighting- IQ
    https://iquilezles.org/articles/outdoorslighting
    
    Cubic Truchet Pattern - Shane
    https://www.shadertoy.com/view/4lfcRl
    
*/

// #define AA

#define MAX_STEPS 256
#define MAX_DIST 10.
#define SURF_DIST .001
#define TAU 6.283185

#define S smoothstep
#define T (iTime)
#define PI 3.14159265

mat2 rot(in float a) { float c = cos(a); float s = sin(a); return mat2(c, s, -s, c); }


float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,233.53));
    p += dot(p, p+23.234);
    return fract(p.x*p.y);
}

float sdVerticalCapsule( vec3 p, float r, float h )
{
  p.x -= clamp( p.x, 0.0, h );
  return length( p ) - r;
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdHexagram( in vec2 p, in float r )
{
    const vec4 k = vec4(-0.5,0.86602540378,0.57735026919,1.73205080757);
    p = abs(p);
    p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
    p -= 2.0*min(dot(k.yx,p),0.0)*k.yx;
    p -= vec2(clamp(p.x,r*k.z,r*k.w),r);
    return length(p)*sign(p.y);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float braids(vec3 p,float l,out float id) {
    p.yz*=rot(p.x*3.14159*.5);
    p.yz = abs(p.yz)-0.25; // 4 for the price of one
    p.yz = (p.yz + vec2(p.z, -p.y))*sqrt(0.5); // Shortcut for 45-degrees rotation https://www.shadertoy.com/view/WsGyWR
    vec2 sector=step(0.0,p.yz);
    id = sector.x + 2.0 * sector.y; 
    p.yz = abs(p.yz)-0.05;
    p.yz*=rot(p.x*3.14159*4.0);
    p.yz = abs(p.yz)-0.02;
    float d = sdVerticalCapsule(p,0.02,l);
    return(d);
}

float carvings(vec3 p,float l, out float id) {
    p.x-=.03;
    float n = round(l);
    id = clamp(round(p.x*2.0),1.0,n*2.0-1.0);
    p.x-=id*.5;
    p.zy*=rot(id*3.1415*.25); 
    return min(sdHexagram(p.xy,0.045),(sdBox(abs(p.xz)-0.033,vec2(0.022)+.006)));
}

float balls(vec3 p,float l, out float id) {
    float rank = round(p.x);
    p.yz*=rot((rank+0.25)*3.14159*.5);
    p.x -= clamp(rank,0.0,l);
    vec2 sector=step(0.0,p.yz);
    id = sector.x + 2.0 * sector.y; 
    float r = .05*(1.0+id*.2);
    p.yz = abs(p.yz);
    p.yz -= vec2(.25,.25);
    id += 4.0*rank;
    return length(p)-r;
}

float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

float decoratedStick(vec3 p,out float m,out float glowDist) {
    float l = 40.0;   // lenght of the stick
    float d = 1e10; // distance
    // materials : 1.0=spiral 2.x=tubes 3.x=stars and squares 4.0=inside spiral 5.0 Balls
    m = 1.0;    // materials
    glowDist = 1e10;
    float core = length(vec3(p.x-clamp(p.x,0.0,l),p.y,p.z));
    float outer = core-.25;
    float inner = core-.22;
    // Stars and Littles windows carvings, change sign to have holes or bumps
    float id;
    float carvings = -carvings(p,l,id);
    d = smax(outer,carvings,.025);
    if ( inner    < d ) { d = inner    ; m = 4.0+id/1024.0 ; }
    // Braids 
    float braids = braids(p,l,id);
    if ( braids < d ) { d=braids ; m= 2.0 + id/1024.0 ; }; // packing the ID in the material
    // Balls :-)
    float balls = balls(p,l,id);
    if ( balls < d ) { d=balls ; m= 5.0 + id/1024.0 ; }; // packing the ID in the material
    // Some blinking
    float blink=1.0-cos(5.0*id+2.0*T);
    glowDist = balls+blink*.1; 
    return d; 
}

// approximated !
float arclength(float turn) {
	float d = turn * turn;
	return d * PI;
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

// arc length of archimedes spiral
float spiralLength(float b, float a) {
  // https://en.wikipedia.org/wiki/Archimedean_spiral
  return 0.5*b*(a*sqrt(1.0+a*a)+log(a+sqrt(1.0+a*a)));
}

// SDF for Archimedean Spiral
// https://www.shadertoy.com/view/stB3WK
float spiralUV2(vec2 p,float b, float a1r,float a2r, float strip, out vec2 uv) {
    float atn = atan(p.y, p.x)/TAU; // sector from -.5 to .5
    float a1n = a1r/TAU, a2n = a2r/TAU; // predivide allows to use fract for modulo TAU computations
    float w = b*TAU;
    float r = length(p)/w;
	float grad = r - atn; // radial distance gradien used for domain repetition using "round"
    float d = 1e9;
    if (a2n-a1n >= fract(atn-a1n)) // opened sector case test
    {
        uv.y = w*(grad-round(clamp(r,a1n+.5,a2n-.5)-atn));
        d=abs(uv.y)-.5*strip;
    }
    // inner end
    vec2 q = p*rot(a1r);
    q.x -= a1n*w;
    q.x -= clamp(q.x,-strip*.5,strip*.5);
    float db = length(q);
    // outer end
    q = p*rot(a2r);
    q.x -= a2n*w;
    q.x -= clamp(q.x,-strip*.5,strip*.5);
    db = min(db,length(q));
    // interior / exterieur distance to ends
    d = d > 0.0 ? min(d,db) : max(d,-db);        
    // UV calculations
    float turn = round(grad); 
    float an = TAU*(turn + atn); 
    uv.x = spiralLength(b,an)-spiralLength(b,a1r);
	return d;
}

float GetDist(vec3 p,out float objID, out float glowDist, out float dC ) {
    p.xz *= rot(T*.1);
    p.xy *= rot(-sin(T*.1)*.5);
    glowDist = 1e10;
    objID = 1.0;
    float tmin = 0.0, tmax = 2.0;
    vec2 uv;
    float d = 1e10;
    dC = abs(p.y)-0.5;
    if ( dC < SURF_DIST ) {
        float dSpiral = spiralUV2(p.xz,1.0/TAU,(tmin+1.0)*TAU,(tmax+2.0)*TAU,1.0,uv);
        dC = abs(dSpiral);
        if ( dSpiral < SURF_DIST-.02 ) {
            vec3 q = vec3(uv.x, p.y, uv.y ); // spiral UV space
            d = decoratedStick(q-vec3(.5,0.,0.),objID,glowDist);
        } 
    }
    return d;
}

float GetDist(vec3 p,out float glowDist,out float dC) {
    float objID;
    return GetDist(p,objID,glowDist,dC);
}

float GetDist(vec3 p) {
    float glowDist,objID,dC;
    return GetDist(p,objID,glowDist,dC);
}

float GetMat(vec3 p) {
    float glowDist,objID,dC;
    float d = GetDist(p,objID,glowDist,dC);
    return objID;
}

float RayMarch(vec3 ro, vec3 rd,out float glowCumul) {
	float dO=0.0;  
    float dS;
    float dC; // distance to cell boundaries
    float glowDist;
    glowCumul=0.0;
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        dS = GetDist(p,glowDist,dC);
        dO += min(dS*.9,dC+0.05); 
        float at = 1.0 / (1. + pow(glowDist*20.,3.0) );
        glowCumul+=at;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }    
    return dO;
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<24; i++ )
    {
		float h = GetDist( ro + rd*t );
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.2 );
        if( res<0.004 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float calcOcclusion( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = GetDist( opos );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    vec3 col = vec3(0);    
    vec3 tcol = vec3(0);
    vec3 target = vec3(0,-0.7,0);
    vec3 ro = vec3(0, 0.7, 3.3);
    vec2 m = iMouse.xy / iResolution.xy-.5;
    float time=mod(T+10.0,20.0);
    float atime=1.0;
    if ( iMouse.x > 0.0 ) {
        target = vec3(0,-0.8,0.0);
        ro = vec3(0, 0.5, 2.0)*2.4;
        ro.yz *= rot(m.y*3.14*.5);
        ro.xz *= rot(-m.x*6.2831*2.0);
    } else  
        ro.y+=S(0.0,10.0,time)-S(10.0,20.0,time);
     
#ifdef AA
	for (float dx = 0.; dx <= 1.; dx++)
		for (float dy = 0.; dy <= 1.; dy++) {
			vec2 uv = (fragCoord + vec2(dx, dy) * .5 - .5 * iResolution.xy) / iResolution.y;
#else
			vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
#endif
    
    vec3 rd = GetRayDir(uv, ro, target, 1.);
    vec3 bgcol = vec3(0.10,0.28,0.10)*(1.-abs(rd.y)); // fast gradient - "the sky will be blue" - https://youtu.be/Cfe5UQ-1L9Q?t=2795
    float glowCumul;
    float d = RayMarch(ro, rd,glowCumul);
    if(d<MAX_DIST) {
    	vec3 pos = ro + rd * d;
        float m = GetMat(pos);
    	vec3 nor = GetNormal(pos);
        vec3 ref = reflect(rd, nor); 
        vec3 c=vec3(0);
        float ks = 1.0; 
        float occ = calcOcclusion( pos, nor );
        vec3  sun_lig = normalize( vec3(0.6, 0.35, 0.5) );
        float sun_dif = clamp(dot( nor, sun_lig ), 0.0, 1.0 );
        vec3  sun_hal = normalize( sun_lig-rd );
        float sun_sha = calcSoftshadow( pos+0.01*nor, sun_lig, 0.01, 0.25 );
        float sun_spe = ks*pow(clamp(dot(nor,sun_hal),0.0,1.0),8.0)*sun_dif*(0.04+0.96*pow(clamp(1.0+dot(sun_hal,rd),0.0,1.0),5.0));
		float sky_dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float bou_dif = sqrt(clamp( 0.1-0.9*nor.y, 0.0, 1.0 ))*clamp(1.0-0.1*pos.y,0.0,1.0);
		vec3 lin = vec3(0.0);
        // materials  
        if ( m >=5.0 ) {            // Balls
            float ballID = fract(m)*1024.0;
            c = fract(ballID*.5) > 0.0 ? vec3(1.0,0.1,0.01) : vec3(0.6,0.6,0.2)*.5;
            float directionality=0.75;
            float sharpness=0.5;
            float spec = length(sin(ref * 3.) * directionality + (1. - directionality)) / sqrt(3.);
            spec = spec + pow(spec, 10. * sharpness);
            float blink=1.0+cos(5.0*ballID+2.0*T);
            lin = vec3(blink)*3.3;
            c = spec * c;  
        } else if ( m >=4.0 ) {     // bright inside spiral
            float starID=fract(m)*1024.0;
            float blink=1.0+cos(5.0*starID+3.15*T);
            c = vec3(0.7,0.7,0.1)*.3;
            lin = vec3(blink)*3.0;
            float directionality=0.75;
            float sharpness=0.5;
            float spec = length(sin(ref * 3.) * directionality + (1. - directionality)) / sqrt(3.);
            spec = spec + pow(spec, 10. * sharpness);
            c = spec * c;  
        } else if ( m >=3.0 ) {    
            // Material Not used c = vec3(0.3,0.1,0.01);
        } else if ( m >=2.0 ) {     // tubes 
            float ropeID=fract(m)*1024.0;
            c = ropeID>2.0 ? vec3(0.5,0.5,0.01)*.25 : vec3(0.01,0.6,0.01)*.1;
        } else if ( m >=1.0 ) {     
            // spiral core
            // https://www.shadertoy.com/view/tlscDB
            c = vec3(0.28,0.2,0.02);
            float directionality=0.75;
            float sharpness=0.7;
            float spec = length(sin(ref * 4.) * directionality + (1. - directionality)) / sqrt(3.);
            spec = spec + pow(spec, 10. * sharpness);
            c =  spec * c * (.3+.7*sun_sha);  
        }
        lin += sun_dif*vec3(8.10,6.00,4.20)*sun_sha*.5;
        lin += sky_dif*vec3(0.50,0.70,1.00)*occ*2.0;
        lin += bou_dif*vec3(0.40,1.00,0.40)*occ*2.0;
		col = c*lin;
		col += sun_spe*vec3(8.10,6.00,4.20)*sun_sha;
        // fog
        float fog=S(12.0,5.0,d);
        col = mix(bgcol, col, fog);
        
    } else {
        col = bgcol;
    }
    col += vec3(0.1,0.1,0.01)*glowCumul;
    col = sqrt(col);	// gamma correction    
    tcol+=col;
#ifdef AA
		}
	tcol /= 4.;
#endif
    
    fragColor = vec4(tcol,1.0);
}
