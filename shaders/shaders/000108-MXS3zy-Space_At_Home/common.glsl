// Common (common) — Space At Home by lz
// https://www.shadertoy.com/view/MXS3zy

/*
    Space at home.
    Copyright © 2024 Leonid Zaides
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#define MAX_DISTANCE 1000.
#define FAR 300.0
#define MAX_ITER 164.
#define MAX_SH_ITER 64.

#define CROSS_SECTION_FACTOR 5.

#define T_EPS 0.0001
#define TS_EPS 0.001

#define N_EPS 0.0001
#define NS_EPS 0.01

#define RAD_45 0.785398163

#define PI 3.14159265
#define PI2 6.2831853

#define GEOM_BOUNDING_CIRCLE 75.
#define GEOM_BOUNDING_CIRCLE_SQR 5625.
#define GEOM_BOUNDING_SHADOW_CIRCLE 100.
#define GEOM_BOUNDING_SHADOW_CIRCLE_SQR 10000.
#define FLOOR_BOUNDING_CIRCLE_SQR 28900.
#define FLOOR_BOUNDING_CIRCLE 160.
#define FLOOR_LEVEL -29.5

//#define DEBUG_HIT
#define DEBUG_CIRCULAR_MOTION
//#define ANIM_TIME (iMouse.x/6.)
#define ANIM_TIME iTime
#define DOWNSAMPLE_SHADOWS

#define ROT2(_alpha) mat2(cos(_alpha), sin(_alpha), -sin(_alpha), cos(_alpha))
#define Ryz(_alpha) mat4(1., 0., 0., 0., \
                         0., cos(_alpha), sin(_alpha), 0., \
                         0., -sin(_alpha), cos(_alpha), 0., \
                         0., 0., 0., 1.)
                         
#define CAMERA_SETUP(_uv) vec3 o = TF3(ORIG_SEQ).xyz;                   \
                     vec4 trg = TF3(LOOKAT_SEQ);                   \
                     vec3 d = normalize(vec3((_uv + half_pixel)*tan(trg.w), -1.)); \
                     d = lookAt(o, d, trg.xyz);

// packing closed unit interval values to uint
#define PACK_CUI_VALUES

#define PACK_CUI3_TO_UINT(_a, _b, _c)                \
        uint packed_uint = uint(_a * 255.);          \
        packed_uint += (uint(_b * 255.) << 8);       \
        packed_uint += (uint(_c * 127.) << 16);
                
#define UNPACK_UINT_TO_CUI3(_packed_val)                   \
        uint packed_uint = uint(_packed_val);              \
        vec3 unpacked_cui3;                                \
        unpacked_cui3.x = float(packed_uint % 256u) / 255.; \
        packed_uint /= 256u;                                \
        unpacked_cui3.y = float(packed_uint % 256u) / 255.; \
        packed_uint /= 256u;                                \
        unpacked_cui3.z = float(packed_uint % 128u) / 127.;

#define Rxz(_alpha) mat4(cos(_alpha), 0., sin(_alpha), 0., 0., 1., 0., 0., -sin(_alpha), 0., cos(_alpha), 0., 0., 0., 0., 1.)


#define ANIM_T(_t, _e, _p) (smoothstep(_p - _e, _p, _t) - smoothstep(_p, _p + _e, _t))
#define ANIM_T_CF(_t, _p, _e0, _e1, _cf0, _cf1) (_cf0 * smoothstep(_p - _e0, _p, _t) - _cf1 * smoothstep(_p, _p + _e1, _t))
#define PULSE_T(_t, _e, _pa, _pb) (smoothstep(_pa - _e, _pa, _t) - smoothstep(_pb, _pb + _e, _t))
#define ASYM_PULSE_T(_t, _ea, _pa, _eb, _pb) (smoothstep(_pa - _ea, _pa, _t) - smoothstep(_pb, _pb + _eb, _t))

#define ANIM_SEQ 150.

// aspect ratios
#define WIDE_SCREEN_AR 0.5625
#define ULTRA_WIDE_SCREEN_AR 0.428571
#define SUPER_WIDE_SCREEN_AR 0.28125
#define ASPECT_RATIO WIDE_SCREEN_AR

//

#define TRACE_NO_FLAG 0
#define TRACE_FLOOR_FLAG 1

#define TRACE_TABLE_FRAME_FLAG 2
#define TRACE_TABLE_TOP_FLAG 4
// sum of previous two
#define TRACE_TABLE_FLAG 6

#define TRACE_CHAIR_BASE_FLAG 8
#define TRACE_CHAIR_BCK_LEG_FLAG 16
#define TRACE_CHAIR_FRNT_LEG_FLAG 32
#define TRACE_CHAIR_BACK_FLAG 64
#define TRACE_CHAIR_FRAME_FLAG 128
#define TRACE_CHAIR_CUSHION_FLAG 256
// sum of previous six
#define TRACE_CHAIRS_FLAG 504

#define TRACE_LAPTOP_BASE_FLAG 512
#define TRACE_LAPTOP_SCREEN_FLAG 1024
// sum of prevoius two
#define TRACE_LAPTOP_FLAG 1536

#define TRACE_ALL TRACE_FLOOR_FLAG | TRACE_TABLE_FLAG | TRACE_CHAIRS_FLAG | TRACE_LAPTOP_FLAG
#define TRACE_NO_FLOOR TRACE_TABLE_FLAG | TRACE_CHAIRS_FLAG | TRACE_LAPTOP_FLAG
#define TRACE_TABLE_LAPTOP TRACE_TABLE_FLAG | TRACE_LAPTOP_FLAG
#define TRACE_CHAIR_UPPER TRACE_CHAIR_BACK_FLAG | TRACE_CHAIR_FRAME_FLAG | TRACE_CHAIR_BCK_LEG_FLAG
#define TRACE_CHAIR_UPPER_W_CUSHION TRACE_CHAIR_UPPER | TRACE_CHAIR_CUSHION_FLAG

// colors

#define N_CHAIRS 5

#define DEFAULT_MTL 0
#define FLOOR_MTL 1
#define TABLE_FRAME_MTL 2
#define TABLE_TOP_MTL 3
#define CHAIR_BASE_MTL 4
#define CHAIR_BCK_LEG_MTL 5
#define CHAIR_FRNT_LEG_MTL 6
#define CHAIR_BACK_MTL 7
#define CHAIR_FRAME_MTL 8
#define CHAIR_CUSHION_MTL 9
#define LAPTOP_BASE_MTL 10
#define LAPTOP_SCREEN_MTL 11

#define LAPTOP_MTL LAPTOP_BASE_MTL

#define is_metal_mtl(_mtl) (_mtl == CHAIR_FRAME_MTL || _mtl == TABLE_FRAME_MTL)

#define TF0(crd) texelFetch(iChannel0, crd, 0)
#define TF1(crd) texelFetch(iChannel1, crd, 0)
#define TF2(crd) texelFetch(iChannel2, crd, 0)
#define TF3(crd) texelFetch(iChannel3, crd, 0)
#define TF(ch, crd) texelFetch(ch, crd, 0)

// CONTROL ZONE - CTRL_ZONE first rows
#define CTRL_ZONE 50
#define FPS_DATA ivec2(0,0)
#define RES_DATA ivec2(1,0)

#define CAMERA_SETUP_ROW 3
#define ORIG_SEQ_ROW 1
#define ORIG_SEQ ivec2(0, ORIG_SEQ_ROW)
#define ORIG_SEQ_1 ivec2(1, ORIG_SEQ_ROW)
#define ORIG_SEQ_2 ivec2(4, ORIG_SEQ_ROW)
#define ORIG_SEQ_3 ivec2(7, ORIG_SEQ_ROW)

#define LOOKAT_SEQ ivec2(0, 3)

// Lights
#define N_LIGHTS 2
#define LIGHT_0 4
#define LIGHT_1 5

// light position/direction and type (directional/point)
#define LIGHT_GEO 0
// rgb, intensity
#define LIGHT_PROP 1

#define LAPTOP_H_DIMS ivec2(0, 10)

#define LAPTOP_BASE_TRF_0 ivec2(0, 11)
#define LAPTOP_BASE_TRF_1 ivec2(1, 11)
#define LAPTOP_BASE_TRF_2 ivec2(2, 11)
#define LAPTOP_BASE_TRF_3 ivec2(3, 11)

#define LAPTOP_SCRN_TRF_0 ivec2(4, 11)
#define LAPTOP_SCRN_TRF_1 ivec2(5, 11)
#define LAPTOP_SCRN_TRF_2 ivec2(6, 11)
#define LAPTOP_SCRN_TRF_3 ivec2(7, 11)

#define LAPTOP_KEY_ANIM ivec2(0, 12)

#define CHAIR_ROT 13

#define GEOM_SHADOW_MAP 20
// not used
#define GEOM_NORM_MAP 21 
#define GEOM_AO_MAP 22

// global variables
// global casting direction accessible from 'everywhere'
vec3 g_dir;
mat4 lpTrf = mat4(1.);
mat4 scrTrf = mat4(1.);
float scrRndSide = 1.;
const float bvh_margin = 1.;

int getNormMap(in int _mtl) { 
    int mtl = (_mtl >= LAPTOP_MTL && _mtl != LAPTOP_SCREEN_MTL) ? LAPTOP_MTL : _mtl;
    return (1 << (mtl - 1)); 
}
mat2 rot2D(in float _a) {
    return mat2(cos(_a), sin(_a), -sin(_a), cos(_a));
} 

mat3 rotY(in float _a) {
    return mat3(cos(_a),  0., sin(_a),
                0.,       1., 0.,
                -sin(_a), 0., cos(_a));
}

mat3 rotX(in float _a) {
    return mat3(1.,       0., 0.,
                0., cos(_a),  sin(_a),
                0., -sin(_a), cos(_a));
}

const float a1 = 20.;
const float a2 = 80.;
const float a3 = 107.;
const float a4 = 112.;
const float a5 = 130.;
const float a6 = ANIM_SEQ;
    
vec3 getCameraTarget(in float _t) {
    float atime = _t;

    vec3 target = vec3(0., 5., 0.);
    float cf;
    if (atime < a1) {
        cf = atime / a1;
        target = mix(target, vec3(11.6, 6.77, 9.13), smoothstep(0.4, 0.6, cf));
    }
    else if (atime < a2) {
        cf = (atime - a1) / (a2 - a1);
        target = mix(vec3(11.6, 6.77, 9.13), vec3(-7., -11., -36.), 
            smoothstep(0.15, 0.21, cf));
        target = mix(target, vec3(-21., -3.3, 43.4), smoothstep(0.34, 0.39, cf));
        vec3 tanchor = vec3(10., 0., 0.);
        float ta = -cf * PI2 * 8.;
        tanchor.xz *= ROT2(ta);
        target = mix(target, vec3(-67., -1., -3.5) + tanchor, smoothstep(0.4, 0.43, cf));
        
        target.y = mix(target.y, -30., PULSE_T(cf, 0.03, 0.57, 0.6));
        target.xz = mix(target.xz, vec2(-16., -49.), smoothstep(0.62, 0.64, cf));
        target = mix(target, vec3(0., -12., -19.), smoothstep(0.75, 0.8, cf));
        target = mix(target, vec3(-22.7, -14., -31.8), smoothstep(0.8, 0.83, cf));
        target = mix(target, vec3(-0., -20., 10.37), smoothstep(0.84, 0.9, cf));
        target = mix(target, vec3(0., -10., 0.), smoothstep(0.9, 0.95, cf));
    }
    else if (atime < a3) {
        cf = (atime - a2) / (a3 - a2);
        target = vec3(0., -10., 0.);
        float circ_targ = PULSE_T(cf, 0.1, 0.2, 0.6);
        float circ_r = 60.*(cf - 0.2)/0.6;
        target.xz = mix(target.xz, circ_r * vec2(cos(cf*PI2*4.),sin(cf*PI2*4.)), circ_targ);
        target.y = target.y + ANIM_T_CF(cf, 0.4, 0.3, 0.3, 30., 10.);
        target = mix(target, vec3(0., 5., 0.), smoothstep(0.75, 0.85, cf));
    }
    else if (atime < a4) {
        cf = (atime - a3) / (a4 - a3);
        target = mix(vec3(0., 5., 0.), vec3(12., 8., 7.), smoothstep(0., 1., sqrt(cf)));
    }
    else if (atime < a5) {
        cf = (atime - a4) / (a5 - a4);
        target = vec3(12., 8., 7.);
        target.x += cos(cf * PI2) * smoothstep(0., 1., cf);
        target.z += 0.3*cos(cf * PI * 0.5) * smoothstep(0., 1., cf);
        target.y += 0.5*sin(cf * PI2 * 0.5) * smoothstep(0., 1., cf);
    }
    else if (atime < a6) {
        cf = (atime - a5) / (a6 - a5);
        target = vec3(13., 8., 7.);
    }
    else { // sequence of stills
        int sti_time = int(mod(atime, 60.) / 10.);
        target = mix(target, vec3(0., 5., 0.), float(sti_time == 0));
        target = mix(target, vec3(-14.7, -12.3, -29.44), float(sti_time == 1));
        target = mix(target, vec3(13.21, 7., 3.75), float(sti_time == 2));
        target = mix(target, vec3(-0.3, -28., 25.), float(sti_time == 3));
        target = mix(target, vec3(20.51, 4., 1.04), float(sti_time == 4));
        target = mix(target, vec3(37., -22., -42.), float(sti_time == 5));
    }
    return target;
}

vec3 getCameraPosition(in float _t) {
    float dist = 90.;
    vec3 p;
    p.xz = dist * vec2(-1., 0.);
    p.y = 70.;
    float cf;
    float atime = _t;

    vec2 ranchor = vec2(0.);
    if (_t < a1) {
        cf = atime / a1;
        dist = 120. - cf * 40.;
        p.xz = ROT2(cf * PI2) * vec2(dist, 0.);
        p.y = 90. - ANIM_T_CF(cf, 0.5, 0.5, 0.45, 50., 30.);
    }
    else if (atime < a2) {
        cf = (atime - a1) / (a2 - a1);
        ranchor = mix(ranchor, vec2(30., -50.), ANIM_T(cf, 0.2, 0.2));
        ranchor = mix(ranchor, vec2(200., 70.), ASYM_PULSE_T(cf, 0.2, 0.7, 0.1, 0.71));
        dist = 80.;
        dist = mix(dist, 80., ANIM_T(cf, 0.2, 0.2));
        dist = mix(dist, 120., ANIM_T(cf, 0.1, 0.75));
        dist = mix(dist, 60., smoothstep(0.75, 0.78, cf));
        dist = mix(dist, 70., smoothstep(0.78, 0.82, cf));
        //dist = mix(dist, 30., ANIM_T(cf, 0.05, 0.88));
        p.xz = ROT2(cf * PI2 * 3.) * (vec2(dist, 0.) - ranchor);
        p.y = mix(70., 0., smoothstep(0., 0.3, cf));
        p.y = mix(p.y, -20., smoothstep(0.6, 0.7, cf));
        p.y = mix(p.y, 5., smoothstep(0.85, 0.9, cf));
    }
    else if (atime < a3) {
        cf = (atime - a2) / (a3 - a2);
        float rcf = 1. - (1.-cf)*(1.-cf);
        dist = 70.;
        dist = mix(dist, 100., smoothstep(0.0, 0.2, cf));
        dist = mix(dist, 32., smoothstep(0.6, 0.9, cf));
        ranchor = 10.*vec2(cos(cf*PI2), sin(cf*PI2)) * PULSE_T(rcf, 0.1, 0.2, 0.8);
        p.xz = ROT2(rcf * PI2 * 2.) * vec2(dist, 0.) - ranchor;
        p.y = mix(5., 40., smoothstep(0.0, 0.2, cf));
        //p.y = mix(p.y, sin(cf*PI2*2.)*5., PULSE_T(cf, 0.1, 0.3, 0.7));
        p.y = mix(p.y, 10., smoothstep(0.8, 0.9, rcf));
    }
    else if (atime < a4) {
        cf = (atime - a3) / (a4 - a3);
        cf = smoothstep(0., 1., cf);
        dist = 32.;
        dist = mix(dist, 24., smoothstep(0.2, 1., cf));
        p.xz = ROT2(cf * PI2 * 0.2) * dist * vec2(1., 0.);
        p.y = mix(10., 18., smoothstep(0., 1., cf));
    }
    else if (atime < a5) {
        cf = (atime - a4) / (a5 - a4);
        dist = 24. - ANIM_T_CF(cf, 0.7, 0.7, 0.3, 14., 10.);
        p.xz = dist * vec2(0.309017, 0.951057);
        p.y = mix(18., 24., ANIM_T(cf, 0.5, 0.5));
    }
    else if (atime < a6) {
        cf = (atime - a5) / (a6 - a5);
        p.xz = 20. * vec2(0.309017, 0.951057);
        p.xz = mix(p.xz, vec2(-20., 10.951057), smoothstep(0.1, 0.9, cf)); 
        p.y = 18.;
    }
    else {
        int sti_time = int(mod(atime, 60.) / 10.);
        p = mix(p, vec3(20., 48., 130.), float(sti_time == 0));
        p = mix(p, vec3(-120., 35., 20.), float(sti_time == 1));
        p = mix(p, vec3(23.21, 17., 23.75), float(sti_time == 2));
        p = mix(p, vec3(20., -25., -65.), float(sti_time == 3));
        p = mix(p, vec3(37.93, 9., -2.), float(sti_time == 4));
        p = mix(p, vec3(57., -15., -62.), float(sti_time == 5));
    }
    
    return p;
}

// A lot of basis features were taken from:
// iq
// https://iquilezles.org/articles/distfunctions2d
// https://iquilezles.org/articles/distfunctions/
float dot2(in vec2 v ) { return dot(v,v); }
float sdTrapezoid( in vec2 p, in float r1, float r2, float he )
{
    vec2 k1 = vec2(r2,he);
    vec2 k2 = vec2(r2-r1,2.0*he);
    p.x = abs(p.x);
    vec2 ca = vec2(p.x-min(p.x,(p.y<0.0)?r1:r2), abs(p.y)-he);
    vec2 cb = p - k1 + k2*clamp( dot(k1-p,k2)/dot2(k2), 0.0, 1.0 );
    float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
    return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float smoothstep_c2( float x )
{
  return clamp(x*x*x*(x*(x*6.0-15.0)+10.0), 0., 1.);
}

// smooth
float sdUnionSmooth( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*0.25;
}


// x - radius, y - x length
float sdCylX(in vec3 _p, in vec2 _lr)
{
    return max(length(_p.yz) - _lr.x, abs(_p.x) - _lr.y);
}

float sdCapsule( vec2 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float sdCapsuleZExtrusion(vec3 _p, float _h, float _r, float _d)
{
    float gzy = sdCapsule(_p.yz, _h, _r);
    return max(gzy, abs(_p.x) - _d);
}

// bounded - not exact
float sdTrapezoid(in vec2 _p, in vec2 _tb, in vec4 _vrl, in vec2 _rl)
{
    float fc0 = _p.y - _tb.x;
    float fc1 = -_p.y - _tb.y;
    float fc2 = -(dot(_p, normalize(_vrl.xy)) + _rl.x);
    float fc3 = -(dot(_p, normalize(_vrl.zw)) + _rl.y);
    
    return max(max(max(fc0, fc1), fc2), fc3);
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(in float _f1, in float _f2, in float _k)
{
  float df = _f1 - _f2;
  return 0.5 * (_f1 + _f2 + sqrt(df * df + _k));
}

// y - axis cylinder
float sdCylinder(in vec3 _p, in float _r, in float _h) {
    float rf = length(_p.xz) - _r;
    return max(rf, abs(_p.y) - _h);
}

#define sdPlane(_p, _v) dot(_p, _v)
#define sdCircle(_p, _r) (length(_p) - _r)

bool inBox(in vec2 _uv, in vec4 _box)
{
   vec2 v = step(_box.xy, _uv) - step(_box.xy + _box.zw, _uv);
   return bool(v.x * v.y);
}

float in_box(in vec2 _uv, in vec4 _box)
{
   vec2 v = step(_box.xy, _uv) - step(_box.xy + _box.zw, _uv);
   return (v.x * v.y);
}


#define sdMorph(_a, _b, _f) mix(_a, _b, _f)
#define sdUnion(_f1, _f2) min(_f1, _f2)
#define sdIntersect(_f1, _f2) max(_f1, _f2)
#define isHit(_trace_res, _eps) (step(abs(_trace_res.y), _trace_res.x * _eps))

float sdEllipsoid( vec3 p, vec3 r )
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdBoxBound(in vec2 p, in vec2 sides)
{
    vec2 q = abs(p) - sides;
    return max(q.x, q.y);
}


float sdBoxBound(in vec3 p, in vec3 sides)
{
    vec3 q = abs(p) - sides;
    return max(max(q.x, q.y), q.z);
}

float spiralSdf(in vec2 _uv, in float _b, in float _ths, in float _the )
{
    float th = atan(_uv.y, _uv.x);
    float r = length(_uv);
    
    float n = floor((r - th * _b)/(PI2 * _b));
    
    float th0 = clamp((PI2 * n + th), _ths, _the);
    float th1 = clamp((PI2 * (n + 1.) + th), _ths, _the);
    
    float r0 = th0 * _b;
    float r1 = th1 * _b;
    
    vec2  p0 = r0 * vec2(cos(th0), sin(th0));
    vec2  p1 = r1 * vec2(cos(th1), sin(th1));
    
    float f = min(dot(_uv - p0, _uv - p0), dot(_uv - p1, _uv - p1));
    
    return sqrt(f);
}

float spiralWrapSDF(in vec2 _uv, in float _hx)
{
    float b = max(0.36, 0.);
    float th_end = abs(8.8);
    
    vec2 e0 = vec2(_hx, 0.) + b * th_end * vec2(cos(th_end), sin(th_end));  
    vec2 e1 = vec2(-_hx, 0.) - b * th_end * vec2(cos(th_end), sin(th_end));
    
    
    vec2 st = vec2((abs(_uv.x) - _hx), sign(_uv.x)*_uv.y);
    float f = spiralSdf(st, b, -0.5, th_end);
    
    float f2 = sdSegment(_uv, e0, e1);
    
    return min(f, f2);
}

// returns (distance from center of sections, radius, angle, ID)
vec4 sdAngularPattern(in vec2 _uv, in float _N, in float _phase)
{
  float alpha = _phase + atan(_uv.y, _uv.x);
  float r = length(_uv);
  vec2 uvec = vec2(cos(-PI/_N), sin(-PI/_N));
  alpha = mix(alpha, -PI-(PI-alpha), step(0., alpha));
  
  float ialpha = floor((-alpha / PI2) * _N) / _N;
  float falpha = -mod(abs(alpha), PI2/_N);

  return vec4(0., r, falpha, ialpha);
}

float hash(in float x)
{
  return fract(5313.235 * mod(x, 0.75182) * mod(x, 0.1242));
}

float hash(in vec2 st) {
    return fract(sin(dot(st.xy,
        vec2(113.9928,1178.243)))
            * 4358.5475123);
}

float noise(in float s)
{
  float i = floor(s);
  float f = fract(s);
  
  return mix(hash(i), hash(i + 1.0), f * f* (3.0 - 2.0 * f));
}

//
vec3 lookAt(in vec3 _o, in vec3 _d, in vec3 _t) {
    vec3 d = normalize(_o - _t);
    vec3 r = normalize(cross(d, vec3(0., 1., 0.))); // fix if needed
    vec3 u = normalize(cross(r, d));
    
    return mat3(r, u, d) * _d;
}
//
// CHAIR SDF

// half lengths of chair frame w1, w2, depth and height from floor (all in halfs)
const vec4 h_ch_frame = vec4(9., 8., 8., 6.75);

float frame_base(in vec3 _p) {
    vec3 fbase_dims = h_ch_frame.xyz + vec3(0.5);
    float fbase = sdTrapezoid(_p.xz, h_ch_frame.x, h_ch_frame.y, h_ch_frame.z);
    float fcut = sdTrapezoid(_p.xz, fbase_dims.x, fbase_dims.y, fbase_dims.z);
    float f = sdBox(vec2(abs(fbase), _p.y), vec2(0.6, 1.25));
    fcut = length(vec2(abs(fcut), _p.y + 1.)) - 0.15;
    return sdIntersect(f, -fcut);
}

float front_legs(in vec3 _p) {
    vec3 op = _p;
    op = vec3(abs(op.x), op.y, op.z) - 
            vec3(h_ch_frame.x, -1.25, -h_ch_frame.z);

    float fb = sdBox(op, vec3(0.8, 2.25, 0.8));
    
    op = vec3(abs(_p.x), _p.y, _p.z) - 
            vec3(h_ch_frame.x - 0.1, -h_ch_frame.w - 1.25, -h_ch_frame.z + 0.1);
    
    float h_frmw = 2. * h_ch_frame.w;
    float ipleg = clamp((_p.y + 2. + h_frmw)/h_frmw, 0., 1.);
    
    // morphing coefficient
    float ipmorph = smoothstep_c2((_p.y + 3.)/2.);
    
    // add leg curvature
    op.xz -= 0.75*vec2(-1., 1.) * sin(ipleg * 6.28);
    
    // modify radius from bottom to top
    float rad = mix(0.4, 1.5, ipleg);
    float fl = sdCylinder(op, rad, h_ch_frame.w);
    
    // plane cuts
    float fp1 = -op.x - 0.5;
    float fp2 = op.z - 0.5;
    fl = max(max(fp1, fp2), fl);
    
    // rotate 45 deg
    float z_offset = mix(0.5, 1.2, ipleg);
    op.xz = rot2D(RAD_45) * op.xz;
    op.xy = rot2D(0.075) * op.xy;
    float fcut = sdCylinder(vec3(op.x - 0.5, op.y + 1., abs(op.z) - z_offset), 0.1, h_ch_frame.w*0.825);
    
    float fmix = sdMorph(sdIntersect(0.66*fl, -fcut), fb, ipmorph); // morphing
    return fmix;
}

float back_legs(in vec3 _p) {
    vec3 op = _p;
    
    // this is the height from the base (y = zero) level to the floor.
    float h_base = 2.*h_ch_frame.w + 1.25; 
    op = vec3(abs(_p.x), _p.y, _p.z) - 
            vec3(h_ch_frame.y + 0.2, -h_ch_frame.w - 1.25, h_ch_frame.z - 0.1);
    
    // one at the bottom of the leg and zero at the top of the leg.
    float ip_hbase = 1. - clamp(((_p.y + h_base)/(2.*h_ch_frame.w)), 0., 1.);
    
    op.xz -= vec2(0.3, 1.7)*ip_hbase*ip_hbase;
    op.xz *= rot2D((-1.-(ip_hbase))*0.1);
    
    float fl = sdBox(op, vec3(0.7, h_ch_frame.w, 0.8));
    
    op.y = _p.y;
    
    float fl2 = sdBox(op + vec3(0., 1., 0.), vec3(0.7, 1., 0.8));
    
    // upper extension of the legs
    op = vec3(abs(_p.x), _p.y, _p.z) - 
            vec3(h_ch_frame.y + 0.2, 0., h_ch_frame.z - 0.1);
    
    op.xz *= rot2D((-1.-(ip_hbase))*0.1);
    op.yz *= rot2D(0.11*smoothstep_c2(op.y*0.25));
    float ful = sdBox(vec2(op.x, 
        sdUnionSmooth(sdCircle(op.yz - vec2(20., 0.5), 0.2), 
                sdSegment(op.yz, vec2(0.), vec2(20., 0.)), 0.5)), vec2(0.7, 0.8));
    
    return sdUnion(sdUnion(fl, fl2), ful);
}

float cushion(in vec3 _p) {
    vec3 op = vec3(_p.x, _p.y - 2.0, _p.z + 1.);
    float ip_cr = clamp((op.y + 1.25) * 0.25, 0., 1.);
    float r = mix(0.35, 0.9, ip_cr);
    
    // cushion size coefficient
    float cf = 0.78 + 0.15*ANIM_T_CF(ip_cr, 0.2, 0.2, 0.85, 1., 3.);
    
    // slight lateral variations
    // Only on highest LOD.
    op.x += 0.1*sin(op.z) + 0.025*(sin(op.z*2. + 11.345));
    op.z += 0.05*cos(_p.x)*cos(_p.x*0.25);
    
    // 
    vec3 params = h_ch_frame.xyz;
    params -= r;
    params *= (cf);
    float fbase = sdTrapezoid(op.xz, params.x, params.y, params.z);
    
    // h_factor can be 1 on low LOD.
    float h_factor = cos(op.z*0.1);
    vec2 q = max(vec2(0.5*fbase - r, abs(op.y) - h_factor*h_factor + r*0.5), vec2(0.));
    float f = length(q) - r;
    return f;
}

// back seat base coordinates
vec4 back_coordinates(const vec3 _p) {
    vec3 op = vec3(_p.x, _p.y - 5.0, _p.z + 15.);
    op.yz *= rot2D(0.11*smoothstep_c2((op.y+4.)*0.25));
    
    // The seat back geometry is placed on a cylinder, and the
    // fourth parameter is the distance to this cylinder.
    return vec4(op, sdCircle(op.xz, 24.6));
}

float back(const vec3 _p) {
    vec4 op = back_coordinates(_p);
    
    // bottom back panel
    // the last parameter is the depth,height of the bottom panel
    float f_lateral2 = sdCircle(vec2(op.x, op.z - 0.3), 24.6);
    float f = sdBox(vec2(op.w, op.y), vec2(0.4, 1.)) - 0.1;
    
    op.y = _p.y - 19.25;
    float rc = 0.5;
    float cw = 0.7 * step(0., op.y) * smoothstep(0., 1., (5. - abs(op.x))/5.);
    float fup = sdBox(vec2(op.w, op.y), vec2(0.1, 0.75 + cw)) - rc;
    fup = sdUnionSmooth(fup, sdCircle(vec2(f_lateral2, op.y-cw-0.7), 0.5), 0.1);
    f = sdUnion(f, fup);
    
    // second parameter is the cut vector.
    float f_cut = sdPlane(vec2(abs(op.x), op.z), (vec2(3., -1.)));
    f = sdIntersect(f, f_cut);
    
    return f;
}

// 
float back_sketch(in vec3 _p, in bool _normal) {
    vec4 op = back_coordinates(_p);
    
    // center coordinates of chair back.
    vec3 chp = vec3(_p.x, _p.y - 10.92, _p.z - 10.);
    vec2 quart_p = abs(chp.yx) - vec2(3.025, 4.33);
    quart_p *= rot2D(4.8);
    float f_sketch = spiralSdf(quart_p.yx, 0.575, 1.2, 8.2);
    f_sketch = sdUnion(f_sketch, abs(sdCircle(vec2(abs(chp.x) - 7., chp.y), 7.)));
    f_sketch = sdUnion(f_sketch, abs(sdCircle(vec2(abs(chp.x) - 7.4, chp.y), 5.)));
    
    float f_cap = sdBox(vec2(op.w, chp.y), vec2(0.1, 7.));
    float f = sdIntersect(f_cap, sdBox(vec2(f_sketch, chp.z), vec2(0.15, 8.)));
    
    // there is a repetition here, since the next two lines are
    // identical to the cut in back
    float f_cut = sdPlane(vec2(abs(op.x), op.z), (vec2(3., -1.)));
    f = sdIntersect(f, f_cut);
    
    return f;
}

vec2 chair_sdf(in vec3 _p, int _trace_flags, in bool _normal, in bool _mtl) {
    float f;
    float fbs = bool(_trace_flags & TRACE_CHAIR_BASE_FLAG) ? frame_base(_p) : FAR;
    float ffl = bool(_trace_flags & TRACE_CHAIR_FRNT_LEG_FLAG) ? front_legs(_p) : FAR;
    float fbl = bool(_trace_flags & TRACE_CHAIR_BCK_LEG_FLAG) ? back_legs(_p) : FAR;
    float fc = bool(_trace_flags & TRACE_CHAIR_CUSHION_FLAG) ? cushion(_p) : FAR;
    float fb = bool(_trace_flags & TRACE_CHAIR_BACK_FLAG) ? back(_p) : FAR;
    float fsk = bool(_trace_flags & TRACE_CHAIR_FRAME_FLAG) ? back_sketch(_p, _normal) : FAR;
    
    f = sdUnion(sdUnion(ffl, fbs), fbl);
    f = sdUnion(f, fc);
    f = sdUnion(f, fb);
    f = sdUnion(f, fsk);
    
    // request for material
    float m = 0.;
    if (_mtl) {
        m += float(CHAIR_BASE_MTL)*float(f == fbs);
        m += float(CHAIR_BCK_LEG_MTL)*float(f == fbl);
        m += float(CHAIR_FRNT_LEG_MTL)*float(f == ffl);
        m += float(CHAIR_CUSHION_MTL)*float(f == fc);
        m += float(CHAIR_BACK_MTL)*float(f == fb);
        m += float(CHAIR_FRAME_MTL)*float(f == fsk);
    }
    
    return vec2(f, m);
}

// laptop
//
float laptop_screen(in vec3 _op, in vec4 _dims, bool _norm)
{
    vec3 opc = (scrTrf * vec4(_op, 1.)).xyz;

    // screen
    float r = 0.5; // side rounds
    float gs = sdBox(opc.xz, _dims.xz - vec2(r)) - r;
    
    // on normal calculation this radius must be constant for all the samples.
    
    mix(step(0., opc.y), scrRndSide, float(_norm));
    r = 0.075 * scrRndSide; // top rounds
    vec2 q = max(vec2(gs + r, abs(opc.y) - 0.5 * 0.25 + r), vec2(0.));
    gs = length(q) - r;
    return gs;
}

vec2 laptop(in vec3 _p, in vec4 _dims, int _trace_flags, bool _norm, bool _mtl)
{
    vec4 dims = _dims;
    // --- origin location of the geometry
    vec3 op = _p;
    vec3 opc; // helper coordinates
    // the transforms for laptop and screen must be initialized
    // earlier.
    op = (lpTrf * vec4(op, 1.)).xyz;
    
    //float dgeom = length(_p - targetOrigin) - 5.;
    
    float g = FAR;
    float gpc = MAX_DISTANCE;
    float gl = MAX_DISTANCE;
    // bottom (keboard) plane
    if (bool(_trace_flags & TRACE_LAPTOP_BASE_FLAG)) {
        float r = 0.5;
        g = sdBox(op, dims.xyz - vec3(r, 0., r));
        g -= r;
        g = max(g, op.y - 0.5 * r) - 0.01;

        // front cut - no need on low LOD.
        vec3 opc = op - vec3(0., dims.y, dims.z + r);
        opc.yz = opc.yz * 0.707 + vec2(opc.z, -opc.y) * 0.707;    
        float gc = sdBox(opc, vec3(1., 0.25, 0.25)) - 0.25;

        g = max(g, -gc);

        // back cut
        opc = op - vec3(0., dims.y, -dims.z);
        gc = sdBox(opc, vec3(11.*0.5, 0.5 * 1.5, 0.25));
        g = max(g, -gc);

        // pins don't draw on low LOD
        opc = vec3(abs(op.x), op.yz) - vec3(dims.x - 1.5, 0.0, -dims.z + 0.25);
        g = min(g, sdCylX(opc, vec2(0.125, 0.8)));

        // jacks should be filtered according to sides;
        vec3 right = transpose(lpTrf)[0].xyz;
        float side = sign(dot(right, g_dir));
        // left side jacks - no need on low LOD or shadows.
        
        // don't model if we're looking the other way
        if (_mtl || side < 0.)
        {
            // power
            gpc = sdCapsuleZExtrusion(op - vec3(dims.x, 0., -dims.z + 1.075), 0.75, 0.12, .05);

            // usb-c
            opc = op - vec3(dims.x, 0., -dims.z + 2.7);
            gl = sdCapsuleZExtrusion(vec3(opc.xy, abs(opc.z)) - (vec3(0., 0., 0.175)), 0.33, 0.1, 0.262);
            // headsets/mic
            opc = op - vec3(dims.x, 0., -dims.z + 3.7);
            gl = min(gl, max(length(opc.zy) - 0.137, abs(opc.x) - 0.3));
        //
        }

        // right side jacks - no need on low LOD or shadows.
        if (_mtl || side > 0.) 
        {
            opc = op - vec3(-dims.x, 0., -dims.z + 2.675);

            gl = min(gl, sdCapsuleZExtrusion(opc, 1., 0.1, 0.262));

            opc = op - vec3(-dims.x, 0., -dims.z + 1.9);
            gl = min(gl, sdCapsuleZExtrusion(opc, 0.33, 0.1, 0.262));

            opc = op - vec3(-dims.x, 0.05,  -dims.z + 1.25);
            float gct = max(sdBox(opc.zy, vec2(0.3, 0.05)), abs(opc.x) - 0.3) - 0.075;
            opc = op - vec3(-dims.x, -0.1, -dims.z + 1.25);
            gct = min(gct, 
                max(sdTrapezoid(opc.zy, vec2(0.075), vec4(1., 1., -1., 1.), vec2(0.21)), abs(opc.x) - 0.3));
            gl = min(gct, gl);
        }
    }
    // screen

    // screen rotation
    opc = (scrTrf * vec4(op, 1.)).xyz;

    float gs = bool(_trace_flags & TRACE_LAPTOP_SCREEN_FLAG) ? laptop_screen(op, dims, _norm) : FAR;
    
    // connecting panel -- attached to screen
    vec3 opp = opc - vec3(0., -0.25, -dims.z + 0.125);
    
    mat4 tmtx = mat4(1.);
    mat4 opTrf = mat4(1.);
    
    opTrf = Ryz(-0.1);
    opTrf *= tmtx;
    opTrf = tmtx * opTrf;
    
    opp = (opTrf * vec4(opp, 1.)).xyz;
    
    float gp = sdBox(opp, vec3(dims.x - 1.5, 0.25, 0.05));
    float gps = sdUnionSmooth(gs, gp, 0.1);
    float gf = max(max(min(gps, g), -gl), -gpc);
    
    float mtl = 0.;
    
    if (_mtl)
    {
        // Works here, but won't work for organics (where smooth min and max are used)
        // In the latter case maybe steps with epsilons will work.
        mtl += float(LAPTOP_BASE_MTL) * float(g == gf);
        mtl += float(LAPTOP_SCREEN_MTL) * float(gs == gf);
        mtl += float(LAPTOP_MTL + 2) * float(gp == gf);
        mtl += float(LAPTOP_MTL + 3) * float(-gl == gf);
        mtl += float(LAPTOP_MTL + 4) * float(-gpc == gf);
    }
    
    return vec2(gf, mtl);
}

vec2 sdLaptop(in vec3 _p, in sampler2D _s, in int _trace_flags, in bool _normal, in bool _mtl) {
    vec3 op = _p;
    vec4 dims = TF(_s, LAPTOP_H_DIMS);
    
    //prepareLaptopTransform(lpTrf, scrTrf);
    lpTrf = mat4(TF(_s, LAPTOP_BASE_TRF_0), TF(_s, LAPTOP_BASE_TRF_1), 
                 TF(_s, LAPTOP_BASE_TRF_2), TF(_s, LAPTOP_BASE_TRF_3));
                 
    scrTrf = mat4(TF(_s, LAPTOP_SCRN_TRF_0), TF(_s, LAPTOP_SCRN_TRF_1),
                  TF(_s, LAPTOP_SCRN_TRF_2), TF(_s, LAPTOP_SCRN_TRF_3));
               
    // bounding volume
    vec4 opb = vec4(op, 1.);
    vec3 bvh_size = dims.xyz + vec3(bvh_margin);
    opb = lpTrf * opb;
    float f_bound = -MAX_DISTANCE;
    if (!_normal && !_mtl) {
        f_bound = sdBox(opb.xyz, bvh_size);
        f_bound = sdUnion(f_bound,
            sdBox((scrTrf * opb).xyz, bvh_size));
    }
    
    vec2 flp = laptop(op, TF(_s, LAPTOP_H_DIMS), _trace_flags, _normal, _mtl);
    
    return flp;
}
//

// TABLE
float hLowBeam(in vec2 _uv, in float _r, in float _h, in float _v)
{
    float f = abs(length(_uv) - _r);
    vec2 v2 = normalize(vec2(-_v, _r - _h));
    
    // clamp the arc
    float fup = _uv.x;
    float fv = dot(vec2(-v2.y, v2.x), _uv);
    
    f = max(max(fup, f), fv);
    
    return f;
}
// _param.x -- table radius, _param.y -- table height
float lowTableProfileSDF(in vec2 _uv, in vec3 _param, in bool _norm)
{
    float v = 0.75 * _param.x;
    float h = _param.y * 0.2;
    float r = (h * h + v * v) / (2. * h);
    
    float fh = hLowBeam(_uv - vec2(0., -_param.x - r + h), r, h, v);
    float fv = hLowBeam(_uv.yx - vec2(-_param.x - r + h, 0.).yx, r, h, v);
    //float fv = vLowBeam(_uv - vec2(-_param.y - r + h, 0.), r, h, v);
    
    //float fb = sdSegment(_uv, vec2(0., 0.), vec2(-_param.x, 0.));
    float fb = sdBoxBound(_uv + vec2(_param.x * 0.5, 0.), vec2(_param.x*0.46, 0.));
    
    vec2 p = vec2(-v, -_param.x);

    vec2 bc = 0.5 * (p + p.yx);
    float fc = abs(length(_uv - bc) - 0.4975*(length(p - p.yx) + 0.));
    fc = max(fc, dot(_uv - bc, normalize(vec2(1., 1.4))));
    fc = max(fc, dot(_uv - bc, normalize(vec2(1.4, 1.))));
    
    float ang = 1.414;
    vec2 ruv = mat2(cos(ang), sin(ang), -sin(ang), cos(ang)) * (_uv + vec2(16.5, 15.0));
    // very expensive. Think about an LOD.
    float fsp = spiralWrapSDF(ruv, 4.3);
    
    float f = smin(fc, min(min(fh, fv), fb), 0.1);
    f = min(f, fsp);
    
    f = abs(f) - _param.z;
       
    //f = fv;
    return f;
}

float tableTop(in vec3 _p)
{
    vec3 op = _p - vec3(0., 1.5, 0.);

    float fa = sdBoxBound(vec3(abs(op.x), op.y - 0.5, (op.z)), vec3(26., .5, 4.));
    float fb = sdBoxBound(vec3(op.x, op.y - 0.5, abs(op.z)) - vec3(0., 0., 15.4), vec3(4., .5, 10.8));
    
    op -= vec3(0., 1., 0.);
    float op_xz_len = length(op.xz);
    vec2 q = vec2(op_xz_len - 30., op.y);
    q = abs(q) - vec2(0.5, 1.);
    
    op -= vec3(0., 1., 0.);
    float dxz = op_xz_len - 31.;
    float r = 0.25 * sign(op.y + 0.5);
    float f = length(max(vec2(dxz + r, abs(op.y) - .5 + r), vec2(0.))) - r;
      
    return min(min(fa, fb), min(f, max(q.x, q.y)));
}

float tableMidBottom(in vec3 _p, in float _h, in float _th, in float _tv)
{
    vec3 op = _p - vec3(0., -_h + 1., 0.);
    float len_op_xz = length(op.xz);
    // bound cylinder
    vec2 q = vec2(len_op_xz - 1., abs(op.y) -_h);
    float fc = max(q.x, q.y);
    
    // limited repitition of central ellipsoid.
    float sh = _h * 0.75;
    vec3 qp = op;
    qp.y = op.y - sh*clamp(round(op.y/sh),-1.,1.);
    float fe = sdEllipsoid(qp, vec3(2., 1.0, 2.));
    
    
    float fcyl = sdCappedCylinder(vec3(op.x, abs(abs(op.y) - _h*0.35) - _h*0.25, op.z), 1., 1.5);
    
    // Torus
    vec2  qt = vec2(len_op_xz - 1.5, abs(abs(op.y) - _h*0.35) - _h*0.2);
    float ftor = length(qt) - 0.25;
    fcyl = smax(fcyl, -ftor, 0.3);
    
    // Torus 2
    vec2 qt2 = vec2(len_op_xz - 1.1, abs(op.y) - 1.75);
    float ftor2 = length(qt2) - 0.2;
    fcyl = smin(fcyl, ftor2, 0.1);
    
    fe = smin(fcyl, fe, 0.1);
    
    // legs
    vec3 lop = op;
    lop.y -= 0.25;
    lop.xz *= mat2(cos(PI*0.25), sin(PI*0.25), -sin(PI*0.25), cos(PI*0.25));
    lop.xz = abs(lop.xz); 
    lop -= vec3(_tv * 0.62, -_th * 0.695, _tv * 0.62);
    float fleg = sdEllipsoid(lop, vec3(2.5, 1.5, 2.5));
    fc = min(fleg, fc);
    
    return min(fc, fe);
}

float tableFrame(in vec3 _p, in bool _norm) {
    vec3 op = _p - vec3(0., -0.0, 0.);
    op.x = -abs(op.x);
    op.z = -abs(op.z);
    
    // the min/max is to apply the sdf to both z and x simultaneously
    // and thus save a rather heavy call.
    float dxy = lowTableProfileSDF(vec2(min(op.x, op.z), op.y), vec3(25., 27., 0.4), _norm);
    //float dxz = lowTableProfileSDF(op.zy, vec3(25., 27., 0.4), _norm);
    float d = max((dxy) - 0.2, (abs(max(op.z, op.x)) - 0.6));
    
    // Because the xz space is separated into 4 quad-regions, we fix the step
    // (instead of fixing the SDF) so that we won't cross regions by much.
    // We don't need to use maxStep.
    float maxStep = 0.7 * (min(abs(_p.x), abs(_p.z)) + 1.);
    //d = min(d, max((dxz) - 0.2, (abs(op.x) - 0.6)));
    d = min(maxStep, d);
 
    // the parameter should be fixed.
    float dmid = tableMidBottom(_p, 27. * 0.8 * 0.5, 27., 25.);
    
    return min(dmid, d);
}
vec2 table(in vec3 _p, in int _trace_flags, in bool _norm, in bool _mtl)
{
    vec3 op = _p;
    
    float dframe = bool(_trace_flags & TRACE_TABLE_FRAME_FLAG) ? tableFrame(_p, _norm) : FAR;
    float dtop = bool(_trace_flags & TRACE_TABLE_TOP_FLAG) ? tableTop(_p) : FAR;
    float d = min(dtop, dframe);
    
    float fmtl = 0.;
    
    if (_mtl)
    {
        fmtl += float(d == dtop) * float(TABLE_TOP_MTL);
        fmtl += float(d != dtop) * float(TABLE_FRAME_MTL);
    }
    
    return vec2(d, fmtl);
}

vec2 sdfTable(in vec3 _p, in int _trace_flags, in bool _norm, in bool _mtl)
{
    // bounding volume
    float f_bound = (!_norm && !_mtl) ? 
        sdCylinder(_p - vec3(0., -12., 0.), 32., 18.) : -FAR;
    
    return (f_bound > T_EPS) ? vec2(f_bound + 0.5, TABLE_TOP_MTL) 
            : table(_p, _trace_flags, _norm, _mtl);
}

// END TABLE

//
// CHAIR SDF

// chair

vec2 chairs(in vec3 _p, in sampler2D _ch, int _trace_flags, in bool _normal, in bool _mtl) {
    const float n_legs = float(N_CHAIRS);
    vec4 fAng = sdAngularPattern(_p.xz, n_legs, 0.);
    int chId = int(fAng.w*n_legs);
    
    
    vec2 trp = fAng.y*vec2(cos(fAng.z), sin(fAng.z));
    float d_hash = 20. * hash(fAng.w + 14.);
    float r_hash = hash(fAng.w + 20.);
    vec2 loc = (40. + d_hash)*vec2(cos(-PI/n_legs), sin(-PI/n_legs));
    
    vec3 op = vec3(trp.x, _p.y, trp.y) - vec3(loc.x, -14.55, loc.y);
    
    // length to section.
    // this can be calculated more precisely if we have direction
    // but on the other hand, it works always, while analytic intersection
    // would work only for the closest.
    vec2 v0 = vec2(1., 0.);
    vec2 v1 = vec2(cos(PI2/n_legs), sin(PI2/n_legs));
    float d0 = length(_p.x * v0.y - _p.y * v0.x);
    float d1 = length(_p.x * v1.y - _p.y * v1.x);
    
    // Analytic intersection //
    // not used because it is slower (and the approximate, distance based
    // solution doesn't seem to produce any additional artifacts);
    // Keeping here for completenes.
    float fchId = float(chId);
    vec2 vc0 = vec2(cos(-fchId * PI2/n_legs), sin(-fchId * PI2/n_legs));
    vec2 vc1 = vec2(cos(-(fchId + 1.) * PI2/n_legs), 
                    sin(-(fchId + 1.) * PI2/n_legs));
                    
    vec2 vn0 = normalize(vec2(-vc0.y/vc0.x, 1.));
    vec2 vn1 = normalize(vec2(-vc1.y/vc1.x, 1.));
    
    float t0 = -dot(_p.xz, vn0) / dot(g_dir.xz, vn0);
    float t1 = -dot(_p.xz, vn1) / dot(g_dir.xz, vn1);
    float at = min(mix(t0, MAX_DISTANCE, step(t0, 0.)),
                   mix(t1, MAX_DISTANCE, step(t1, 0.)));
    //
    
    // chair rotation
    float rotAng = TF(_ch, ivec2(chId/4, CHAIR_ROT))[chId % 4];
    op.xz *= rot2D(rotAng);
    
    // chair bounding volume
    bool trace_pass = !_normal && !_mtl;
    float f_bound = -FAR;
    f_bound = trace_pass ? 
        sdBox(op - vec3(0., -h_ch_frame.w, -2.), vec3(h_ch_frame.x + 3., h_ch_frame.w + 5., h_ch_frame.y + 1.)) : -FAR;
    f_bound = trace_pass ? sdUnion(f_bound, sdBox(op - vec3(0., 0., h_ch_frame.y + 1.), vec3(h_ch_frame.x + 1., 23., 4.))) : -FAR;
    
    vec2 f_chair = (f_bound > 0.01) ? vec2(f_bound + 0.5, DEFAULT_MTL) : chair_sdf(op, _trace_flags, _normal, _mtl);

    // the cross section factor is a safe margin distance for crossing
    // patterned boundary
    
    float cross_section_factor = sdUnion(d0, d1) + CROSS_SECTION_FACTOR;
    //float cross_section_factor = at + 1.;
    f_chair.x = sdUnion(f_chair.x, cross_section_factor);
    return f_chair;
}

vec2 sdFloor(in vec3 _p) {
    return vec2(_p.y - (FLOOR_LEVEL), float(FLOOR_MTL));
}

float rayXFloor(in float _oy, in float _dy) {
    if (_dy > T_EPS)
        return FAR;
    return (FLOOR_LEVEL - _oy) / _dy;
}

vec2 map(in vec3 _p, int _trace_flags, in sampler2D _ch, in bool _normal, in bool _mtl)
{
   int trace_flags = _trace_flags;
   vec2 ft = bool(trace_flags & TRACE_TABLE_FLAG) ? sdfTable(_p, _trace_flags, _normal, _mtl) : vec2(FAR, 0.); 
   vec2 fch = bool(trace_flags & TRACE_CHAIRS_FLAG) ? chairs(_p, _ch, _trace_flags, _normal, _mtl) : vec2(FAR, 0.);
   //vec2 ffl = bool(trace_flags & TRACE_FLOOR_FLAG) ? sdFloor(_p) : vec2(FAR, 0.);
   vec2 flp = bool(trace_flags & TRACE_LAPTOP_FLAG) ? sdLaptop(_p, _ch, _trace_flags, _normal, _mtl) : vec2(FAR, 0.);
   
   float f;
   f = fch.x;
   f = sdUnion(f, ft.x);
   //f = sdUnion(f, ffl.x);
   f = sdUnion(f, flp.x);
   
   vec2 rf = vec2(f, 0.);
   
   if (_mtl)
   {
       rf.y += float(f == ft.x) * ft.y;
       rf.y += float(f == fch.x) * fch.y;
       //rf.y += float(f == ffl.x) * ffl.y;
       rf.y += float(f == flp.x) * flp.y;
   }
   
   return rf;
}

vec2 trace(in vec3 _o, in vec3 _d, int _trace_flags, 
    in sampler2D _ch, const float _iter, const float _far, const float _eps) {
    float t = 0.;
    float mint = 10.;
    vec2 res = vec2(10.);
    g_dir = _d;
    int trace_flags = _trace_flags;
    for (float fi = 0.; fi < _iter; fi++) {
        vec3 p = _o + _d * t;

        mint = map(p, _trace_flags, _ch, false, false).x;
        
        if (abs(mint) < t * _eps || t > _far || p.y < FLOOR_LEVEL)
            break;
        if (dot(normalize(p.xz), _d.xz) > 0. 
            && dot(p.xz, p.xz) > GEOM_BOUNDING_CIRCLE_SQR)
            break;
        
        t += mint;
    }
    
    return vec2(t, mint);
}
