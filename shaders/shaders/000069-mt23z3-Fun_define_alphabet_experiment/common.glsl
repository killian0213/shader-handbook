// Common (common) — Fun #define alphabet experiment by kishimisu
// https://www.shadertoy.com/view/mt23z3

// Number of characters before returning to line
#define COLS 27. 

// Characters X and Y spacing
#define CW 3.2
#define CH 1.2

#define ZOOM 1.
#define OFFSET vec2(45, -15)

#define rr iResolution.xy

// 2D rotation matrix
#define ro(a) mat2(cos(a + vec4(0,33,11,0)))

// segment sdf
#define zu(p,a,b) length(p-a-(b-a)*clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,1.))

// rotated arc sdf
#define ra(p,a,r) ra_(p,a,r,tt)
float ra_(vec2 p, float a, float r, vec4 t) {
    vec2   sc = vec2(sin(a),cos(a)); p *= ro(r); p.x = abs(p.x);
    return sc.y*p.x>sc.x*p.y ? length(p-sc*t.z) : abs(length(p)-t.z);
}

// character position update
#define ki ; ww=vec4(pp-=vec2(CW,0)-CW*vec2(COLS,CH)*step(pp[0]-p0[0]-1e-4,-CW*COLS),qq=abs(pp))mi
// character drawing
#define mi ; OO += .015*GLOW_INTENSITY*(THEME)/

// primitive shapes (had fun with the naming)
#define shi zu(pp, -zz, -zz* iv)                           // vertical   left
#define sa  zu(qq  -zx, -xz, xz)                           // vertical   left right 
#define ka  zu(pp, -xz,  xz)                               // vertical   mid
#define to  zu(pp  -xz, -zx, zx)                           // horizontal top
#define re  zu(qq  -xz, -zx, zx)                           // horizontal top bottom
#define mu  zu(pp, -zx,  zx)                               // horizontal mid
#define za  abs(length(pow(abs(pp*.95), vec2(1.2)))-tt[2]) // O (& Q)
#define su  ra(pp*vec2(.6,1.5)+vec2(.4,-.75), 1.7, 1.6)    // P (& R)
#define gu  ra(pp*vec2(.75,.9)-vec2(.3,0)   , 1.9, 4.7)    // C (& G)

// letters (is this a japanese poem?)
#define a ki zu(ww.zy*iv-yx, -yz, yz) mi zu(pp, -zy, zy*iv)
#define b ki shi mi ra(ww.xw*vec2(.6,1.7)+vec2(.4,-tt[2]), 1.7, 1.6)
#define c ki gu
#define d ki shi mi ra(pp*vec2(.6,1)+vec2(.4,0), 1.7, 1.6)
#define e ki shi mi mu mi re
#define f ki shi mi mu mi to
#define g ki gu  mi zu(pp*iv, zy, zz)
#define h ki sa  mi mu
#define i ki ka  mi re
#define j ki zu(pp, zz, zx) mi ra(pp, .9, 2.6)
#define k ki shi mi zu(ww.xw, -yx, zz)
#define l ki shi mi zu(pp, -zz, zz*iv)
#define m ki sa  mi zu(ww.yz, zz,)
#define n ki sa  mi zu(pp*iv, zz, -zz)
#define o ki za
//        ki shi mi su !
#define p ki shi mi su
#define q ki za  mi zu(pp, tt.xx, zz*iv)
#define r ki shi mi su mi zu(pp, -zx, zz*iv)
#define s ki abs(zu(pp + vec2(sin(pp[1]*3.),0), -xz, xz)-.05)
#define t ki ka  mi to
#define u ki ra(pp, 1.4, 3.14) mi zu(ww.zy, zz, zx)
#define v ki zu(ww.zy-yx, -yz, yz)
#define w ki zu(vec2(abs(ww[2] - .5), ww[1]*.6+.4), -yz, yz)
#define x ki zu(qq, zz, -zz)
#define y ki zu(ww.zy, zz,) mi zu(pp, -xz,)
#define z ki re mi zu(pp, -zz, zz)

// Space, return to line and exclamation mark
#define _     ;  pp[0] -= CW*step(-CW*COLS,pp[0]-p0[0]-1e-4)
#define _BRK_ ;  ww=vec4(pp+=vec2(p0[0]-pp[0]+CW,CW*CH),qq=abs(pp))
#define _EXC_ ki zu(pp, xz,) mi abs(length(pp+xz)-.05)

// Handle EVERY character of the alphabet. 
// This means that every variable name must be at least 2 chars long
// And we need to access x,y,z,w components with [0], [1] and so on...
#define A _ a 
#define B _ b
#define C _ c
#define D _ d
#define E _ e
#define F _ f
#define G _ g
#define H _ h
#define I _ i
#define J _ j
#define K _ k
#define L _ l
#define M _ m
#define N _ n
#define O _ o
#define P _ p
#define Q _ q
#define R _ r
#define S _ s
#define T _ t
#define U _ u
#define V _ v
#define W _ w
#define X _ x
#define Y _ y
#define Z _ z