// Image (image) — protoplasm - shorter by FabriceNeyret2
// https://www.shadertoy.com/view/MlSSzG

// short & simplified version of https://www.shadertoy.com/view/lllSWr


mat4 m = mat4( 0,   1.8,  1.2, 0,  // random 3x3 rotation and /2 scaling ( padded to 4x4 )
              -1.6,  .7, -1,   0,
       	  	  -1.2, -1,   1.3, 0,
               0,    0,   0,   0);
// float m = 2.;                  // shorter but less random

// --- compact Perlin noise

#define N(p)   ( 2.* texture( iChannel0, (p).xy/256. ) - 1. )                      // random value in [-1,1]
vec4 P(vec4 p) { return N(p*=m/4.)/2. + N(p*=m)/4. + N(p*=m)/8.  + N(p*=m)/16. ;}  // "Perlin" value noise

// --- using the base ray-marcher of Trisomie21: https://www.shadertoy.com/view/4tfGRB

void mainImage( out vec4 f, vec2 w ) {
    
    vec4 p = vec4(w,0,1)/iResolution.yyxy-.5, d,u,t; p.x-=.4;    // init ray. p = position on ray
    d = p; p.z += 10.;                                           // ray dir d = ray0-vec3(0)
    float  T=iTime, x=1e9, l;
    f = vec4(0,.2,0,1);                                          // bg color

    for (float i=1.; i>0.; i-=.01)                               // ray march 100 steps
        u = .03* floor( p/vec4(8,8,1,1) +3.5 ), t = p, 

        // try = instead of += !
 		t +=   P( t+vec4(T,0,0,0) )  *  ( 4.6 - 4.*cos(T/16.) ), // distort space with Perlin noise * waves
 
        x = max( abs( fract(l=length(t.xyz)) -.5 ) ,  l-7. ),    // distance to oignon layers
        x<.01 ? f += (1.-f)*.4*i*i, x=.1 : x,                    // hit : blend voxel volor
                
        p += d*x;                                                // march ray
     
}
