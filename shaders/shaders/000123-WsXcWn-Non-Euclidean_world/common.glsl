// Common (common) — Non-Euclidean world by tmst
// https://www.shadertoy.com/view/WsXcWn

// ==========================
// Generic Helpers/Constants
// ==========================

#define PI 3.141592653589793
#define TWOPI 6.283185307179586
#define PI_OVER_2 1.570796326794896
#define PI_OVER_4 0.7853981633974483

#define SQRT2 1.414213562373095
#define INV_SQRT2 0.7071067811865476

// Keyboard input description: https://www.shadertoy.com/view/lsXGzf
#define KEY_S 83
#define KEY_D 68
#define KEY_F 70

//---------------
// Miscellaneous
//---------------

//cf. Dave Hoskins https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Find t so that mix(a,b,t) = x
float unmix(float a, float b, float x) {
    return (x - a)/(b - a);
}

// 1 if x \in (a,b], else 0
float isInInterval(float a, float b, float x) {
    return step(a, x) * (1.0 - step(b, x));
}

// Parameterization of unit square with t \in [0,4]
vec2 paramUnitSquare(float t) {
    float tmod4 = mod(t, 4.0);
    return vec2(
        clamp(2.0*abs(tmod4-2.5)-2.0, -1.0, 1.0),
        clamp(2.0-2.0*abs(tmod4-1.5), -1.0, 1.0)
    );
}

// Rodrigues' formula: v -> (v.n)n + (v-(v.n)n)c - (vxn)s
mat3 oProd(vec3 n) {
    float xy = n.x*n.y, xz = n.x*n.z, yz = n.y*n.z;
    return mat3(n.x*n.x,xy,xz,  xy,n.y*n.y,yz,  xz,yz,n.z*n.z);
}
mat3 glRotate(vec3 axis, float angle) {
    float c = cos(angle), s = sin(angle);
    vec3 n = normalize(axis);
    return (
        (1.-c)*oProd(n) +
        mat3(c,s*n.z,-s*n.y,  -s*n.z,c,s*n.x,  s*n.y,-s*n.x,c)
    );
}

//----------------------------------------
// Color blending for premultiplied alpha
//----------------------------------------

vec4 blendOnto(vec4 cFront, vec4 cBehind) {
    return cFront + (1.0 - cFront.a)*cBehind;
}

vec4 blendOnto(vec4 cFront, vec3 cBehind) {
    return cFront + (1.0 - cFront.a)*vec4(cBehind, 1.0);
}

//--------------------------------------------------------------
// Conversions vec3 rgb888 <-> vec2 rgb565 to free up a channel
//--------------------------------------------------------------

#define DITHER

//24-bit color in [0,1]^3 to 16-bit color in [0,1]^2
vec2 packColor(vec2 fragCoord, vec3 c24){
  //get 5r6g5b values
  float r = (c24.r == 1.0) ? 31.0 : floor(c24.r*32.0);
  float g = (c24.g == 1.0) ? 63.0 : floor(c24.g*64.0);
  float b = (c24.b == 1.0) ? 31.0 : floor(c24.b*32.0);

  #ifdef DITHER
      float tr = fract(c24.r*32.0);
      float tg = fract(c24.g*64.0);
      float tb = fract(c24.b*32.0);

      float tarr[16];
      tarr[ 0] =  1.0; tarr[ 1] =  9.0; tarr[ 2] =  3.0; tarr[ 3] = 11.0;
      tarr[ 4] = 13.0; tarr[ 5] =  5.0; tarr[ 6] = 15.0; tarr[ 7] =  7.0;
      tarr[ 8] =  4.0; tarr[ 9] = 12.0; tarr[10] =  2.0; tarr[11] = 10.0;
      tarr[12] = 16.0; tarr[13] =  8.0; tarr[14] = 14.0; tarr[15] =  6.0;

      int tci = int(mod(fragCoord.x, 4.0));
      int tcj = int(mod(fragCoord.y, 4.0));

      float thresh = 1.0;
      for(int i=0; i<4; i++){
      for(int j=0; j<4; j++){
        if((i == tci) && (j == tcj)){ thresh = tarr[i*4+j]/17.0; }
      }}

      if(tr > thresh){ r = min(r+1.0, 31.0); }
      if(tg > thresh){ g = min(g+1.0, 63.0); }
      if(tb > thresh){ b = min(b+1.0, 31.0); }
  #endif

  //encode 5r6g5b -> [gggrrrrr][gggbbbbb]
  float gmin = mod(g,8.0);
  float gmax = floor(g/8.0);

  float x = (r + 32.0*gmin)/255.0;
  float y = (b + 32.0*gmax)/255.0;

  return vec2(x,y);
}

//16-bit color in [0,1]^2 to 24-bit color in [0,1]^3
vec3 unpackColor(vec2 c16){
  //[gggrrrrr][gggbbbbb] -> 5r6g5b

  float rpack = floor(255.0*c16.x);
  float bpack = floor(255.0*c16.y);

  float gmin = floor(rpack/32.0);
  float gmax = floor(bpack/32.0);
  float g = (gmin + 8.0*gmax)/63.0;

  float r = mod(rpack,32.0)/31.0;
  float b = mod(bpack,32.0)/31.0;

  return vec3(r,g,b);
}

//---------------------------
// Signed distance functions
//---------------------------

float sdSubtract(float d1, float d2) {
    return max(-d1,d2);
}

float sdBox(vec3 boxCenter, vec3 boxRadii, vec3 p) {
    vec3 q = boxRadii - abs(p - boxCenter);
    return length(min(q, 0.0)) - max( min(min(q.x, q.y), q.z), 0.0 );
}

//------------------------------------------
// Exact hits along a ray (1d and 2d boxes)
//------------------------------------------

// Find t>0 so x+t*dx is on boundary of xMin-xMax, assuming x in interval
float hitIntervalFromInside(
    float xMin, float xMax,
    float x, float dx
) {
    float tMin = (xMin - x) / dx;
    float tMax = (xMax - x) / dx;
    return max(tMin, tMax);
}

// Find t>0 so p+t*v is on boundary of boxMin-boxMax, assuming x in box
float hitBox2FromInside(
    in vec2 boxMin, in vec2 boxMax,
    in vec2 p, in vec2 v
) {
    return min(
        hitIntervalFromInside(boxMin.x, boxMax.x, p.x, v.x),
        hitIntervalFromInside(boxMin.y, boxMax.y, p.y, v.y)
    );
}

// Find t>0 so p+t*v is on boundary of boxMin-boxMax, assuming x outside box
// (Hitting from outside means there may be no such t, then didHit -> 0.0)
void hitBox2FromOutside(
    in vec2 boxMin, in vec2 boxMax,
    in vec2 p, in vec2 v,
    out float t, out float didHit
) {
    vec2 tb0 = (boxMin - p) / v;
    vec2 tb1 = (boxMax - p) / v;
    vec2 tmin = min(tb0, tb1);
    vec2 tmax = max(tb0, tb1);

    vec2 tRange = vec2(
        max(tmin.x, tmin.y),
        min(tmax.x, tmax.y)
    );

    didHit = step(tRange.s, tRange.t) * step(0.0, tRange.s);
    t = tRange.s;
}

//-----------------------------------------------------
// Exact squared distances (point, segment, ray, line)
//-----------------------------------------------------

// Returns t that minimizes distance(p, a + t*nv)
float minPointLine(vec3 a, vec3 nv, vec3 p) {
    return dot(p - a, nv);
}

// Returns (s,t) that minimizes distance(a + t*nv, b + t*nw)
vec2 minLineLine(vec3 a, vec3 nv, vec3 b, vec3 nw) {
    vec3 d = a - b;
    float vw = dot(nv, nw);
    float dv = dot(d, nv);
    float dw = dot(d, nw);
    return vec2(dv - dw*vw, -dw + dv*vw) / (vw*vw - 1.0);
}

float dsq(vec3 p, vec3 q) {
    vec3 d = p - q;
    return dot(d, d);
}

float dsqPointLine(vec3 a, vec3 p, vec3 nv) {
    float tMinA = minPointLine(p, nv, a);
    return dsq( a, p + tMinA*nv );
}

float dsqPointRay(vec3 a, vec3 p, vec3 nv) {
	float tMinA = max(0.0, minPointLine(p, nv, a));
    return dsq( a, p + tMinA*nv );
}

float dsqSegmentLine(vec3 a, vec3 b, vec3 p, vec3 nv) {
    float tMinA = minPointLine(p, nv, a);
    float tMinB = minPointLine(p, nv, b);
    float dsqMin = min(
        dsq( a, p + tMinA*nv ),
        dsq( b, p + tMinB*nv )
    );

    float lenSeg = length(a - b);
    vec3 nvSeg = (a - b) / lenSeg;

    vec2 minInterior = minLineLine(b, nvSeg, p, nv);
    if (minInterior.s > 0.0 && minInterior.s < lenSeg) {
        vec3 cpSeg = b + minInterior.s*nvSeg;
        vec3 cpLine = p + minInterior.t*nv;
        dsqMin = min( dsqMin, dsq(cpSeg, cpLine) );
    }

    return dsqMin;
}

float dsqSegmentRay(vec3 a, vec3 b, vec3 p, vec3 nv) {
    float tMinA = max(0.0, minPointLine(p, nv, a));
    float tMinB = max(0.0, minPointLine(p, nv, b));
    float dsqMin = min(
        dsq( a, p + tMinA*nv ),
        dsq( b, p + tMinB*nv )
    );

    float lenSeg = length(a - b);
    vec3 nvSeg = (a - b) / lenSeg;

    float sMinP = clamp(minPointLine(b, nvSeg, p), 0.0, lenSeg);
    dsqMin = min( dsqMin, dsq(p, b + sMinP*nvSeg) );

    vec2 minInterior = minLineLine(b, nvSeg, p, nv);
    if (minInterior.s > 0.0 && minInterior.s < lenSeg && minInterior.t > 0.0) {
        vec3 cpSeg = b + minInterior.s*nvSeg;
        vec3 cpLine = p + minInterior.t*nv;
        dsqMin = min( dsqMin, dsq(cpSeg, cpLine) );
    }

    return dsqMin;
}
