// Image (image) — flow by Perlin noise by FabriceNeyret2
// https://www.shadertoy.com/view/Xl3Gzj

// see also https://www.shadertoy.com/view/ldtSzn

// --- Perlin noise by inigo quilez - iq/2013   https://www.shadertoy.com/view/XdXGW8
//     (extended to 3D)
vec3 hash( vec3 p )
{
	p *= mat3( 127.1,311.7,-53.7,
			   269.5,183.3, 77.1,
			  -301.7, 27.3,215.3 );

	return 2.*fract(sin(p)*43758.5453123) -1.;
}

float noise( vec3 p )
{
    vec3 i = floor( p ),
         f = fract( p ),
	     u = f*f*(3.-2.*f);
      // u = f*f*f* ( 10. + f * ( -15. + 6.* f ) ); // smoother. from http://staffwww.itn.liu.se/~stegu/TNM022-2005/perlinnoiselinks/paper445.pdf
 
    return 2.*mix(
              mix( mix( dot( hash( i + vec3(0,0,0) ), f - vec3(0,0,0) ), 
                        dot( hash( i + vec3(1,0,0) ), f - vec3(1,0,0) ), u.x),
                   mix( dot( hash( i + vec3(0,1,0) ), f - vec3(0,1,0) ), 
                        dot( hash( i + vec3(1,1,0) ), f - vec3(1,1,0) ), u.x), u.y),
              mix( mix( dot( hash( i + vec3(0,0,1) ), f - vec3(0,0,1) ), 
                        dot( hash( i + vec3(1,0,1) ), f - vec3(1,0,1) ), u.x),
                   mix( dot( hash( i + vec3(0,1,1) ), f - vec3(0,1,1) ), 
                        dot( hash( i + vec3(1,1,1) ), f - vec3(1,1,1) ), u.x), u.y), u.z);
}

float Mnoise(vec3 U ) {
    return noise(U);                      // base turbulence
  //return -1. + 2.* (1.-abs(noise(U)));  // flame like
  //return -1. + 2.* (abs(noise(U)));     // cloud like
}

float turb( vec2 U, float t )
{ 	float f = 0., q=1., s=0.;
	
    float m = 2.; 
 // mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    for (int i=0; i<2; i++) {
      U -= t*vec2(.6,.2);
      f += q*Mnoise( vec3(U,t) ); 
      s += q; 
      q /= 2.; U *= m; t *= 1.71;  // because of diff, we may rather use q/=4.;
    }
    return f/s; 
}
// -----------------------------------------------

#define L(a,b) O+= .3/R.y/length( clamp( dot(U-(a),v=b-(a))/dot(v,v), 0.,1.) *v - U+a )

void mainImage( out vec4 O, in vec2 U )
{
    vec2 R = iResolution.xy;
    U /= R.y;
	float S = 3.,                              // scaling of noise
        eps = 1e-3, t=.4*iTime;
    //U -= t*vec2(.3,.1);                      // translation (or do it per band)
    
    float n = turb(S*U,t);                     // pure noise = stream
 
                                               // flow = rot(stream) 
 // vec2  V = vec2( turb(S*U+vec2(0,-eps),t) - turb(S*U+vec2(0,eps),t),
 //                 turb(S*U+vec2(eps,0),t)  - turb(S*U+vec2(-eps,0),t) ) / eps;
    vec2 V = vec2( -dFdy(n), dFdx(n) )* R.y*.7;// using hardware derivatives
    //V += vec2(3,0);                          // linearly combine other base flows
    V /= R.y;
    
	O = clamp(vec4(n,0,-n,0),0.,1.);           // draw stream value (note that curl = lapl(stream) so they are very similar)
    
    S = R.y/10.;
    vec2 p = floor(U*S+.5)/S, v;           // draw velocity vectors
    L ( p-V*2., p+V*2.);               
}