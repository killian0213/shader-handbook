// Image (image) — Floppy Sheet by dr2
// https://www.shadertoy.com/view/MlVSz1

// "Floppy Sheet" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  A non-self-intersecting sheet.

  Mouse stops/controls box rotation.

  Shadows are costly and are not included.

  Set LBIG = 1 in all the shaders for higher resolution.

  Surface rendering adapted from implicit kd-tree traversal in "curtain and ball"
  by archee.
*/

float PrBoxDf (vec3 p, vec3 b);
mat3 QtToRMat (vec4 q);
float Fbm2 (vec2 p);
vec4 Loadv4 (vec2 vId);

#define LBIG 0
#if LBIG
const int nBallE = 65;
const int nBall = nBallE * nBallE;
#else
const int nBallE = 33;
const int nBall = nBallE * nBallE;
#endif

const vec2 bGrid = vec2 (nBallE - 1, nBallE - 1);
vec3 ltDir, vnBall, rdSign;
vec2 qgHit;
float dstFar, hbLen, spLen;
int idObj;

vec3 GetR (vec2 v)
{
  return Loadv4 (v).xyz;
}

float SheetRay (vec3 ro, vec3 rd)
{
  vec3 r;
  vec2 g;
  float d, dMin, sz, szMax, szMin, grLen;
  bvec2 ilt;
  bool bkTrak;
  dMin = dstFar;
  grLen = 0.92 * spLen;
  szMax = max (bGrid.x, bGrid.y);
  szMin = 1./16.;
  g = vec2 (0.);
  bkTrak = false;
  sz = szMax;
  for (int ns = 0; ns < 2000; ns ++) {
    if (sz == szMin) {
      r = GetR (g) - ro;
      if (length (cross (r, rd)) < sz * grLen) {
        d = dot (rd, r);
        if (d < dMin) {
          dMin = d;
          qgHit = g;
        }
      }
      bkTrak = true;
    }
    bkTrak = bkTrak || (length (cross (GetR (g + 0.5 * sz) - ro, rd)) > sz * grLen);
    if (bkTrak) {
      bkTrak = false;
      ilt = lessThan (fract (g / (2. * sz)), vec2 (0.5));
      g.x += ilt.x ? sz : - sz;
      if (! ilt.x) {
        g.y += ilt.y ? sz : - sz;
        if (! ilt.y) {
          sz *= 2.;
          if (sz == szMax) break;
          bkTrak = true;
        }
      }
    } else if (sz > szMin) sz *= 0.5;
  }
  return dMin;
}

vec3 GetRC (vec2 v)
{
  return GetR (clamp (v, vec2 (0.), bGrid - 1.));
}

vec3 SheetNf () 
{
  vec2 e = vec2 (1., 0.);
  return normalize (cross (GetRC (qgHit + e.yx) - GetRC (qgHit - e.yx),
     GetRC (qgHit + e.xy) - GetRC (qgHit - e.xy)));
}

float BBallHit (vec3 ro, vec3 rd, float dMin)
{
  vec3 u;
  float rad, b, d, w;
  rad = 0.2 * hbLen + 0.7;
  for (float fz = -1.; fz <= 1.; fz += 2.) {
    for (float fy = -1.; fy <= 1.; fy += 2.) {
      for (float fx = -1.; fx <= 1.; fx += 2.) {
        u = ro - 0.4 * hbLen * vec3 (fx, fy, fz);
        b = dot (rd, u);
        w = b * b - (dot (u, u) - rad * rad);
        if (w >= 0.) {
          d = - b - sqrt (w);
          if (d > 0. && d < dMin) {
            dMin = d;
            vnBall = (u + d * rd) / rad;
          }
        }
      }
    }
  }
  return dMin;
}

float ObjDf (vec3 p)
{
  vec4 fVec;
  vec3 q, eLen, eShift;
  float dMin, d, eWid, sLen;
  dMin = dstFar;
  sLen = hbLen - 0.7;
  eWid = 0.04;
  eShift = vec3 (0., sLen, sLen);
  eLen = vec3 (sLen + eWid, eWid, eWid);
  fVec = sLen * vec4 (rdSign, 0.);
  d = min (min (PrBoxDf (p - fVec.xww, eLen.yxx),
     PrBoxDf (p - fVec.wyw, eLen.xyx)), PrBoxDf (p - fVec.wwz, eLen.xxy));
  if (d < dMin) { dMin = d;  idObj = 1; }
  q = abs (p);
  d = min (min (PrBoxDf (q - eShift, eLen), PrBoxDf (q - eShift.yxz, eLen.yxz)),
     PrBoxDf (q - eShift.yzx, eLen.yzx));
  if (d < dMin) { dMin = d;  idObj = 2; }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 50; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  const vec3 e = vec3 (0.001, -0.001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, w;
  vec2 b;
  float dstBall, dstObj, dstSheet, spec;
  dstBall = BBallHit (ro, rd, dstFar);
  rdSign = sign (rd);
  dstObj = ObjRay (ro, rd);
  dstSheet = SheetRay (ro, rd);
  if (min (min (dstBall, dstObj), dstSheet) < dstFar) {
    if (dstSheet < min (dstBall, dstObj)) {
      vn = SheetNf ();
      ro += rd * dstSheet;
      if (dot (rd, vn) < 0.) {
        col = vec3 (1., 0.6, 0.6);
      } else {
        col = vec3 (0.7, 1., 0.7);
        vn = - vn;
      }
      col = mix (col, vec3 (1., 1., 0.), 0.5 *
         smoothstep (0.2, 0.4, length (mod (0.125 * (qgHit + 0.5), vec2 (1.)) - 0.5)));
      b = abs (abs (0.5 * bGrid - qgHit) - 0.5 * bGrid);
      if (min (b.x, b.y) < 0.2) col = vec3 (0.7, 0.7, 0.2);
      spec = 0.1;
      col *= (1. - 0.3 * Fbm2 (0.5 * qgHit));
    } else if (dstBall < dstObj) {
      vn = vnBall;
      col = vec3 (0.4, 0.4, 0.7);
      spec = 0.1;
    } else if (dstObj < dstFar) {
      ro += rd * dstObj;
      vn = ObjNf (ro);
      if (idObj == 1) {
        w = smoothstep (0., 0.1, abs (fract (6. * ro / hbLen + 0.5) - 0.5));
        col = vec3 (mix (vec3 (0.4, 0.5, 0.4), vec3 (0.5, 0.5, 0.4),
           dot (abs (vn) * w.yzx * w.zxy, vec3 (1.))));
      } else if (idObj == 2) col = vec3 (0.4, 0.5, 0.4);
      spec = 0.2;
    }
    col = col * (0.4 + 0.6 * max (dot (vn, ltDir), 0.)) +
       spec * pow (max (0., dot (ltDir, reflect (rd, vn))), 32.);
  } else col = vec3 (0.);
  return clamp (col, 0., 1.);
}

float BlkHitSil (vec3 ro, vec3 rd)
{
  vec3 v, tm, tp;
  float dn, df, sLen;
  sLen = hbLen - 0.7;
  v = ro / rd;
  tp = sLen / abs (rd) - v;
  tm = - tp - 2. * v;
  dn = max (max (tm.x, tm.y), tm.z);
  df = min (min (tp.x, tp.y), tp.z);
  return (df > 0. && dn < df) ? dn : dstFar;
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 qtVu, stDat;
  vec3 col, rd, ro;
  vec2 canvas, uv;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  stDat = Loadv4 (vec2 (0, nBallE));
  spLen = stDat.x;
  hbLen = stDat.y;
  dstFar = 11. * hbLen;
  qtVu = Loadv4 (vec2 (1, nBallE));
  vuMat = QtToRMat (qtVu);
  rd = normalize (vec3 (uv, 3.5)) * vuMat;
  ro = vec3 (0., 0., -6. * hbLen) * vuMat;
  ltDir = normalize (vec3 (1., 1., -1.)) * vuMat;
  if (BlkHitSil (ro, rd) < dstFar) col = ShowScene (ro, rd);
  else col = vec3 (0., 0.05, 0.);
  fragColor = vec4 (pow (col, vec3 (0.8)), 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec4 t;
  vec2 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv4f (dot (ip, cHashA3.xy));
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
}

float Fbm2 (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

vec4 Loadv4 (vec2 vId)
{
  return texture (txBuf, (vId + 0.5) / txSize);
}
