// Image (image) — High-perf by-example Noise [HN18 by FabriceNeyret2
// https://www.shadertoy.com/view/MdyfDV

// ---------------------------------------------------------------------
// With only 3 texture fetches, generates endless seamless non-repeating 
// same-properties texture from example. ( in the paper: +1 LUT fetch
// to handle non-Gaussian correlated color histograms).

// Simple implementation of our HPG'18 
// "High-Performance By-Example Noise using a Histogram-Preserving Blending Operator"
// https://hal.inria.fr/hal-01824773
// ( color-histogram Gaussianisation not possible in shadertoy ;-) 
//   or possibly via this approx: https://www.shadertoy.com/view/slX3zr  ). 
// ---------------------------------------------------------------------

#define CON 1      // contrast preserving interpolation. cf https://www.shadertoy.com/view/4dcSDr
#define Z   8.     // patch scale inside example texture

#define rnd22(p)    fract(sin((p) * mat2(127.1,311.7,269.5,183.3) )*43758.5453)
#define srgb2rgb(V) pow( max(V,0.), vec4( 2.2 )  )          // RGB <-> sRGB conversions
#define rgb2srgb(V) pow( max(V,0.), vec4(1./2.2) )

// --- texture patch associated to vertex I in triangular/hexagonal grid. key 'P'
// (textureGrad handles MIPmap through patch borders)
#define C(I)  ( keyToggle(16) ? vec4( I==P, I==P+vec2(1,0), I==P+vec2(0,1), 1 ) \
                              : srgb2rgb( textureGrad(iChannel0, U/Z-rnd22(I) ,Gx,Gy)) - m*float(CON) )
// --- for tests
//#define C(I)     ( srgb2rgb( texture(iChannel0, U/8.-rnd22(I)) ) - m*float(CON) )
//#define C(I)     ( srgb2rgb( textureGrad(iChannel0, U/Z-rnd22(I) ,Gx,Gy)) - m*float(CON) )
//#define C(I)     H(I)
//#define C(I)     vec4( I==P, I==P+vec2(1,0), I==P+vec2(0,1), 1 )
#define S(v)       smoothstep( p,-p, v )                    // antialiased drawing
#define hue(v)   ( .6 + .6 * cos( v  + vec4(0,23,21,0)  ) ) // from https://www.shadertoy.com/view/ll2cDc
#define H(I)       hue( (I).x + 71.3*(I).y )
#define keyToggle(c) ( texelFetch(iChannel3,ivec2(64+c,2),0).x > 0.) // keyboard. from https://www.shadertoy.com/view/llySRh

// ---------------------------------------------------------------------
void mainImage( out vec4 O, vec2 u )
{
    mat2 M0 = mat2( 1,0, .5,sqrt(3.)/2. ),
          M = inverse( M0 );                           // transform matrix <-> tilted space
    vec2 R = iResolution.xy,
         z = iMouse.xy/R,
         U = ( 2.*u - R ) / R.y  *Z/8.* exp2(z.y==0.?2.:4.*z.y+1.) + vec2(2.*iTime),
         V = M * U,                                    // pre-hexa tilted coordinates
         I = floor(V),                                 // hexa-tile id
         P = floor( M * vec2(2.*iTime) );              // center tile (to show patches)
    float p = .7*dFdy(U.y);                            // pixel size (for antialiasing)
    vec2 Gx = dFdx(U/Z), Gy = dFdy(U/Z);               // (for cross-borders MIPmap)
    vec4 m = srgb2rgb( texture(iChannel0,U,99.) );     // mean texture color
    
    vec3 F = vec3(fract(V),0), A, W; F.z = 1.-F.x-F.y; // local hexa coordinates
    if ( F.z > 0. )
        O = ( W.x=   F.z ) * C(I)                      // smart interpolation
          + ( W.y=   F.y ) * C(I+vec2(0,1))            // of hexagonal texture patch
          + ( W.z=   F.x ) * C(I+vec2(1,0));           // centered at vertex
    else                                               // ( = random offset in texture )
        O = ( W.x=  -F.z ) * C(I+1.) 
          + ( W.y=1.-F.y ) * C(I+vec2(1,0)) 
          + ( W.z=1.-F.x ) * C(I+vec2(0,1));
#if CON    
    O = m + O/length(W);  // contrast preserving interp. cf https://www.shadertoy.com/view/4dcSDr
#endif
    O = clamp( rgb2srgb(O), 0., 1.);
    if (m.g==0.) O = O.rrrr;                           // handles B&W (i.e. "red") textures
    
    if (keyToggle(7)) O = mix( O, vec4(1), S(min(W.x,min(W.y,W.z))-p) ); // key 'G'; show grid   
  //O = mix(O, H(floor(V+.5)), S(length(M0*(fract(V+.5)-.5))-.1));       // show nodes
}