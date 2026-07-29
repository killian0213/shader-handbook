// Common (common) — Marble Marcher: SE by michael0884
// https://www.shadertoy.com/view/3lKyDR

//standard constants
#define TWO_PI 6.28318530718
#define PI 3.14159265359

//rendering settings
#define MAX_STEPS 256
#define MIN_DIST 1e-5
#define MAX_DIST 30.0
#define LIGHT_BRIGHTNESS 2.0
#define FRACTAL_ITER 12
#define FOV 1.0
#define EXPOSURE 1.2
#define ADAPTIVE_PHYSICS_ITERATIONS
//#define FORCE_ALONG_CAMERA

//#define PATH_TRACING
#define BOUNCES 6
//#define DIRECT_LIGHT
#define AMBIENT 2.
#define APERTURE 0.0

//TAA
#define DISOCCLUSION_REJECTION 6e-4
#define CAMERA_MOVEMENT_REJECTION 5e-3

#ifdef PATH_TRACING
    #define REPROJECTION 0.94
#else
    #define REPROJECTION 0.9
#endif

#define AMBIENT_OCCLUSION
#define SHADOWS
#define DIRECT_BRIGHTNESS vec3(6.0)

#define FRACTAL_F0 vec3(0.06)
#define FRACTAL_ROUGHNESS 0.1
#define FRACTAL_TRANSPARENT false
#define FRACTAL_WHITE 0.99

#define DISOCCLUSION_REJECTION_STR 1.0
#ifdef PATH_TRACING
    #define NEIGHBOR_CLAMP_RADIUS 2
#else
    #define NEIGHBOR_CLAMP_RADIUS 2
#endif


//#define AUTO_FOCUS
#define FOCAL_PLANE 0.3


//gameplay defines
#define NUM 16

#define MOUSE_       0
#define CAM_ANGLE_   1
#define CAM_POS_     2
#define PCAM_ANGLE_  3
#define PCAM_POS_    4
#define PRESOLUTION_ 5
#define CAM_VEL_     6
//scene
#define LIGHT_POS_   7
#define MARBLE_POS_  8
#define DMARBLE_POS_ 9
#define MARBLE_VEL_  10
#define TIMER_MODE_  11
#define FLAG_POS_    12

//fractal angles, scale
#define FRAC_PARAM1_ 13
//shift
#define FRAC_PARAM2_ 14
//color
#define FRAC_PARAM3_ 15

#define GAMEMODE_MENU 0
#define GAMEMODE_LEVELS 1
#define GAMEMODE_GAME 3
#define GAMEMODE_FINISH 4
#define GAMEMODE_FREE 5

#define GET_DATA(ch, i) texelFetch(ch, ivec2(i, 0), 0)

float CAM_ANGLE;

//fractal
float iFracScale, iFracAng1, iFracAng2;
vec3 iFracShift, iFracCol;

vec4 iMarblePos, iFlagPos;
vec3 iMarbleVel; vec4 dMarblePos;

vec3 iLightDir;
float isPlanet;

//current and prev camera
vec4 ang, pang; 
vec4 pResolution;
mat3 cam, pcam;
vec3 campos, pcampos;
vec3 camvel;
float radius;

float time;
vec3 timers;
float MODE;


//CAMERA stuff
mat3 get_cam(vec2 ang)
{
    vec3 x_dir = vec3(cos(ang.x)*sin(ang.y), cos(ang.y), sin(ang.x)*sin(ang.y));
    vec3 y_dir = normalize(cross(x_dir, vec3(0,1,0)));
    vec3 z_dir = normalize(cross(y_dir, x_dir));
    return mat3(-x_dir, y_dir, z_dir);
}

//use previous camera matrix and camera position to reproject a point onto previous frame
vec3 reproject(mat3 pcam_mat, vec3 pcam_pos, vec2 iRes, vec3 p)
{
    float td = distance(pcam_pos, p);
    vec3 dir = (p - pcam_pos)/td;
    vec3 screen = vec3(dot(pcam_mat[0],dir),dot(pcam_mat[1],dir),dot(pcam_mat[2],dir));
    return vec3(screen.yz*iRes.y/(FOV*screen.x) + 0.5*iRes.xy, td);
}

//SCENE
void load_scene(sampler2D data, float t, vec2 res)
{
    time = t;
    CAM_ANGLE = 1./res.y;
    vec4 d1 = GET_DATA(data, FRAC_PARAM1_);        
    iFracScale = d1.x; iFracAng1 = d1.y+0.000*sin(t); iFracAng2 = d1.z; //Scale, Angle1, Angle2
    isPlanet = d1.w;
    iFracShift = GET_DATA(data, FRAC_PARAM2_).xyz;                //Offset
    iFracCol =   GET_DATA(data, FRAC_PARAM3_).xyz;                    //Color
    iMarblePos = GET_DATA(data, MARBLE_POS_);                //Marble radius + size
    iFlagPos =  GET_DATA(data, FLAG_POS_);           //Flag radius + size
    vec4 MV_ = GET_DATA(data, MARBLE_VEL_);
    iMarbleVel = MV_.xyz;
    radius = MV_.w;
    
    dMarblePos = GET_DATA(data, DMARBLE_POS_);
    
    vec4 TM_ = GET_DATA(data, TIMER_MODE_);
    timers = TM_.xyz;
    MODE = TM_.w;
    
    //current camera
    ang = GET_DATA(data, CAM_ANGLE_);
    campos = GET_DATA(data, CAM_POS_).xyz;
    camvel = GET_DATA(data, CAM_VEL_).xyz;
    cam = get_cam(ang.xy);
    
    //previous camera
    pang = GET_DATA(data, PCAM_ANGLE_);
    pcampos = GET_DATA(data, PCAM_POS_).xyz;
    pcam = get_cam(pang.xy);
    
    iLightDir = normalize(GET_DATA(data, LIGHT_POS_).xyz);
    
    pResolution = GET_DATA(data, PRESOLUTION_);
}

//marble physics
const float ground_force = 0.008f;
const float air_force = 0.004f;
const float ground_friction = 0.99f;
const float air_friction = 0.995f;
const float orbit_speed = 0.005f;
const int max_marches = 10;
const int num_phys_steps = 6;
const float marble_bounce = 1.2f;
const float gravity = 0.005f;

//##########################################
//   Space folding
//##########################################
void planeFold(inout vec3 z, vec3 n, float d) {
	z.xyz -= 2.0 * min(0.0, dot(z.xyz, n) - d) * n;
}
void sierpinskiFold(inout vec3 z) {
	z.xy -= min(z.x + z.y, 0.0);
	z.xz -= min(z.x + z.z, 0.0);
	z.yz -= min(z.y + z.z, 0.0);
}
vec2 mp = vec2(-1.,1.);
void mengerFold(inout vec3 z) 
{
	z.xy += min(z.x - z.y, 0.0)*mp;
	z.xz += min(z.x - z.z, 0.0)*mp;
	z.yz += min(z.y - z.z, 0.0)*mp;
}
void boxFold(inout vec3 z, vec3 r) {
	z.xyz = clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}
//##########################################
//   Primitive DEs
//##########################################
float de_sphere(vec3 p, float r) {
	return (length(p.xyz) - r);
}
float de_box(vec3 p, vec3 s) {
	vec3 a = abs(p.xyz) - s;
	return (min(max(max(a.x, a.y), a.z), 0.0) + length(max(a, 0.0)));
}
float de_tetrahedron(vec3 p, float r) {
	float md = max(max(-p.x - p.y - p.z, p.x + p.y - p.z),
				max(-p.x + p.y + p.z, p.x - p.y + p.z));
	return (md - r) / sqrt(3.0);
}
float de_capsule(vec3 p, float h, float r) {
	p.y -= clamp(p.y, -h, h);
	return (length(p.xyz) - r);
}
//##########################################
//   Main DEs
//##########################################

vec2 opUnion(vec2 a, vec2 b)
{
    return (a.x < b.x)?a:b;
}

vec4 fractal(vec3 p)
{
    vec2 a1 = vec2(sin(iFracAng1), cos(iFracAng1));
    vec2 a2 = vec2(sin(iFracAng2), cos(iFracAng2));
	mat2 rmZ = mat2(a1.y, a1.x, -a1.x, a1.y);
	mat2 rmX = mat2(a2.y, a2.x, -a2.x, a2.y);
    float scale = 1.0;
    vec3 orbit = vec3(0.); 
    for (int i = 0; i < FRACTAL_ITER; ++i) {
		p.xyz = abs(p.xyz);
		p.xy *= rmZ;
		mengerFold(p);
		p.yz *= rmX;
		p *= iFracScale; scale*=iFracScale;
		p.xyz += iFracShift;
        orbit = max(orbit, p.xyz*iFracCol);
	}
    return vec4(clamp(orbit, 0., 1.), de_box(p, vec3(6.0))/scale);
}

vec2 de_fractal(vec3 p)
{
    return vec2(fractal(p).w, 0);
}

vec3 color_fractal(vec3 p)
{
    return fractal(p).xyz;
}

vec2 de_marble(vec3 p) 
{
	float de = de_sphere(p - iMarblePos.xyz, iMarblePos.w*0.98);
    return vec2(de, 1);
}

vec2 de_flag(vec3 p) 
{
	vec3 f_pos = iFlagPos.xyz + vec3(1.5, 4, 0)*iFlagPos.w;
	vec3 p_s = p/iFlagPos.w;
	vec3 d_pos = p - f_pos;
	vec3 caps_pos = p - (iFlagPos.xyz + vec3(0, iFlagPos.w*2.4, 0));
	//animated flag
	float speed = 14.0;
	float oscillation = sin(8.0*p_s.x - 1.0*p_s.y - speed*time) +
                    0.4*sin(11.0*p_s.x + 2.0*p_s.y - 1.2*speed*time) + 
                    0.15*sin(20.0*p_s.x - 5.0*p_s.y - 1.4*speed*time);
	//scale the flag displacement amplitude by the distance from the flagpole
	vec2 flag = vec2(0.6*de_box(d_pos + caps_pos.x*vec3(0,(0.02+ caps_pos.x* 0.5+0.01*oscillation),0.04*oscillation),
                        vec3(1.5, 0.8, 0.005)*iFlagPos.w), 2);
	vec2 capsule = vec2(de_capsule(caps_pos, iFlagPos.w*2.4, iFlagPos.w*0.05), 3);
    
	return opUnion(flag, capsule);
}

vec2 scene(vec3 p)
{
    vec2 fractal = de_fractal(p);
    vec2 marble = de_marble(p);
    vec2 flag = de_flag(p);
    return opUnion(opUnion(fractal, marble),flag);
}

vec4 calcNormal(vec3 p, float dx) {
	const vec3 k = vec3(1,-1,0);
	return  0.25*(k.xyyx*scene(p + k.xyy*dx).x +
			      k.yyxx*scene(p + k.yyx*dx).x +
			      k.yxyx*scene(p + k.yxy*dx).x +
			      k.xxxx*scene(p + k.xxx*dx).x)/vec4(dx,dx,dx,1.0);
}

vec3 closestPoint(vec3 p) {
	const vec3 k = vec3(1,-1,0);
    const float dx = 1e-5;
    vec4 n = 0.25*(k.xyyx*fractal(p + k.xyy*dx).w +
			       k.yyxx*fractal(p + k.yyx*dx).w +
			       k.yxyx*fractal(p + k.yxy*dx).w +
			       k.xxxx*fractal(p + k.xxx*dx).w); 
	return p - normalize(n.xyz)*n.w;
}

struct material
{
    vec3 color;
    vec3 emission;
    vec3 normal;
    vec3 cpoint; //closest point
    vec3 velocity;
    float roughness;
    bool transparent;
    vec3 F0;
    float inside;
};

material getMaterial(inout vec4 p)
{
    material cur;
    float mindistance = 0.75*max(CAM_ANGLE*p.w,MIN_DIST);
    cur.normal = normalize(calcNormal(p.xyz, mindistance).xyz);
    vec2 scene = scene(p.xyz);
    cur.inside = sign(scene.x);
    vec3 dsurface = cur.normal*scene.x;
    cur.cpoint = p.xyz - dsurface;
    
    //move away from the surface
    p.xyz += cur.inside*cur.normal*mindistance;
    
    int id = int(scene.y);
    cur.F0 = vec3(0.15);
    cur.transparent = false; 
    cur.emission = vec3(0.0);
    switch(id)
    {
    case 0:
        cur.color = mix(vec3(1.0),color_fractal(cur.cpoint),FRACTAL_WHITE);
        cur.F0 = FRACTAL_F0;
        cur.roughness = FRACTAL_ROUGHNESS;
        cur.transparent = FRACTAL_TRANSPARENT; 
        cur.velocity = vec3(0.);//TODO with animations
        cur.emission = vec3(0.0)*exp(-300.*clamp(pow(abs(length( cur.color - vec3(1.) )),2.),0.,1.));
        break;
    case 1:
        cur.color = vec3(1.);
        cur.roughness = 0.011;
        cur.F0 = vec3(0.03);
        cur.velocity = dMarblePos.xyz;
        cur.emission = vec3(0.0);
        cur.transparent = true;
        break;
    case 2:
        cur.color = vec3(1.000,0.078,0.078);
         cur.transparent = true;
        cur.roughness = 0.02;
        cur.velocity = vec3(0.); //TODO
        break;
    case 3:
        cur.color = vec3(1.000,0.867,0.000);
        cur.roughness = 0.5;
        cur.velocity = vec3(0.);
        break;
    default:
        cur.color = vec3(1.000,1.000,1.000);
        cur.roughness = 0.5;
        cur.velocity = vec3(0.);
        break;
    }
    return cur;
}

bool trace(inout vec4 ro, vec3 rd)
{
    for(int i = 0; i < MAX_STEPS; i++)
    {
        float de = abs(scene(ro.xyz).x); 
        float md = max(CAM_ANGLE*ro.w,MIN_DIST);
        de -= step(de, md)*md;
        ro += vec4(rd,1.)*de; 
        if(de < md) return true;
        if(ro.w > MAX_DIST) return false;
    }
    return true;
}


//internal RNG state 
uvec4 s0, s1; 
ivec2 pixel;

void rng_initialize(vec2 p, int frame)
{
    pixel = ivec2(p);

    //white noise seed
    s0 = uvec4(p, uint(frame), uint(p.x) + uint(p.y));
    
    //blue noise seed
    s1 = uvec4(frame, frame*15843, frame*31 + 4566, frame*2345 + 58585);
}

// https://www.pcg-random.org/
void pcg4d(inout uvec4 v)
{
	v = v * 1664525u + 1013904223u;
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    v = v ^ (v>>16u);
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
}

float rand()
{
    pcg4d(s0); return float(s0.x)/float(0xffffffffu);
}

vec2 rand2()
{
    pcg4d(s0); return vec2(s0.xy)/float(0xffffffffu);
}

vec3 rand3()
{
    pcg4d(s0); return vec3(s0.xyz)/float(0xffffffffu);
}

vec4 rand4()
{
    pcg4d(s0); return vec4(s0)/float(0xffffffffu);
}

//random blue noise sampling pos
ivec2 shift2()
{
    pcg4d(s1); 
    return (pixel + ivec2(s1.xy%0x0fffffffu))%1024;
}

vec2 rand2t()
{
    pcg4d(s1); return vec2(s1.xy)/float(0xffffffffu);
}

//uniformly spherically distributed
vec3 udir(vec2 rng)
{
    vec2 r = vec2(2.*PI*rng.x, acos(2.*rng.y-1.));
    vec2 c = cos(r), s = sin(r);
    return vec3(c.x*s.y, s.x*s.y, c.y);
}

// halton low discrepancy sequence, from https://www.shadertoy.com/view/wdXSW8
vec2 halton(int index)
{
    const vec2 coprimes = vec2(2.0f, 3.0f);
    vec2 s = vec2(index, index);
	vec4 a = vec4(1,1,0,0);
    while (s.x > 0. && s.y > 0.)
    {
        a.xy = a.xy/coprimes;
        a.zw += a.xy*mod(s, coprimes);
        s = floor(s/coprimes);
    }
    return a.zw;
}

float HenyeyGreenstein(float g, float costh)
{
    return (1.0 - g * g) / (4.0 * PI * pow(1.0 + g * g - 2.0 * g * costh, 3.0/2.0));
}

 
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

mat2 rot(float ang)
{
    return mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
}

//Keyboard constants
const int KEY_SPACE = 32;
const int KEY_BSPACE = 8;
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;
const int KEY_A     = 65;
const int KEY_B     = 66;
const int KEY_C     = 67;
const int KEY_D     = 68;
const int KEY_E     = 69;
const int KEY_F     = 70;
const int KEY_G     = 71;
const int KEY_H     = 72;
const int KEY_I     = 73;
const int KEY_J     = 74;
const int KEY_K     = 75;
const int KEY_L     = 76;
const int KEY_M     = 77;
const int KEY_N     = 78;
const int KEY_O     = 79;
const int KEY_P     = 80;
const int KEY_Q     = 81;
const int KEY_R     = 82;
const int KEY_S     = 83;
const int KEY_T     = 84;
const int KEY_U     = 85;
const int KEY_V     = 86;
const int KEY_W     = 87;
const int KEY_X     = 88;
const int KEY_Y     = 89;
const int KEY_Z     = 90;

//from https://www.shadertoy.com/view/XsSXDy
vec4 powers( float x ) { return vec4(x*x*x, x*x, x, 1.0); }

const vec4 ca = vec4(   3.0,  -5.0,   0.0,  2.0 ) /  2.0;
const vec4 cb = vec4(  -1.0,   5.0,  -8.0,  4.0 ) /  2.0;

vec4 spline( float x, vec4 c0, vec4 c1, vec4 c2, vec4 c3 )
{
    // We could expand the powers and build a matrix instead (twice as many coefficients
    // would need to be stored, but it could be faster.
    return c0 * dot( cb, powers(x + 1.0)) + 
           c1 * dot( ca, powers(x      )) +
           c2 * dot( ca, powers(1.0 - x)) +
           c3 * dot( cb, powers(2.0 - x));
}


#define SAM(a,b)  texture(tex, (i+vec2(float(a),float(b))+0.5)/res, -99.0)

vec4 texture_Bicubic( sampler2D tex, vec2 t )
{
    vec2 res = vec2(textureSize(tex,0));
    vec2 p = res*t - 0.5;
    vec2 f = fract(p);
    vec2 i = floor(p);

    return spline( f.y, spline( f.x, SAM(-1,-1), SAM( 0,-1), SAM( 1,-1), SAM( 2,-1)),
                        spline( f.x, SAM(-1, 0), SAM( 0, 0), SAM( 1, 0), SAM( 2, 0)),
                        spline( f.x, SAM(-1, 1), SAM( 0, 1), SAM( 1, 1), SAM( 2, 1)),
                        spline( f.x, SAM(-1, 2), SAM( 0, 2), SAM( 1, 2), SAM( 2, 2)));
}


uvec2 unpack_uint2x(uint x)
{
    return uvec2(x%0x00010000u,x/0x00010000u);
}

uint pack_uint2x(uvec2 x)
{
    return x.x + x.y*0x00010000u;
}

vec2 decode(float data)
{
    return vec2(unpack_uint2x(floatBitsToUint(data)))/100.;
}

float encode(vec2 data)
{
    return uintBitsToFloat(pack_uint2x(uvec2(data*100.0)));
}

//simplified ttg's GLSL character printing library
//https://www.shadertoy.com/view/Wd2SDt
const struct CHARS {
  uint
    _,   em,  dq,  ha,  ds,  mo,  am,  sq,  lp,  rp,  as,  pl,  cm,  hm,  pe,  sl,
    _0,  _1,  _2,  _3,  _4,  _5,  _6,  _7,  _8,  _9,  co,  sc,  lt,  eq,  gt,  qm,
    at,   A,   B,   C,   D,   E,   F,   G,   H,   I,   J,   K,   L,   M,   N,   O,
     P,   Q,   R,   S,   T,   U,   V,   W,   X,   Y,   Z,  lb,  bs,  rb,  up,  un,
    bt,   a,   b,   c,   d,   e,   f,   g,   h,   i,   j,   k,   l,   m,   n,   o,
     p,   q,   r,   s,   t,   u,   v,   w,   x,   y,   z,  lc,  ba,  rc,  ti, _U0,
   alp, bet, gam, del, eps, the, lam,  mu,  xi,  pi, rho, sig, tau, phi, psi, ome,
   Gam, Del, The, Lam,  Pi, Sig, Phi, Psi, Ome, inf,flor,ring,intg,pdrv, nab,sqrt,
   _U1, iem, cen, pou, cur, yen, bba, sec, dia, cop, fem, lda, not, _U2, reg, mac,
   deg, pms, su2, su3, acu, mic, pil, mid, ced, su1, mas, rda, v14, v12, v34, iqm,
    AG,  AA,  AC,  AT,  AD,  AR,  AE,  CC,  EG,  EA,  EC,  ED,  IG,  IA,  IC,  ID,
   Eth,  NT,  OG,  OA,  OC,  OT,  OD, mul,  OS,  UG,  UA,  UC,  UD,  YA, Tho, Sha,
    aG,  aA,  aC,  aT,  aD,  aR,  ae,  cC,  eG,  eA,  eC,  eD,  iG,  iA,  iC,  iD,
   eth,  nT,  oG,  oA,  oC,  oT,  oD, div,  oS,  uG,  uA,  uC,  uD,  yA, yho,  yD,  
  _nul;
} CHAR = CHARS(
  0x20u,0x21u,0x22u,0x23u,0x24u,0x25u,0x26u,0x27u,0x28u,0x29u,0x2au,0x2bu,0x2cu,0x2du,0x2eu,0x2fu,
  0x30u,0x31u,0x32u,0x33u,0x34u,0x35u,0x36u,0x37u,0x38u,0x39u,0x3au,0x3bu,0x3cu,0x3du,0x3eu,0x3fu,
  0x40u,0x41u,0x42u,0x43u,0x44u,0x45u,0x46u,0x47u,0x48u,0x49u,0x4au,0x4bu,0x4cu,0x4du,0x4eu,0x4fu,
  0x50u,0x51u,0x52u,0x53u,0x54u,0x55u,0x56u,0x57u,0x58u,0x59u,0x5au,0x5bu,0x5cu,0x5du,0x5eu,0x5fu,
  0x60u,0x61u,0x62u,0x63u,0x64u,0x65u,0x66u,0x67u,0x68u,0x69u,0x6au,0x6bu,0x6cu,0x6du,0x6eu,0x6fu,
  0x70u,0x71u,0x72u,0x73u,0x74u,0x75u,0x76u,0x77u,0x78u,0x79u,0x7au,0x7bu,0x7cu,0x7du,0x7eu,0x7fu,
  0x80u,0x81u,0x82u,0x83u,0x84u,0x85u,0x86u,0x87u,0x88u,0x89u,0x8au,0x8bu,0x8cu,0x8du,0x8eu,0x8fu,
  0x90u,0x91u,0x92u,0x93u,0x94u,0x95u,0x96u,0x97u,0x98u,0x99u,0x9au,0x9bu,0x9cu,0x9du,0x9eu,0x9fu,
  0xa0u,0xa1u,0xa2u,0xa3u,0xa4u,0xa5u,0xa6u,0xa7u,0xa8u,0xa9u,0xaau,0xabu,0xacu,0xadu,0xaeu,0xafu,
  0xb0u,0xb1u,0xb2u,0xb3u,0xb4u,0xb5u,0xb6u,0xb7u,0xb8u,0xb9u,0xbau,0xbbu,0xbcu,0xbdu,0xbeu,0xbfu,
  0xc0u,0xc1u,0xc2u,0xc3u,0xc4u,0xc5u,0xc6u,0xc7u,0xc8u,0xc9u,0xcau,0xcbu,0xccu,0xcdu,0xceu,0xcfu,
  0xd0u,0xd1u,0xd2u,0xd3u,0xd4u,0xd5u,0xd6u,0xd7u,0xd8u,0xd9u,0xdau,0xdbu,0xdcu,0xddu,0xdeu,0xdfu,
  0xe0u,0xe1u,0xe2u,0xe3u,0xe4u,0xe5u,0xe6u,0xe7u,0xe8u,0xe9u,0xeau,0xebu,0xecu,0xedu,0xeeu,0xefu,
  0xf0u,0xf1u,0xf2u,0xf3u,0xf4u,0xf5u,0xf6u,0xf7u,0xf8u,0xf9u,0xfau,0xfbu,0xfcu,0xfdu,0xfeu,0xffu,
  0x7fu);

#define C(c) CHAR.c
#define NUM2CHAR(x) (CHAR._0 + uint(x)%10u)
#define STRLENGTH 24
#define STRING(c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23) \
     C(c0),C(c1),C(c2),C(c3),C(c4),C(c5),C(c6),C(c7),C(c8),C(c9),C(c10),C(c11), \
     C(c12),C(c13),C(c14),C(c15),C(c16),C(c17),C(c18),C(c19),C(c20),C(c21),C(c22),C(c23)


struct Button
{
    vec2 size;
    int string;
};

#define MAIN_POS vec2(0.03, 0.30)*iResolution.xy
#define LEVELS_POS vec2(0.03, 0.03)*iResolution.xy

#define FONT_SCALE min(iResolution.x,iResolution.y)/400.0

const Button[] Buttons = Button[](
//main menu
Button(vec2(35.0, 300.0), 6), //0
Button(vec2(35.0, 300.0), 7),  //1

//levels
Button(vec2(30.0, 300.0), 8), //2
Button(vec2(26.0, 300.0), 9),  //3
Button(vec2(26.0, 300.0), 10), //4
Button(vec2(26.0, 300.0), 11), //5
Button(vec2(26.0, 300.0), 12), //6
Button(vec2(26.0, 300.0), 13), //7
Button(vec2(26.0, 300.0), 14), //8
Button(vec2(26.0, 300.0), 15), //9
Button(vec2(26.0, 300.0), 16), //10
Button(vec2(26.0, 300.0), 17), //11
Button(vec2(26.0, 300.0), 18), //12
Button(vec2(26.0, 300.0), 19) //13
);
