// Buffer B (buffer) — Floppy Sheet by dr2
// https://www.shadertoy.com/view/MlVSz1

// "Floppy Sheet" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec4 QtMul (vec4 q1, vec4 q2);
mat3 QtToRMat (vec4 q);
vec4 EulToQt (vec3 e);
float Hashff (float p);
vec4 Loadv4 (vec2 vId);
void Savev4 (vec2 vId, vec4 val, inout vec4 fCol, vec2 fCoord);

#define LBIG 0
#if LBIG
const int nBallE = 65;
const int nBall = nBallE * nBallE;
#else
const int nBallE = 33;
const int nBall = nBallE * nBallE;
#endif

const float pi = 3.14159;
vec4 qtVu;
float hbLen, spLen, fOvlap, ntStep;

const int nNeb = 4, nNebD = 4;
ivec2 idNeb[nNeb], idNebD[nNebD];

void IdNebs ()
{
  idNeb[0] = ivec2 (1, 0);
  idNeb[1] = - idNeb[0];
  idNeb[2] = ivec2 (0, 1);
  idNeb[3] = - idNeb[2];
  idNebD[0] = ivec2 (1, 1);
  idNebD[1] = - idNebD[0];
  idNebD[2] = ivec2 (1, -1);
  idNebD[3] = - idNebD[2];
}

vec3 GetR (vec2 v)
{
  return Loadv4 (v).xyz;
}

vec3 GetV (vec2 v)
{
  v.x += float (nBallE);
  return Loadv4 (v).xyz;
}

#define InLatt(t) (t >= 0 && t < nBallE)

void SpringForce (ivec2 iv, vec3 r, vec3 v, inout vec3 f)
{
  vec3 dr;
  ivec2 ivn;
  float spLenD, fSpring, fDamp;
  fSpring = 50.;
  fDamp = 0.5;
  for (int n = 0; n < nNeb; n ++) {
    ivn = iv + idNeb[n];
    if (InLatt (ivn.x) && InLatt (ivn.y)) {
      dr = r - GetR (vec2 (ivn));
      f += fSpring * (spLen - length (dr)) * normalize (dr) -
         fDamp * (v - GetV (vec2 (ivn)));
    }
  }
  spLenD = spLen * sqrt (2.);
  for (int n = 0; n < nNebD; n ++) {
    ivn = iv + idNebD[n];
    if (InLatt (ivn.x) && InLatt (ivn.y)) {
      dr = r - GetR (vec2 (ivn));
      f += 5. * fSpring * (spLenD - length (dr)) * normalize (dr) -
         fDamp * (v - GetV (vec2 (ivn)));
    }
  }
}

#define InLatt2(t, k) (k == 0 && t > 1 || k == 2 && t < nBallE - 2 || k == 1 && (t > 0 && t < nBallE - 1))

void BendForce (ivec2 iv, vec3 r, inout vec3 f)
{
  vec3 dr1, dr2, rt;
  ivec2 ivd;
  float s, c11, c22, c12, cd, fBend;
  fBend = 500.;
  for (int nd = 0; nd < 2; nd ++) {
    ivd = (nd == 0) ? ivec2 (1, 0) : ivec2 (0, 1);
    for (int k = 0; k < 3; k ++) {
      if (nd == 0 && InLatt2 (iv.x, k) || nd == 1 && InLatt2 (iv.y, k)) {
        if (k == 0) {
          rt = GetR (vec2 (iv - ivd));
          dr1 = rt - GetR (vec2 (iv - 2 * ivd));
          dr2 = r - rt;
          s = -1.;
        } else if (k == 2) {
          rt = GetR (vec2 (iv + ivd));
          dr1 = rt - r;
          dr2 = GetR (vec2 (iv + 2 * ivd)) - rt;
          s = -1.;
        } else {
          dr1 = r - GetR (vec2 (iv - ivd));
          dr2 = GetR (vec2 (iv + ivd)) - r;
          s = 1.;
        }
        c11 = 1. / dot (dr1, dr1);
        c12 = dot (dr1, dr2);
        c22 = 1. / dot (dr2, dr2);
        cd = sqrt (c11 * c22);
        s *= fBend * cd * (c12 * cd - 1.);
        if (k <= 1) f += s * (dr1 - c12 * c22 * dr2);
        if (k >= 1) f += s * (c12 * c11 * dr1 - dr2);
      }
    }
  }
}

void PairForce (ivec2 iv, vec3 r, inout vec3 f)
{
  vec3 dr;
  float rSep;
  int nx, ny;
  nx - 0;
  ny = 0;
  for (int n = 0; n < nBall; n ++) {
    dr = r - GetR (vec2 (nx, ny));
    rSep = length (dr);
    if (rSep > 0.01 && rSep < 1.) f += fOvlap * (1. / rSep - 1.) * dr;
    if (++ nx == nBallE) {
      nx = 0;
      ++ ny;
    }  
  }
}

void WallForce (vec3 r, inout vec3 f)
{
  vec3 dr;
  dr = hbLen - abs (r);
  f -= step (dr, vec3 (1.)) * fOvlap * sign (r) * (1. / abs (dr) - 1.) * dr;
}

void ObsForce (vec3 r, inout vec3 f)
{
  vec3 dr;
  float rSep;
  for (float fz = -1.; fz <= 1.; fz += 2.) {
    for (float fy = -1.; fy <= 1.; fy += 2.) {
      for (float fx = -1.; fx <= 1.; fx += 2.) {
        dr = r - 0.4 * hbLen * vec3 (fx, fy, fz);
        rSep = length (dr) - 0.2 * hbLen;
        if (rSep < 1.) f += fOvlap * (1. - rSep) * normalize (dr);
      }
    }
  }
}

void Step (ivec2 iv, out vec3 r, out vec3 v)
{
  vec3 f;
  float fDamp, grav, dt;
  IdNebs ();
  fOvlap = 1000.;
  fDamp = 0.5;
  grav = 2.;
  r = GetR (vec2 (iv));
  v = GetV (vec2 (iv));
  f = vec3 (0.);
  PairForce (iv, r, f);
  SpringForce (iv, r, v, f);
  BendForce (iv, r, f);
  WallForce (r, f);
  ObsForce (r, f);
  f -= vec3 (0., grav, 0.) * QtToRMat (qtVu) + fDamp * v;
  dt = 0.02;
  v += dt * f;
  r += dt * v;
}

vec3 VInit (int n)
{
  float fn;
  fn = float (n);
  return 2. * normalize (vec3 (Hashff (fn), Hashff (fn + 0.3),
     Hashff (fn + 0.6)) - 0.5);
}

void OrientVu (inout vec4 qtVu, vec4 mPtr, inout vec4 mPtrP, bool init)
{
  vec3 vq1, vq2;
  vec2 dm;
  float mFac;
  if (! init) {
    qtVu = vec4 (0., 0., 0., 1.);
    mPtrP = vec4 (99., 0., -1., 0.);
  } else {
    if (mPtr.z > 0.) {
      if (mPtrP.x == 99.) mPtrP = mPtr;
      mFac = 1.5;
      dm = - mFac * mPtrP.xy;
      vq1 = vec3 (dm, sqrt (max (1. - dot (dm, dm), 0.)));
      dm = - mFac * mPtr.xy;
      vq2 = vec3 (dm, sqrt (max (1. - dot (dm, dm), 0.)));
      qtVu = normalize (QtMul (vec4 (cross (vq1, vq2), dot (vq1, vq2)), qtVu));
      mPtrP = mPtr;
    } else mPtrP = vec4 (99., 0., -1., 0.);
  }
}

void Init (ivec2 iv, out vec3 r, out vec3 v)
{
  vec3 vSum;
  for (int iy = 0; iy < nBallE; iy ++) {
    for (int ix = 0; ix < nBallE; ix ++) {
      if (iv.x == ix && iv.y == iy) {
        r = 0.97 * spLen * vec3 (ix, iy, 0.);
        r.xy -= 0.5 * (float (nBallE) - 1.);
      }
    }
  }
  v = VInit (iv.y * nBallE + iv.x);
  vSum = vec3 (0.);
  for (int n = 0; n < nBall; n ++) vSum += VInit (n);
  v -= vSum / float (nBall);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 mPtr, mPtrP, stDat;
  vec3 p, r, v;
  ivec2 pxIv, iv;
  float tCur;
  int mId, pxId;
  pxIv = ivec2 (fragCoord);
  pxId = pxIv.x + 2 * nBallE * pxIv.y;
  if (pxIv.x >= 2 * nBallE || pxId > 2 * nBall + 2) discard;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / iResolution.xy - 0.5;
  qtVu = Loadv4 (vec2 (1, nBallE));
  mPtrP = Loadv4 (vec2 (2, nBallE));
  iv = pxIv;
  if (iv.x >= nBallE) iv.x -= nBallE;
  mId = iv.y * nBallE + iv.x;
  if (iFrame <= 5) {
    spLen = 1.1;
    hbLen = 0.55 * spLen * float (nBallE - 1);
    OrientVu (qtVu, mPtr, mPtrP, false);
    ntStep = 0.;
    if (mId < nBall) {
      Init (iv, r, v);
      p = (pxIv.x >= nBallE) ? v : r;
    }
  } else {
    OrientVu (qtVu, mPtr, mPtrP, true);
    stDat = Loadv4 (vec2 (0, nBallE));
    spLen = stDat.x;
    hbLen = stDat.y;
    ntStep = stDat.w;
    ++ ntStep;
    if (mPtrP.z < 0.) qtVu = normalize (QtMul (EulToQt (0.004 *
       pi * vec3 (-0.27, 0.34, 0.11)), qtVu));
    
    if (mId < nBall) {
      Step (iv, r, v);
      p = (pxIv.x >= nBallE) ? v : r;
    }
  }
  if (pxId < 2 * nBall) stDat = vec4 (p, 0.);
  else if (pxId == 2 * nBall) stDat = stDat = vec4 (spLen, hbLen, tCur, ntStep);
  else if (pxId == 2 * nBall + 1) stDat = qtVu;
  else if (pxId == 2 * nBall + 2) stDat = mPtrP;
  Savev4 (vec2 (pxIv), stDat, fragColor, fragCoord);
}

vec4 QtMul (vec4 q1, vec4 q2)
{
  return vec4 (
     q1.w * q2.x - q1.z * q2.y + q1.y * q2.z + q1.x * q2.w,
     q1.z * q2.x + q1.w * q2.y - q1.x * q2.z + q1.y * q2.w,
   - q1.y * q2.x + q1.x * q2.y + q1.w * q2.z + q1.z * q2.w,
   - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z + q1.w * q2.w);
}

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  q = normalize (q);
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

vec4 EulToQt (vec3 e)
{
  float a1, a2, a3, c1, s1;
  a1 = 0.5 * e.y;  a2 = 0.5 * (e.x - e.z);  a3 = 0.5 * (e.x + e.z);
  s1 = sin (a1);  c1 = cos (a1);
  return normalize (vec4 (s1 * cos (a2), s1 * sin (a2), c1 * sin (a3),
     c1 * cos (a3)));
}

float Hashff (float p)
{
  const float cHashM = 43758.54;
  return fract (sin (p) * cHashM);
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

vec4 Loadv4 (vec2 vId)
{
  return texture (txBuf, (vId + 0.5) / txSize);
}

void Savev4 (vec2 vId, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  vec2 d = abs (fCoord - vId - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}
