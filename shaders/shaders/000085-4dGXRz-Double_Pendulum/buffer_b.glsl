// Buffer B (buffer) — Double Pendulum by dr2
// https://www.shadertoy.com/view/4dGXRz

// "Double Pendulum" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float pi = 3.14159;
const float txRow = 32.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  vec2 d;
  float fi;
  fi = float (idVar);
  d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}

float nStep, gVal, mFrac, rLen1, rLen2, delT;
const int ntPoint = 120;

vec4 EvalRhs (vec4 s)
{
  vec4 f;
  float sd, cd, s1, s2, t;
  sd = sin (s.x - s.y);
  cd = cos (s.x - s.y);
  s1 = sin (s.x);
  s2 = sin (s.y);
  t = delT / (1. - mFrac * cd * cd);
  f.x = s.z * delT;
  f.y = s.w * delT;
  f.z = t * ((mFrac * cd * s2 - s1) * gVal / rLen1 -
     mFrac * sd * (cd * s.z * s.z + (rLen2 / rLen1) * s.w * s.w));
  f.w = t * ((cd * s1 - s2) * gVal / rLen2 +
     mFrac * cd * sd * s.w * s.w + (rLen1 / rLen2) * sd * s.z * s.z);
  return f;
}

void Step (inout vec4 s)
{
  vec4 k1, k2, k3, k4;
  k1 = EvalRhs (s);
  k2 = EvalRhs (s + k1 / 2.);
  k3 = EvalRhs (s + k2 / 2.);
  k4 = EvalRhs (s + k3);
  s += (k1 + k4) / 6. + (k2 + k3) / 3.;
  s.xy = mod (s.xy + pi, 2. * pi) - pi;
}

float Eng (vec4 s)
{
  float c1, c2;
  c1 = cos (s.x);
  c2 = cos (s.y);
  return 0.5 * ((1. - mFrac) * rLen1 * rLen1 * s.z * s.z + 
     mFrac * (rLen1 * rLen1 * s.z * s.z + rLen2 * rLen2 * s.w * s.w +
     2. * rLen1 * rLen2 * cos (s.x - s.y) * s.z * s.w)) +
     gVal * ((1. - mFrac) * rLen1 * (1. - c1) +
     mFrac * (rLen1 * (1. - c1) + rLen2 * (1. - c2)));
}

vec2 TPoint (vec4 s)
{
  return rLen1 * vec2 (sin (s.x), cos (s.x)) +
         rLen2 * vec2 (sin (s.y), cos (s.y));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 wgBx[4], mPtr, mPtrP, stDat, slVal, r;
  vec2 iFrag, canvas, ust, tPoint;
  float asp, vW, parmL, parmM, parmV1, parmV2, eTot, el, az;
  int pxId, wgSel, wgReg, kSel;
  bool doInit;
  canvas = iResolution.xy;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= 4 + ntPoint) discard;
  delT = 0.005;
  gVal = 10.;
  doInit = false;
  wgReg = -2;
  if (iFrame <= 5) {
    parmL = 0.6;
    parmM = 0.5;
    parmV1 = -6.;
    parmV2 = 6.;
    slVal.x = 0.5 + (parmL - 1.) * ((parmL >= 1.) ? 1. : 5.) / 8.;
    slVal.y = 0.5 + (parmM - 1.) * ((parmM >= 1.) ? 1. : 5.) / 8.;
    slVal.z = 0.5 - parmV1 / 20.;
    slVal.w = 0.5 - parmV2 / 20.;
    mPtrP = mPtr;
    wgSel = -1;
    doInit = true;
  } else {
    nStep = Loadv4 (0).x;
    r = Loadv4 (1);
    slVal = Loadv4 (2);
    stDat = Loadv4 (3);
    mPtrP = vec4 (stDat.xyz, 0.);
    wgSel = int (stDat.w);
  }
  asp = canvas.x / canvas.y;
  if (mPtr.z > 0.) {
    wgBx[0] = vec4 (-0.45 * asp, 0., 0.012 * asp, 0.18);
    wgBx[1] = vec4 (-0.35 * asp, 0., 0.012 * asp, 0.18);
    wgBx[2] = vec4 ( 0.35 * asp, 0., 0.012 * asp, 0.18);
    wgBx[3] = vec4 ( 0.45 * asp, 0., 0.012 * asp, 0.18);
    for (int k = 0; k < 4; k ++) {
      ust = abs (mPtr.xy * vec2 (asp, 1.) - wgBx[k].xy) - wgBx[k].zw;
      if (max (ust.x, ust.y) < 0.) wgReg = k;
    }
    if (mPtrP.z <= 0.) wgSel = wgReg;
  } else {
    wgSel = -1;
    wgReg = -2;
  }
  el = 0.;
  az = 0.;
  if (wgSel < 0) {
    if (mPtr.z > 0.) {
      el +=  pi * mPtr.y;
      az += 2. * pi * mPtr.x;
    }
  } else {
    for (int k = 0; k < 4; k ++) {
      if (wgSel == k) {
        kSel = k;
        vW = clamp (0.5 + 0.5 * (mPtr.y - wgBx[k].y) / wgBx[k].w, 0.01, 0.99);
        break;
      }
    }
    if      (kSel == 0) slVal.x = vW;
    else if (kSel == 1) slVal.y = vW;
    else if (kSel == 2) slVal.z = vW;
    else if (kSel == 3) slVal.w = vW;
    doInit = true;
  }
  parmL = (slVal.x - 0.5) * ((slVal.x >= 0.5) ? 1. : 1. / 5.) * 8. + 1.;
  parmM = (slVal.y - 0.5) * ((slVal.y >= 0.5) ? 1. : 1. / 5.) * 8. + 1.;
  parmV1 = - (slVal.z - 0.5) * 20.;
  parmV2 = - (slVal.w - 0.5) * 20.;
  if (doInit) {
    r = vec4 (0., 0., parmV1, parmV2);
    nStep = 0.;
  }
  rLen1 = 1. / (1. + parmL);
  rLen2 = 1. - rLen1;
  mFrac = parmM / (1. + parmM);
  if (! doInit) {
    Step (r);
    ++ nStep;
  }
  eTot = Eng (r);
  if (pxId == 4) tPoint = TPoint (r);
  else if (pxId > 4) {
    if (doInit) tPoint = vec2 (0.);
    else {
      if (mod (nStep, 5.) == 0.) tPoint = Loadv4 (pxId - 1).xy;
      else tPoint = Loadv4 (pxId).xy;
    }
  }
  if (pxId == 0) stDat = vec4 (nStep, eTot, el, az);
  else if (pxId == 1) stDat = r;
  else if (pxId == 2) stDat = slVal;
  else if (pxId == 3) stDat = vec4 (mPtr.xyz, float (wgSel));
  else stDat = vec4 (tPoint, 0., 0.);
  Savev4 (pxId, stDat, fragColor, fragCoord);
}
