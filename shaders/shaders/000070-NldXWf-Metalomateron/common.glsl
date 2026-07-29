// Common (common) — Metalomateron by davidar
// https://www.shadertoy.com/view/NldXWf

#define GRID vec2(3,2)
#define CELL ivec2(GRID * u/R)
#define SHADER (2 + CELL.x + int(GRID.x)*CELL.y)

#define MAIN void mainImage( out vec4 r, in vec2 u )
#define R iResolution.xy

#define UV fract(GRID * u/R)

// convolutions
#define CONV(z) for(int i=-z; i<=z; ++i) for(int j=-z; j<=z; ++j)
#define CONVO(z) CONV(z) if(0. < length(ij) && length(ij) <= float(z))

// gaussian
#define G(c) exp(-dot(c,c))

// textures
#define UVCOORD(u) ((vec2(CELL) + fract(GRID * (u)/R)) / GRID)
#define A(u) texture(iChannel0,UVCOORD(u))
#define B(u) texture(iChannel1,UVCOORD(u))
#define C(u) texture(iChannel2,UVCOORD(u))
#define D(u) texture(iChannel3,UVCOORD(u))

#define Au A(u)
#define Bu B(u)
#define Cu C(u)
#define Du D(u)

#define Ai A(u+ij)
#define Bi B(u+ij)
#define Ci C(u+ij)
#define Di D(u+ij)

#define Ad (Ai - Au)
#define Bd (Bi - Bu)
#define Cd (Ci - Cu)
#define Dd (Di - Du)

// rotation
#define rot90(b) ((b).yx * vec2(-1,1))

// safe division
#define normz(v) (length(v) == 0. ? v : normalize(v))
#define recip(s) ((s) == 0. ? 1. : 1./(s))

#define ij vec2(i,j)
#define nij normz(ij)
#define lij length(ij)
