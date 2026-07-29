// Image (image) — 4D raymarching by iapafoto
// https://www.shadertoy.com/view/4sjGWw

// Created by sebastien durand - 2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Based on iq famous exemple
// More info here: https://iquilezles.org/articles/distfunctions

 // Change this to improve quality (3 is good)
#define ANTIALIASING 3

#define RAY_STEP 200
//#define DRAWAXES


float sdPlane( vec4 p ) {
	return p.y;
}

// 3-sphere (4d sphere)
float sdSphere( vec4 p, float s ) {
    return length(p)-s;
}

float sdEllipsoid( in vec4 p, in vec4 r) {
    return (length(p/r ) - 1.) * min(min(min(r.x,r.y),r.z),r.w);
}

// tesseract (4d hypercube)
float sdTesseract( vec4 p, vec4 b ) {
  vec4 d = abs(p) - b;
  return min(max(d.x,max(d.y,max(d.z,d.w))),0.0) + length(max(d,0.0));
}

float udRoundTesseract( vec4 p, vec4 b, float r) {
  return length(max(abs(p)-b,0.0))-r;
}

float sdCapsule( vec4 p, vec4 a, vec4 b, float r ) {
	vec4 pa = p - a, ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0., 1. );
	return length( pa - ba*h ) - r;
}


float sdCylinder(in vec4 p,in vec2 h ) {
  return max(length(p.xzw)-h.x, abs(p.y)-h.y );
}

float sdCone(in vec4 p,in vec2 h ) {
  return max( length(p.xzw)-h.x, abs(p.y)-h.y) - h.x*p.y;
}

// http://eusebeia.dyndns.org/4d/cubinder
float sdCubicalCylinder(vec4 p, vec3 rh1h2) {
	vec3 d = abs(vec3(length(p.xz), p.y, p.w)) - rh1h2;
	return min(max(d.x,max(d.y,d.z)),0.) + length(max(d,0.));
}

// http://eusebeia.dyndns.org/4d/duocylinder
float sdDuoCylinder( vec4 p, vec2 r1r2) {
  vec2 d = abs(vec2(length(p.xz),length(p.yw))) - r1r2;
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}


float opS( float d1, float d2 ) {
    return max(-d2,d1);
}

vec2 opU( vec2 d1, vec2 d2 ) {
	return (d1.x<d2.x) ? d1 : d2;
}

vec4 opRep( vec4 p, vec4 c ) {
    return mod(p,c)-0.5*c;
}

vec4 opRepW(vec4 p, float c) {
	p.w = mod(p.w,c)-0.5*c;
    return p;
}

vec4 opTwist( vec4 p ) {
    float  c = cos(10.0*p.y+10.0);
    float  s = sin(10.0*p.y+10.0);
    mat2   m = mat2(c,-s,s,c);
    return vec4(m*p.xz,p.y, p.w);
}

//----------------------------------------------------------------------

vec2 map( in vec4 pos ) {
    vec2 res = vec2(99999.,0);

#ifdef DRAWAXES
//	pos.xy *= mat2(c2,-s2,s2,c2);
	
	res = opU( res, vec2( sdCapsule(   pos,vec4(0), vec4(10.,0.,0.,0.), 0.05  ), 31.9 ) );
	res = opU( res, vec2( sdCapsule(   pos,vec4(0), vec4(0.,10.,0.,0.), 0.05  ), 41.9 ) );
	res = opU( res, vec2( sdCapsule(   pos,vec4(0), vec4(0.,0.,10.,0.), 0.05  ), 51.9 ) );
	res = opU( res, vec2( sdCapsule(   pos,vec4(0), vec4(0.,0.,0.,10.), 0.05  ), 61.9 ) );
#else
	res = vec2(sdPlane(pos),1.);
#endif
    res = opU( res, vec2(sdCubicalCylinder(pos-vec4(-.5,.3, -.8, .1), vec3(.2,.3,.2)), 60.9 ) );
    res = opU( res, vec2(sdDuoCylinder( pos-vec4(-.2,.3, -.2, -.1), vec2(.2,.3) ), 53.9 ) );


	res = opU( res, vec2( sdTesseract(       pos-vec4( 1.0,0.25, 0.1, 0.2), vec4(0.25) ), 3.0 ) );
    res = opU( res, vec2( udRoundTesseract(  pos-vec4( 1.0,0.25, 1.0, 0.0), vec4(0.15), 0.1 ), 41.0 ) );
	res = opU( res, vec2( sdCapsule(   pos,vec4(-1.3,0.20,-0.1, -.3), vec4(-1.0,0.20,0.2,1.5), 0.1  ), 31.9 ) );
	res = opU( res, vec2( sdCylinder(  pos-vec4( 1.0,0.30,-1.0, -.5), vec2(0.1,0.2) ), 4.0 ) );
	//res = opU( res, vec2( sdCone(      pos-vec4( 1.0,0.30,-1.0, 0.10), vec2(0.1,0.4) ), 4.0 ) );
	
	float d = 2.;
	pos.w = mod(pos.w,d)-.5*d;
   
      res = opU( res, vec2( sdSphere(pos-vec4( 0.0,0.25, 0.0, 0.25), 0.25 ), 46.9 ) );
  //  res = opU( res, vec2( sdEllipsoid(pos-vec4( 0.0,0.25, 0.0, 0.25), vec4(.25,.1,.15,.3) ), 46.9 ) );

	return res;
}


vec2 castRay( in vec4 ro, in vec4 rd, in float maxd ) {
	float precis = 0.0005;
    float h=precis*2.0;
    float t = 2.0;
	vec2 res;
    for( int i=0; i<RAY_STEP; i++ ) {
        if (abs(h)<precis || t>maxd ) break;
        t += h;
        res = map( ro+rd*t );
        h = res.x;
    }
    return vec2( t, t>=maxd ? -1. : res.y );
}

float softshadow( in vec4 ro, in vec4 rd, in float mint) {
	float res = 1.0;
    float h,t = mint;
    for( int i=0; i<15; i++ ) {
        h = map( ro + rd*t ).x;
        res = min( res, 7.*h/t );
        t += 0.028;
    }
    return clamp( res-.6, 0.0, 1.0 );
}

const vec2 eps = vec2( 0.001, 0.0);
vec4 calcNormal( in vec4 pos )
{
	return normalize(vec4(
	    map(pos+eps.xyyy).x - map(pos-eps.xyyy).x,
	    map(pos+eps.yxyy).x - map(pos-eps.yxyy).x,
	    map(pos+eps.yyxy).x - map(pos-eps.yyxy).x,
		map(pos+eps.yyyx).x - map(pos-eps.yyyx).x
	));
}

float calcAO( in vec4 pos, in vec4 nor ){
	float dd, hr, totao = 0.0;
    float sca = 1.0;
    vec4 aopos; 
    for( int aoi=0; aoi<5; aoi++ ) {
        hr = 0.01 + 0.05*float(aoi);
        aopos =  nor * hr + pos;
        totao += -(map( aopos ).x-hr)*sca;
        sca *= 0.75;
    }
    return clamp( 1.0 - 4.0*totao, 0.0, 1.0 );
}

vec3 render( in vec4 ro, in vec4 rd ){ 
    vec3 col = vec3(0);
    vec2 res = castRay(ro,rd, 19.0);
    float t = res.x;
	float m = res.y;
    if( m>-0.5 )
    {
        vec4 pos = ro + t*rd;
        vec4 nor = calcNormal( pos );

		col = vec3(0.6) + 0.4*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
		
        float ao = calcAO( pos, nor );

		vec4 lig = normalize( vec4(-0.6, 0.7, -0.5, 0.5) );
		float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec4(-lig.x,0.0,-lig.z,0.0))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);

		float sh = 1.0;
		if( dif>0.02 ) { sh = softshadow( pos, lig, 0.025); dif *= sh; }

		vec3 brdf = vec3(0.0);
		brdf += 0.20*amb*vec3(0.10,0.11,0.13)*ao;
        brdf += .2*bac*vec3(0.15)*ao;
        brdf += 1.20*dif*vec3(1.00,0.90,0.70);

		float pp = clamp( dot( reflect(rd,nor), lig ), 0.0, 1.0 );
		float spe = sh*pow(pp,16.0);
		float fre = ao*pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );

		col = col*brdf + vec3(1.0)*col*spe + 0.7*fre*(0.5+0.5*col);
	}

	col *= exp( -0.01*t*t );

	return vec3( clamp(col,0.0,1.0) );
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 mo = iMouse.xy/iResolution.xy;	 
	float time = 20.0 + iTime*8.;
	vec3 colorSum = vec3(0.);

          	// rotation around xy plane
	float 
		a = (iTime-3.)/2.03,
		b = (iTime-3.)/2.1,
		c1 = cos(a), s1 = sin(a),
		c2 = cos(b), s2 = sin(b);
	mat2 rot1 = mat2(c1,-s1,s1,c1),
         rot2 = mat2(c2,-s2,s2,c2);
    
    vec4 rd,
        ro = vec4( -0.5+3.2*cos(0.1*time + 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 3.2*sin(0.1*time + 6.0*mo.x),0.),
        ta = vec4( -0.5, -0.4, 0.5, 0. ),
        cw = normalize( ta-ro ),
        cp = vec4( 0., 1., 0., 0. ),
        cu = normalize( vec4(cross(cw.xyz,cp.xyz),0.)),
        cv = normalize( vec4(cross(cu.xyz,cw.xyz),0.));

// Rotation of 4D scene
    ro.zw *= rot1;
	ro.xw *= rot2;
    
#if (ANTIALIASING == 1)	
	int i=0;
#else
	for (int i=0;i<ANTIALIASING;i++) {
#endif
		vec2 q = (fragCoord.xy+.4*vec2(cos(6.28*float(i)/float(ANTIALIASING)),sin(6.28*float(i)/float(ANTIALIASING))))/iResolution.xy;
		vec2 p = -1.0+2.0*q;
		p.x *= iResolution.x/iResolution.y;

		// Camera is still a 2D plane because human vision is in 2D (brain recalculates 3D)
		// (The scene is time rotated around xy plan)
		rd = normalize( p.x*cu + p.y*cv + 2.5*cw );
		// Rotation of 4D scene
    	rd.zw *= rot1;
		rd.xw *= rot2;
        
		colorSum += sqrt(render( ro, rd ));
#if (ANTIALIASING > 1)	
	}
    fragColor = vec4(colorSum/float(ANTIALIASING), 1.);
#else
	fragColor=vec4(colorSum, 1.);
#endif
}