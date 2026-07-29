// Common (common) — Alien Tunnel by lz
// https://www.shadertoy.com/view/X3ySRc


#define PI 3.14159265359
#define PI2 6.28318530718
#define PI_H 1.57079632679

#define PHI 1.6180339887
#define INV_PHI 0.6180339887

#define INT(f) int(f + 0.00001)

#define SEL_ZONE_Y 0.01

#define ROT2D(p2d, ang) (cos(ang) * p2d.xy + sin(ang) * vec2(p2d.y, -p2d.x))

#define FAR 60.
#define M_ITER 256
#define T_EPS 0.001
#define N_EPS 0.001

#define PI 3.14159265359
#define PI2 6.28318530718

//#define TARGET_RATIO 0.5625
#define TARGET_RATIO 0.428

#define PULSE_T(_t, _e, _pa, _pb) (smoothstep(_pa - _e, _pa, _t) - smoothstep(_pb, _pb + _e, _t))
#define ASYM_PULSE_T(_t, _ea, _pa, _eb, _pb) (smoothstep(_pa - _ea, _pa, _t) - smoothstep(_pb, _pb + _eb, _t))
#define ANIM_T_CF(_t, _p, _e0, _e1, _cf0, _cf1) (_cf0 * smoothstep(_p - _e0, _p, _t) - _cf1 * smoothstep(_p, _p + _e1, _t))
#define ANIM_T_CF3(_t, _p0, _p1, _p2, _e0, _e1, _e2, _cf0, _cf1) (_cf0 * smoothstep(_p0 - _e0, _p0, _t) - _cf1 * smoothstep(_p1, _p1 + _e1, _t) - (_cf0-_cf1) * smoothstep(_p2, _p2 + _e2, _t))

// noise
float hash(in float s) {
  return fract(5313.235 * mod(s, 0.78182) * mod(s, 0.1242));
}

float hash2(in vec2 st) {
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

//https://www.shadertoy.com/view/ldSSzV
vec3 hash31(float p) {
	vec3 h = vec3(127.231,491.7,718.423) * p;	
    return fract(sin(h)*435.543);
}

float grayscale(in vec3 col)
{
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    return gray;
}


float hash(in vec3 p)
{
return fract(sin(dot(p,
vec3(12.6547, 765.3648, 78.653)))*43749.535);
}

float noise3(in vec3 p)
{
vec3 pi = floor(p);
vec3 pf = fract(p);

pf = pf*pf*(3.-2.*pf);

float a = hash(pi + vec3(0., 0., 0.));
float b = hash(pi + vec3(1., 0., 0.));
float c = hash(pi + vec3(0., 1., 0.));
float d = hash(pi + vec3(1., 1., 0.));

float e = hash(pi + vec3(0., 0., 1.));
float f = hash(pi + vec3(1., 0., 1.));
float g = hash(pi + vec3(0., 1., 1.));
float h = hash(pi + vec3(1., 1., 1.));

return mix(mix(mix(a,b,pf.x),mix(c,d,pf.x),pf.y),
mix(mix(e,f,pf.x),mix(g,h,pf.x),pf.y), pf.z);
}

float fbm(vec3 p) {

  float f = 0.;
  float ampl = 0.5;
  float freq = 1.;
  float off = 0.;

  int i = 0;
  for (i = 0; i < 4; i++) {
    f += ampl*noise3(p*freq + off);
    ampl*= 0.5;
    freq *= 2.;
    off += 12.274739;
  }

  return f;
}

vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

vec3 camera(in vec3 o, in vec3 d, in vec3 tar, out mat3 viewCam) {
  vec3 dir = normalize(o - tar);
  vec3 right = cross(vec3(0.,1.,0.),dir);
  vec3 up = cross(dir,right);

  mat3 view = mat3(right,up,dir);
  viewCam = view;
  return view*d;
}

vec3 camera(in vec3 o, in vec3 d, in vec3 tar, in vec3 up) {
  vec3 dir = normalize(o - tar);
  vec3 right = normalize(cross(dir, up));
  up = normalize(cross(right,dir));

  mat3 view = mat3(right,up,dir);
  return (view*d);
}

#define NPO 6
vec3 origs[NPO] = vec3[NPO](vec3(-7., 4.2, 6.4), vec3(4., 5.8, 6.4), 
    vec3(3., -6., 7.), vec3(4.4, -4., -8.23), vec3(-4., -6.3, -7.3), vec3(-4.7, 4.1, -6.6));

vec3 getOrigin(in float time, in sampler2D s, in float _power)
{
    float t = time * 0.05;
    float oTime = texelFetch(s, ivec2(mod(t, 256.), 0), 0).r;
    float oNTime = texelFetch(s, ivec2(mod(t + 1., 256.), 0), 0).r;

    int iOrig = int(mod(oTime * float(4), float(4)));
    int iNOrig = int(mod(oNTime * float(4), float(4)));

    float fOrig = fract(t);

    vec3 o = mix(origs[iOrig], origs[iNOrig], smoothstep(0., 1., pow(fOrig, _power)));
    o = normalize(o) * 8.;
    o += vec3(sin(time*.5),cos(time*.5),0.);
    
    return o;
}