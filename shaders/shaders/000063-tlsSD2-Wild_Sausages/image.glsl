// Image (image) — Wild Sausages by iapafoto
// https://www.shadertoy.com/view/tlsSD2

//-----------------------------------------------------
// Created by sebastien durand - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------
//
// Simulate sausages.
//
//-----------------------------------------------------
// [dr2]            More Balls               - https://www.shadertoy.com/view/MsfyRn
// [iq]             Capsule - soft shadow    - https://www.shadertoy.com/view/MlGczG
// [iq]             Balls and shadows        - https://www.shadertoy.com/view/lsSSWV
// [Shane]          Desert Canyon            - https://www.shadertoy.com/view/Xs33Df
//-----------------------------------------------------

    
//#define WITH_SHADOWS // only for sphere mode for the moment 
#define WITH_AO

#define SAUSAGES // else display element spheres


// -----------------------------------------------------------

const vec3 light = normalize( vec3(-.4, .3, -1.5) );
const float dstFar = 999.;

vec3 vnBall;
int idBall;


// +-------------------------------------+
// |         Geometric tools             |
// +-------------------------------------+

// Distance to point
float dista(vec3 ro, vec3 rd, vec3 p) {
	return length(cross(p-ro,rd));
}

bool cube(vec3 ro, vec3 rd, vec3 sz) {
	vec3 m = 1./rd, k = abs(m)*sz,
         a = -m*ro-k*.5, b = a+k;
    float tn = max(max(a.x,a.y),a.z);
	return tn>0. && tn<min(min(b.x,b.y),b.z);
}


#ifdef SAUSAGES

//-------------------------------------------------------------------------------------------
// Capsules related functions
//-------------------------------------------------------------------------------------------
// [iq] Capsule - soft shadow - https://www.shadertoy.com/view/MlGczG
//-------------------------------------------------------------------------------------------

float capShadow( in vec3 ro, in vec3 rd, in vec3 a, in vec3 b, in float r, in float k ) {
    vec3 ba =  b - a, oa = ro - a;
    // closest distance between ray and segment
	float oad  = dot( oa, rd ), dba  = dot( rd, ba ),
		  baba = dot( ba, ba ), oaba = dot( oa, ba );
	vec2 th = vec2( -oad*baba + dba*oaba, oaba - oad*dba ) / (baba - dba*dba);
	th.x = max(   th.x, .0001 );
	th.y = clamp( th.y, .0, 1. );
	vec3  p =  a + ba*th.y, q = ro + rd*th.x;
    float d = length( p-q )-r;
    // fake shadow
    float s = clamp( k*d/th.x, 0., 1. );
    return s*s*(3.-2.*s);
}

// intersect capsule
float capIntersect( in vec3 ro, in vec3 rd, in vec3 pa, in vec3 pb, in float r ) {
    vec3  ba = pb - pa, oa = ro - pa;
    float baba = dot(ba,ba), bard = dot(ba,rd),
    	  baoa = dot(ba,oa), rdoa = dot(rd,oa), oaoa = dot(oa,oa);
    float a = baba - bard*bard,
          b = baba*rdoa - baoa*bard,
          c = baba*oaoa - baoa*baoa - r*r*baba,
          h = b*b - a*c;
    if( h>=0.) {
        float t = (-b-sqrt(h))/a,
              y = baoa + t*bard;
        // body
        if (y>0. && y<baba) return t;
        // caps
        vec3 oc = y<=0. ? oa : ro - pb;
        b = dot(rd,oc);
        h = b*b - dot(oc,oc) + r*r;
        if (h>0.) return -b - sqrt(h);
    }
    return -1.;
}

// compute normal
vec3 capNormal( in vec3 pos, in vec3 a, in vec3 b, in float r ) {
    vec3  ba = b - a, pa = pos - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba),0.,1.);
    return (pa - h*ba)/r;
}

// fake occlusion
float capOcclusion( in vec3 p, in vec3 n, in vec3 a, in vec3 b, in float r ) {
    vec3 ba = b - a, pa = p - a,
         d = pa - ba * clamp(dot(pa,ba)/dot(ba,ba),0.,1.);
    float l = length(d), o = 1. - max(0.,dot(-d,n))*r*r/(l*l*l);
    return sqrt(o*o*o);
}

float shadow( in vec3 ro, in vec3 rd ) {
	float res = .0;
    for (int n = 0; n<NB_ELT; n+=CHAIN) {
        vec4 p = Load(iChannel0, POSITION, n+(CHAIN/2));
        if (length(ro-p.xyz)<2.+p.w*float(CHAIN)) {
            vec4 pmem =Load(iChannel0, POSITION, n);
            for (int i =1; i<CHAIN; i++) {
                p = Load(iChannel0, POSITION, n+i);
                // if (length(ro-p.xyz)<2.) { 
                res = max( res, capShadow(ro,rd, p.xyz, pmem.xyz, p.w, 1.5) );
                // }
                pmem = p;
            }
        }         
        
    }
    return 1.;//-res;					  
}

float occlusion( in vec3 pos, in vec3 nor ) {
	float res = 1.;
    for (int n = 0; n<NB_ELT; n+=CHAIN) {
        vec4 p = Load(iChannel0, POSITION, n+(CHAIN/2));
        if (length(pos-p.xyz)<p.w*float(CHAIN)+1.) {
            vec4 pmem = Load(iChannel0, POSITION, n);
            for (int i =1; i<CHAIN; i++) {
                p = Load(iChannel0, POSITION, n+i);
                res *= capOcclusion(pos, nor, p.xyz, pmem.xyz, p.w); 
                pmem = p;
            }
        }
    }
    return res;					  
}

float BallHit(vec3 ro, vec3 rd) {
    vec4 p;
    float d, dMin = dstFar;
    for (int n =0; n<NB_ELT; n+=CHAIN) {
        p = Load(iChannel0, POSITION, n+(CHAIN/2));
        if (length(ro-p.xyz)-p.w*float(CHAIN)<dMin && dista(ro,rd,p.xyz)<p.w*float(CHAIN)) {
            vec4 pmem = Load(iChannel0, POSITION, n);
            for (int i =1; i<CHAIN; i++) {
                p = Load(iChannel0, POSITION, n+i);
                d = capIntersect(ro, rd, pmem.xyz, p.xyz, p.w);
                if (d > 0. && d < dMin) {
                    dMin = d;
                    vnBall = capNormal(ro+rd*d,pmem.xyz, p.xyz, p.w);
                    idBall = n;
                }
                pmem = p;
            }
        }
    }
    return dMin;
}


#else  

//-------------------------------------------------------------------------------------------
// Spheres related functions
//-------------------------------------------------------------------------------------------
// [iq] Balls and shadows - https://www.shadertoy.com/view/lsSSWV
//-------------------------------------------------------------------------------------------

float sphShadow(in vec3 ro, in vec3 rd, in vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd ),
          c = dot( oc, oc ) - sph.w*sph.w;
    return step( min( -b, min( c, b*b - c ) ), 0. );
}
            
vec2 sphDistances(in vec3 ro, in vec3 rd, in vec4 sph) {
	vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd ),
     c = dot( oc, oc ) - sph.w*sph.w,
     h = b*b - c,
     d = sqrt( max(0.,sph.w*sph.w-h)) - sph.w;
    return vec2( d, -b-sqrt(max(h,0.)) );
}

float sphSoftShadow(in vec3 ro, in vec3 rd, in vec4 sph) {
    vec2 r = sphDistances( ro, rd, sph );
    return r.y>0. ? max(r.x,0.)/r.y : 1.;
}    
            
float sphOcclusion(in vec3 pos, in vec3 nor, in vec4 sph) {
    vec3  r = sph.xyz - pos;
    float l = length(r), d = dot(nor,r), res = d;
    if (d<sph.w) 
        res = pow(clamp((d+sph.w)/(2.*sph.w),0.,1.),1.5)*sph.w;
    return clamp( res*(sph.w*sph.w)/(l*l*l), 0., 1. );
}

float shadow( in vec3 ro, in vec3 rd ) {
	float res = 1.;
    for (int n = 0; n<NB_ELT; n+=CHAIN) {
        vec4 p = Load(iChannel0, POSITION, n+(CHAIN/2));
        if (length(ro-p.xyz)<2.+p.w*float(CHAIN)/* && dista(ro,rd,p.xyz)<p.w*float((CHAIN))*/) {
            for (int i=0; i<CHAIN; i++) {
                p = Load(iChannel0, POSITION, n+i);
                if (length(ro-p.xyz)<2.) { 
                    res = min( res, 8.0*sphSoftShadow(ro,rd, p) );
                }
            }
        }         
    }
    return res;					  
}

float occlusion( in vec3 pos, in vec3 nor ) {
	float res = 1.;
    for (int n = 0; n<NB_ELT; n+=CHAIN) {
        vec4 p = Load(iChannel0, POSITION, n+(CHAIN/2));
        if (length(pos-p.xyz)<p.w*float(CHAIN)+1.) {
            for (int i=0; i<CHAIN; i++) {
                p = Load(iChannel0, POSITION, n+i);
                res *= 1. - sphOcclusion( pos, nor, p ); 
            }
        }
    }
    return res;					  
}

float BallHit(vec3 ro, vec3 rd) {
    vec4 p;
    vec3 u;
    float b, d, w, dMin = dstFar;
    for (int n = 0; n<NB_ELT; n+=CHAIN) {
        p = Load(iChannel0, POSITION, n+(CHAIN/2));
        if (length(ro-p.xyz)-p.w*float(CHAIN)<dMin && dista(ro,rd,p.xyz)<p.w*float(CHAIN)) {
            for (int i =0; i<CHAIN; i++) {
                p = Load(iChannel0, POSITION, n+i);
                if (length(ro-p.xyz)-p.w<dMin) {
                    u = ro - p.xyz;
                    b = dot (rd, u);
                    w = b * b - dot (u, u) + p.w * p.w;
                    if (w >= 0.) {
                        d = - b - sqrt (w);
                        if (d > 0. && d < dMin) {
                            dMin = d;
                            vnBall = (u + d * rd) / p.w;
                            idBall = n;
                        }
                    }
                }
            }
        }
    }
    return dMin;
}

#endif


// +--------------------------------+
// |          Rendering             |
// +--------------------------------+

//------------------------------------------------------------------------
// [Shane] - Desert Canyon - https://www.shadertoy.com/view/Xs33Df
//------------------------------------------------------------------------
vec3 shade( in vec3 rd, in vec3 pos, in vec3 nor, in float id, in float dis ) {    
#ifdef WITH_AO
    float occ = occlusion( pos, nor );
    occ = pow(occ,2.);
    occ = occ*.5 + .5*occ*occ;
#else
    float occ = 1.f;
#endif

#ifdef WITH_SHADOWS
    float shd = shadow(pos+rd*.01, light );
#else 
    float shd = 1.f;
#endif
    // Sausage Color 
    vec3 col = .5*mix(vec3(1,0,0), vec3(0,1,1), id/float(CHAIN)/7.);    
    vec3 ref = reflect(rd,nor);
    float dif = max( dot( light, nor ), 0.), // Diffuse term.
    	  spe = pow(max( dot( reflect(-light, nor), -rd ), 0.), 29.), // Specular term.
    	  fre = clamp(1. + dot(rd, nor), 0., 1.); // Fresnel reflection term.
    // Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
    // so could almost be aproximated by a constant, but I prefer it. Here, it's being
    // used to give a hard clay consistency... It "kind of" works.
    float Schlick = pow( 1. - max(dot(rd, normalize(rd + light)), 0.), 5.);
    float fre2 = mix(.2, 1., Schlick);  //F0 = .2 - Hard clay... or close enough.
    // Overal global ambience.
    float amb = .6*fre*fre2 + .06*occ;
    
    float h = dot(pos,vec3(127.1,311.7,758.5453123));	
	col *= .6+.4*fract(sin(h)*43758.5453123);
    // Coloring the soil - based on depth. Based on a line from Dave Hoskins's "Skin Peeler."
    return (col*(dif + .1) + fre2*spe*2.)*shd*occ + amb*col;
}    


// Render scene using raytracing (to save gpu)
vec4 ShowScene (vec3 ro, vec3 rd, vec3 backColor) {
    if (cube(ro,rd, CUBE_SIZE*2.-1.)) { // Full scene bounding box
        float d = BallHit (ro, rd);
        if (d < dstFar) {
            vec3 pos = ro + d*rd, nor = vnBall;
            return vec4(shade(rd, pos, nor, 63.*(.5+.5*cos(float(2*idBall))), d), d);
        } 
    }
    return vec4(backColor, 20);
}


// Create camera base matrix
mat3 setCamera( in vec3 ro, in vec3 ta, float cr) {
    cr = .1*cos(.1*iTime);
	vec3 w = normalize(ta-ro),
	 	 p = vec3(0., sin(cr), -cos(cr)),
         u = normalize( cross(w,p) ),
         v = normalize( cross(u,w) );
    return mat3(u,v,w);
}

void mainImage (out vec4 fragColor, vec2 fragCoord) {
    
    // Normalize pixels
    vec2 canvas = iResolution.xy,
         uv = 2. * fragCoord.xy/canvas - 1.;
    uv.x *= canvas.x / canvas.y;
    
	// Camera      
    float gAnim = mod(iTime,35.);

    // Distance
    float camDist;
    camDist = mix(3.5,4.5, smoothstep(9.,11.,gAnim));
    camDist = mix(camDist,6., smoothstep(17.,23.,gAnim));
    camDist = mix(camDist,3.5, smoothstep(34.,35.,gAnim));
    
    // Target
    vec3 ta;
    ta = mix(vec3(0,0,.8*CUBE_SIZE.z), vec3(0), smoothstep(10.,12.,gAnim));
    ta = mix(ta, vec3(0,0,.8*CUBE_SIZE.z), smoothstep(33.,35.,gAnim));
    
    // Camera position
    vec3 a = mix(vec3(cos(.5*iTime), sin(.5*iTime), -.5),vec3(1,1,-.5), smoothstep(1.,0.,iTime)); 
    vec3 ro = ta + camDist*pow(float(NB_LELT),.45)*(.9+.1*cos(iTime))*a;
    
    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 1.);
    
    // current ray direction
    vec3 rd = ca * normalize( vec3(uv.xy, 4.5) );

    // Background color
    vec2 q = fragCoord.xy/canvas;
    float h = dot(vec3(q,1.),vec3(127.1,311.7,758.5453123));	
	vec3 backColor = vec3(.2) + .05*fract(sin(h)*43758.5453123);
    
    // Render scene (xyz = color, w = distance)
    vec4 result = ShowScene (ro, rd, backColor);
    
    // Post traitment
   	vec3 col = pow(1.5*result.xyz,vec3(.6));
    col *= pow(16.*q.x*q.y*(1.-q.x)*(1.-q.y), .25);
        
    fragColor = vec4(col, result.w);
}




