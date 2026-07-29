// Common (common) — Crowdy waves 2 by FabriceNeyret2
// https://www.shadertoy.com/view/3ty3Dy

#define N 10. // use only 1/N % of the max Rx*Ry particles (for readability)

// Buff B (1) store Voronoï tracking acceleration structure;
//            xyzw: ids of 4 closest partics to buffer location
// Buff A (0) stores particles: 
//            xy: position zw: velocity

// --- translate particle id (in [1,Rx*Ry] ) to buffer pixel 
#define A(n) T0( vec2( (int(n)-1) % iR.x,      \
                       (int(n)-1) / iR.x ) +.5 )  // +.5 useless

// --- utils
                           
#define R     iResolution.xy
#define iR    ivec2(iResolution)
#define T0(U) texelFetch( iChannel0, ivec2(U)   , 0 )
#define T1(U) texelFetch( iChannel1, ivec2(U)%iR, 0 )
#define T2(U) texelFetch( iChannel2, ivec2(U)   , 0 )

#define l2(x) dot(x,x)

#define TAU 6.2831853
                           
#define hue(v)  ( .6 + .6 * cos( 6.3*(v)  + vec4(0,23,21,0)  ) )
                           
// --- keyboard
#define key(k,mode) ( texelFetch( iChannel3, ivec2(k,mode), 0 ).x > .5 )
#define keyDown(k) key(k,0)
#define  keyHit(k) key(k,1)
#define keyFlip(k) key(k,2)


// --- random numbers

int IHash(int a){
	a = (a ^ 61) ^ (a >> 16);
	a = a + (a << 3);
	a = a ^ (a >> 4);
	a = a * 0x27d4eb2d;
	a = a ^ (a >> 15);
	return a;
}

#define Hash(a) ( float(IHash(a)) / float(0x7FFFFFFF) ) // Uniform in [0,1]

vec4 rand4(int seed){
    return vec4(Hash(seed^0x34F85A93),
                Hash(seed^0x85FB93D5),
                Hash(seed^0x6253DF84),
                Hash(seed^0x25FC3625));
}

// --- normal law random generator
vec2 randn(vec2 r){ // r: randuniform
    r.x = sqrt( -2.* log(1e-9+abs(r.x)));
    r.y *= TAU;
    return r.x * vec2(cos(r.y),sin(r.y));
}
