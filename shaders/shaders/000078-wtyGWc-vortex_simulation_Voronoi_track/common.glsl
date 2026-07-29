// Common (common) — vortex simulation+Voronoi track by FabriceNeyret2
// https://www.shadertoy.com/view/wtyGWc

#define R     iResolution.xy

// --- simu params

#define N 100         // N*N partics
#define Nf float(N)
#define MARKERS .97   // % of passive markers
#define BINARY 0      // are vorticities distributed or binaries ( -1 or 1 )
                      //   2: on the fly
#define CYCLE 2       // evaluate forces through cycling world 0:no 1:full 2:cheap
#define STRENGTH ( (R.y>300. ? 2e2 : 1e2 ) / (1.-MARKERS) * (15./Nf) )
#define Nmark     int( float(N*N) * MARKERS )
#define Nvort    ( N*N - Nmark )


// --- display params

#define BLEND 2 // Blending mode: 0: add   1: max   2: add partics & blend past

float Rv = 16., // vortice thickness^2 (pixels)
      Rm = 2.,  // markers thickness^2 (pixels)
      Wv = BLEND != 2 ? .3 : .5; // vortice weight



// ----------------------------------------------

// Buff B (1) store Voronoï tracking acceleration structure;
//            xyzw: ids of 4 closest partics to buffer location
// Buff A (0) stores particles: 
//            xy: position zw: velocity

// --- translate particle id to buffer pixel 
#define A(n,T) T0( T+ ivec2( (int(n)-1) % N,     \
                             (int(n)-1) / N ) ) // + tile offset

#define W(P)      T1( P + vec2(0,N) ).z
                                 
// --- utils
                           
#define iR    ivec2(iResolution)
#define T0(U) texelFetch( iChannel0, ivec2(U)   , 0 )
#define T1(U) texelFetch( iChannel1, ivec2(U)%iR, 0 )
#define T2(U) texelFetch( iChannel2, ivec2(U)   , 0 )

#define l2(x) dot(x,x)

#define TAU 6.2831853

#define keyFlip(k) ( texelFetch( iChannel3, ivec2(k,2), 0 ).x > .5 )
                           
// --- random numbers

 #define rand2(U)   fract( 1e5* sin( mat2(17.1,191.7,-31.1,241.7) * U ))

int IHash(int a){
	a = (a ^ 61) ^ (a >> 16);
	a = a + (a << 3);
	a = a ^ (a >> 4);
	a = a * 0x27d4eb2d;
	a = a ^ (a >> 15);
	return a;
}