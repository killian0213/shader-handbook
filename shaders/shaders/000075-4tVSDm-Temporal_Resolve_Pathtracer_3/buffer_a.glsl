// Buffer A (buffer) — Temporal Resolve Pathtracer 3 by granito
// https://www.shadertoy.com/view/4tVSDm

// Hacked by Lucas Granito 2016 https://www.shadertoy.com/view/XlVSWh

// Simple path tracer. Created by Reinder Nijhoff 2014
// @reindernijhoff
//
// https://www.shadertoy.com/view/4tl3z4
//

#define SPEED 1.0
#define eps 0.01
#define EYEPATHLENGTH 4
#define SAMPLES 8
#define FULLBOX
#define LIGHTCOLOR vec3(16.86, 10.76, 8.2)*3.
#define WHITECOLOR vec3(.7295, .7355, .729)*0.7
#define ANIMATED

lowp float seed;

lowp float hash1() {
    return fract(sin(seed += 0.1)*43758.5453123);
}

lowp vec2 hash2() {
    return fract(sin(vec2(seed+=0.1,seed+=0.1))*vec2(43758.5453123,22578.1459123));
}

lowp vec3 hash3() {
    return fract(sin(vec3(seed+=0.1,seed+=0.1,seed+=0.1))*vec3(43758.5453123,22578.1459123,19642.3490423));
}


float bluenoise(vec2 uv)
{
    #if defined( ANIMATED )
    uv += 1337.0*fract(iTime);
    #endif
    float v = texture( iChannel1 , (uv + 0.5) / iChannelResolution[1].xy, 0.0).x;
    return v;
}


vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


//-----------------------------------------------------
// Intersection functions (by iq)
//-----------------------------------------------------

lowp vec3 nSphere( in vec3 pos, in vec4 sph ) {
    return (pos-sph.xyz)/sph.w;
}

lowp float iSphere( in vec3 ro, in vec3 rd, in vec4 sph ) {
    lowp vec3 oc = ro - sph.xyz;
    lowp float b = dot(oc, rd);
    lowp float c = dot(oc, oc) - sph.w * sph.w;
    lowp float h = b * b - c;
    if (h < 0.0) return -1.0;

	lowp float s = sqrt(h);
	lowp float t1 = -b - s;
	lowp float t2 = -b + s;
	
	return t1 < 0.0 ? t2 : t1;
}

vec3 nPlane( in vec3 ro, in vec4 obj ) {
    return obj.xyz;
}

float iPlane( in vec3 ro, in vec3 rd, in vec4 pla ) {
    return (-pla.w - dot(pla.xyz,ro)) / dot( pla.xyz, rd );
}

//-----------------------------------------------------
// scene
//-----------------------------------------------------

vec3 cosWeightedRandomHemisphereDirection( const vec3 n ) {
  	lowp vec2 r = hash2();
	lowp vec3  uu = normalize( cross( n, vec3(0.0,1.0,1.0) ) );
	lowp vec3  vv = cross( uu, n );
	lowp float ra = sqrt(r.y);
	lowp float rx = ra*cos(6.2831*r.x); 
	lowp float ry = ra*sin(6.2831*r.x);
	lowp float rz = sqrt( 1.0-r.y );
	lowp vec3  rr = vec3( rx*uu + ry*vv + rz*n );
    return normalize( rr );
}

vec3 randomSphereDirection() {
    lowp vec2 r = hash2()*6.2831;
	lowp vec3 dr=vec3(sin(r.x)*vec2(sin(r.y),cos(r.y)),cos(r.x));
	return dr;
}

vec3 randomHemisphereDirection( const vec3 n ) {
	lowp vec3 dr = randomSphereDirection();
	return dot(dr,n) * dr;
}

//-----------------------------------------------------
// light
//-----------------------------------------------------

lowp vec4 lightSphere;

void initLightSphere( float time ) {
	lightSphere = vec4( 2.5+2.2*sin(time),3.+2.*sin(time*0.7),6.0 + 1.0 * sin(time*1.7), 0.6 + 0.4 * sin(time*.5) );
}

lowp vec3 sampleLight( const in vec3 ro ) {
    lowp vec3 n = randomSphereDirection() * lightSphere.w;
    return lightSphere.xyz + n;
}

//-----------------------------------------------------
// scene
//-----------------------------------------------------

float bounce() { return pow( abs( sin( iTime * 1.5  *SPEED ) * 2.), 0.5) * 2. + 0.5;}
float sway() { return asin(cos( iTime * 1.5 * SPEED)) * 0.3;}
lowp float bounce2() { return pow( abs( sin( iTime * 2.  *SPEED ) * 2.), 0.5) + 0.5;}

lowp vec2 intersect( in vec3 ro, in vec3 rd, inout vec3 normal ) {
	lowp vec2 res = vec2( 1e20, -1.0 );
    lowp float t;
	
	t = iPlane( ro, rd, vec4( 0.0, 1.0, 0.0,0.0 ) ); if( t>eps && t<res.x ) { res = vec2( t, 1. ); normal = vec3( 0., 1., 0.); }
	t = iPlane( ro, rd, vec4( 0.0, 0.0,-1.0,8.0 ) ); if( t>eps && t<res.x ) { res = vec2( t, 1. ); normal = vec3( 0., 0.,-1.); }    
    t = iPlane( ro, rd, vec4( 1.0, 0.0, 0.0,sin(iTime*SPEED+0.5)*0.5+1.0 ) ); if( t>eps && t<res.x ) { res = vec2( t, 2. ); normal = vec3( 1., 0., 0.); }
#ifdef FULLBOX
    t = iPlane( ro, rd, vec4( 0.0,-1.0, 0.0,sin(iTime*SPEED)*0.5+6.) ); if( t>eps && t<res.x ) { res = vec2( t, 1. ); normal = vec3( 0., -1., 0.); }
    t = iPlane( ro, rd, vec4(-1.0, 0.0, 0.0,cos(iTime*SPEED)*0.5+6.) ); if( t>eps && t<res.x ) { res = vec2( t, 3. ); normal = vec3(-1., 0., 0.); }
#endif

	t = iSphere( ro, rd, vec4( 1.5 + sway(),0.5 + bounce(), 2.7, 1.0) ); if( t>eps && t<res.x ) { res = vec2( t, 1. ); normal = nSphere( ro+t*rd, vec4( 1.5 + sway(),0.5 + bounce(), 2.7,1.0) ); }
    t = iSphere( ro, rd, vec4( 4.0,0.5 + bounce2(), 4.0, 1.0) ); if( t>eps && t<res.x ) { res = vec2( t, 5. ); normal = nSphere( ro+t*rd, vec4( 4.0,0.5 + bounce2(), 4.0,1.0) ); }
    t = iSphere( ro, rd, lightSphere ); if( t>eps && t<res.x ) { res = vec2( t, 0.0 );  normal = nSphere( ro+t*rd, lightSphere ); }
					  
    return res;					  
}

bool intersectShadow( in vec3 ro, in vec3 rd, in float dist ) {
    lowp float t;
	
	t = iSphere( ro, rd, vec4( 1.5 + sway(),0.5 + bounce(), 2.7,1.0) );  if( t>eps && t<dist ) { return true; }
    t = iSphere( ro, rd, vec4( 4.0,0.5 + bounce2(), 4.0,1.0) );  if( t>eps && t<dist ) { return true; }

    return false; // optimisation: planes don't cast shadows in this scene
}

//-----------------------------------------------------
// materials
//-----------------------------------------------------

lowp vec3 matColor( const in float mat ) {
	lowp vec3 nor = vec3(1., 1., 1.);
	
	if( mat<3.5 ) nor = hsv2rgb(vec3(iTime * 0.025,0.8,0.6));
    if( mat<2.5 ) nor = hsv2rgb(vec3(iTime * 0.025 + 0.5,0.9,0.6));
	if( mat<1.5 ) nor = WHITECOLOR;
	if( mat<0.5 ) nor = LIGHTCOLOR;
					  
    return nor;					  
}

bool matIsSpecular( const in float mat ) {
    return mat > 4.5;
}

bool matIsLight( const in float mat ) {
    return mat < 0.5;
}

//-----------------------------------------------------
// brdf
//-----------------------------------------------------

lowp vec3 getBRDFRay( in vec3 n, const in vec3 rd, const in float m, inout bool specularBounce ) {
    specularBounce = false;
    
    lowp vec3 r = cosWeightedRandomHemisphereDirection( n );
    if(  !matIsSpecular( m ) ) {
        return r;
    } else {
        specularBounce = true;
        
        lowp float n1, n2, ndotr = dot(rd,n);
        
        if( ndotr > 0. ) {
            n1 = 1.0; 
            n2 = 1.5;
            n = -n;
        } else {
            n1 = 1.5;
            n2 = 1.0; 
        }

        lowp float r0 = (n1-n2)/(n1+n2); r0 *= r0;

		lowp float fresnel = r0 + (1.-r0) * pow(1.0-abs(ndotr),2.);
        
        lowp vec3 ref;
        
        ref = reflect( rd, n );
        
        return normalize( ref + 0.1 * hash1() * r );
	}
}

//-----------------------------------------------------
// eyepath
//-----------------------------------------------------

lowp vec3 traceEyePath( in vec3 ro, in vec3 rd, const in bool directLightSampling ) {
    lowp vec3 tcol = vec3(0.);
    lowp vec3 fcol  = vec3(1.);
    
    bool specularBounce = true;
    
    for( int j=0; j<EYEPATHLENGTH; ++j ) {
        lowp vec3 normal;
        
        lowp vec2 res = intersect( ro, rd, normal );
        if( res.y < -0.5 ) {
            return tcol;
        }
        
        if( matIsLight( res.y ) ) {
            if( directLightSampling ) {
            	if( specularBounce ) tcol += fcol*LIGHTCOLOR;
            } else {
                tcol += fcol*LIGHTCOLOR;
            }

            return tcol;
        }
        
        ro = ro + res.x * rd;
        
        rd = getBRDFRay( normal, rd, res.y, specularBounce );        
        
        fcol *= matColor( res.y );

        lowp vec3 ld = sampleLight( ro ) - ro;
        
        if( directLightSampling ) {
			lowp vec3 nld = normalize(ld);
            if( !specularBounce && j < EYEPATHLENGTH-1 && !intersectShadow( ro, nld, length(ld)) ) {

                lowp float cos_a_max = sqrt(1. - clamp(lightSphere.w * lightSphere.w / dot(lightSphere.xyz-ro, lightSphere.xyz-ro), 0., 1.));
                lowp float weight = 2. * (1. - cos_a_max);

                tcol += (fcol * LIGHTCOLOR) * (weight * clamp(dot( nld, normal ), 0., 1.));
            }
        }
    }    
    return tcol;
}

//-----------------------------------------------------
// main
//-----------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

	vec2 q = fragCoord.xy / iResolution.xy;
    
    lowp float splitCoord = (iMouse.x == 0.0) ? iResolution.x/2. + iResolution.x*cos(iTime*.5) : iMouse.x;
    bool directLightSampling = true;
    
    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------

    lowp vec2 p = -1.0 + 2.0 * (fragCoord.xy) / iResolution.xy;
    p.x *= iResolution.x/iResolution.y; 

    seed = bluenoise(fragCoord.xy); // jitter dither pattern offset

    lowp vec3 ro = vec3(2.78, 2.73, -8.00);
    lowp vec3 ta = vec3(2.78, 2.73,  0.00);
    lowp vec3 ww = normalize( ta - ro );
    lowp vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    lowp vec3 vv = normalize( cross(uu,ww));

    //-----------------------------------------------------
    // render
    //-----------------------------------------------------

    lowp vec3 col = vec3(0.0);
    lowp vec3 tot = vec3(0.0);
    lowp vec3 uvw = vec3(0.0);
    
    for( int a=0; a<SAMPLES; a++ ) {

        lowp vec2 rpof;

	    lowp vec3 rd = normalize( (p.x+rpof.x)*uu + (p.y+rpof.y)*vv + 3.0*ww );
        
        lowp vec3 rof = ro;

        initLightSphere( iTime * SPEED * 1.0);        

        col = traceEyePath( rof, rd, directLightSampling );

        tot += col;
        
        seed = mod( seed*1.1234567893490423, 13. );
    }
    
    tot /= float(SAMPLES);
    
    tot = pow( tot, vec3(0.35) );

    fragColor = vec4( tot, 1.0 );
}
