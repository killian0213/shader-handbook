// Common (common) — Frozen Lake by TDM
// https://www.shadertoy.com/view/MsXyzN

/*
 * "Frozen Lake" by Alexander Alekseev aka TDM - 2019
 * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * Contact: tdmaav@gmail.com
 */

#define HASHSCALE3 vec3(.1031, .1030, .0973)
const float PI = 3.141592;

float saturate(float x) { return clamp(x,0.0,1.0); }
float mul(vec2 x) { return x.x*x.y; }
mat3 fromEuler(vec3 ang) {
	vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
	m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
	m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
	return m;
}

bool intersectionPlane(vec3 o, vec3 d, out vec3 p) {
    float t = o.y / d.y;
    p = o - d * t;
    return bool(step(t,0.0));
}

float hash11(float x) {
    return fract(sin(x) * 43758.5453);
}
float hash12( vec2 p ) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}
vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}
float hash13(in vec3 p) {
    p  = fract( p*0.3183099+.1 );
	p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}
float noise11(in float p) {
    float i = floor( p );
    float f = fract( p );	
	float u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix(hash11(i),hash11(i+1.0),u);
}
float noise12( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );	
	vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash12( i + vec2(0.0,0.0) ), 
                     hash12( i + vec2(1.0,0.0) ), u.x),
                mix( hash12( i + vec2(0.0,1.0) ), 
                     hash12( i + vec2(1.0,1.0) ), u.x), u.y);
}
vec2 noise2( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );	
	vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash22( i + vec2(0.0,0.0) ), 
                     hash22( i + vec2(1.0,0.0) ), u.x),
                mix( hash22( i + vec2(0.0,1.0) ), 
                     hash22( i + vec2(1.0,1.0) ), u.x), u.y);
}

float noise13(in vec3 p) {
    vec3 i = floor( p );
    vec3 f = fract( p );	
	vec3 u = f*f*(3.0-2.0*f);
    
    float a = hash13( i + vec3(0.0,0.0,0.0) );
	float b = hash13( i + vec3(1.0,0.0,0.0) );    
    float c = hash13( i + vec3(0.0,1.0,0.0) );
	float d = hash13( i + vec3(1.0,1.0,0.0) ); 
    float v1 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
    
    a = hash13( i + vec3(0.0,0.0,1.0) );
	b = hash13( i + vec3(1.0,0.0,1.0) );    
    c = hash13( i + vec3(0.0,1.0,1.0) );
	d = hash13( i + vec3(1.0,1.0,1.0) );
    float v2 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
        
    return abs(mix(v1,v2,u.z));
}

float fbm1(in float p) {
    float m = 2.0;
    float a = 1.0;
    float w = 1.0;
    float f = noise11( p );
    for(int i = 0; i < 8; i++) {
        p *= m; a /= 1.8;
        f += a*noise11( p );
        w += a;
    }
    return f / w;
}

float fbm2(in vec2 p, float t) {
    float m = 2.0;
    float a = 1.0;
    float w = 1.0;
    float f = noise12( p );
    for(int i = 0; i < 8; i++) {
        p *= m; a /= 1.5;
        f += a*noise12( p+t );
        w += a;
    }
    return f / w;
}

vec2 fbm22(in vec2 p) {
    float m = 2.0;
    float a = 1.0;
    float w = 1.0;
    vec2 f = noise2( p );
    for(int i = 0; i < 8; i++) {
        p *= m; a /= 1.2;
        f += a*noise2(p);
        w += a;
    }
    return f / w;
}

float fbmClouds(in vec2 p) {
    p *= 0.001;
    float m = 2.0;
    float a = 1.0;
    float w = 1.0;
    float f = noise12( p );
    for(int i = 0; i < 4; i++) {
        p *= m; a /= 1.5;
        f += a* abs(noise12( p ));
        w += a;
    }
    f /= w;
    //f = pow(max(f,0.0001),5.0);
    f = max((f - 0.4) / (1.0 - 0.4), 1e-4);
    f = sqrt(f);
    return f;
}

// iq's voronoi
vec3 voronoi( in vec2 x ) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
	vec2 mg, mr;

    float md = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
		vec2 o = hash22( n + g );
        vec2 r = g + o - f;
        float d = dot(r,r);

        if( d<md )
        {
            md = d;
            mr = r;
            mg = g;
        }
    }

    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    md = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = mg + vec2(float(i),float(j));
		vec2 o = hash22( n + g );
        vec2 r = g + o - f;

        if( dot(mr-r,mr-r)>0.00001 )
        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
    }

    return vec3( md, mr );
}

float triangle(float x) {
	return abs(1.0 - mod(abs(x), 2.0)) * 2.0 - 1.0;
}

// gamma correction
const float GAMMA = 2.2;
const float iGAMMA = 1.0 / GAMMA;
float toLinear(float c) { return pow(c,GAMMA); }
vec2 toLinear(vec2 c) { return pow(c,vec2(GAMMA)); }
vec3 toLinear(vec3 c) { return pow(c,vec3(GAMMA)); }
float toSRGB(float c) { return pow(c,iGAMMA); }
vec2 toSRGB(vec2 c) { return pow(c,vec2(iGAMMA)); }
vec3 toSRGB(vec3 c) { return pow(c,vec3(iGAMMA)); }