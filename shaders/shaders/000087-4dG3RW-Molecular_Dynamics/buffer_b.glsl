// Buffer B (buffer) — Molecular Dynamics by dr2
// https://www.shadertoy.com/view/4dG3RW

// "Molecular Dynamics" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy
#define mPtr iMouse

float Hashff (float p)
{
  const float cHashM = 43758.54;
  return fract (sin (p) * cHashM);
}

const float txRow = 32.;

vec4 Loadv4 (int idVar)
{
  float fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  float fi = float (idVar);
  vec2 d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}

const int nMolEdge = 20;
const int nMol = nMolEdge * nMolEdge;
float bFac;

vec4 Step (int mId)
{
  vec4 p, pp;
  vec2 dr, f;
  float rr, rri, rri3, rCut, rrCut, bLen, dt;
  f = vec2 (0.);
  p = Loadv4 (mId);
  rCut = pow (2., 1./6.);
  rrCut = rCut * rCut;
  for (int n = 0; n < nMol; n ++) {
    pp = Loadv4 (n);
    dr = p.xy - pp.xy;
    rr = dot (dr, dr);
    if (n != mId && rr < rrCut) {
      rri = 1. / rr;
      rri3 = rri * rri * rri;
      f += 48. * rri3 * (rri3 - 0.5) * rri * dr;
    }
  }
  bLen = bFac * float (nMolEdge);
  dr = 0.5 * (bLen + rCut) - abs (p.xy);
  if (dr.x < rCut) {
    if (p.x > 0.) dr.x = - dr.x;
    rri = 1. / (dr.x * dr.x);
    rri3 = rri * rri * rri;
    f.x += 48. * rri3 * (rri3 - 0.5) * rri * dr.x;
  }
  if (dr.y < rCut) {
    if (p.y > 0.) dr.y = - dr.y;
    rri = 1. / (dr.y * dr.y);
    rri3 = rri * rri * rri;
    f.y += 48. * rri3 * (rri3 - 0.5) * rri * dr.y;
  }
  dt = 0.005;
  p.zw += dt * f;
  p.xy += dt * p.zw;
  return p;
}

vec4 Init (int mId)
{
  vec4 p;
  float x, y, t, vel;
  const float pi = 3.14159;
  y = float (mId / nMolEdge);
  x = float (mId) - float (nMolEdge) * y;
  t = 0.25 * (2. * mod (y, 2.) - 1.);
  p.xy = (vec2 (x + t, y) - 0.5 * float (nMolEdge - 1));
  t = 2. * pi * Hashff (float (mId));
  vel = 3.;
  p.zw = vel * vec2 (cos (t), sin (t));
  return p;
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 stDat, p;
  int mId;
  vec2 kv = floor (fragCoord);
  mId = int (kv.x + txRow * kv.y);
  if (kv.x >= txRow || mId > nMol) discard;
  if (iFrame <= 5) {
    bFac = 1.1;
    stDat = vec4 (0., bFac, 0., 0.);
    if (mId < nMol) p = Init (mId);
  } else {
    stDat = Loadv4 (nMol);
    ++ stDat.x;
    bFac = stDat.y;
    if (mId < nMol) p = Step (mId);
    if (mPtr.z > 0. && stDat.x > 50.) {
      stDat.x = 0.;
      p = Init (mId);
    }
  }
  Savev4 (mId, ((mId < nMol) ? p : stDat), fragColor, fragCoord);
}
