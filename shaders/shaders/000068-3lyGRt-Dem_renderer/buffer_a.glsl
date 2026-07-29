// Buffer A (buffer) — Dem renderer by iapafoto
// https://www.shadertoy.com/view/3lyGRt

// Mouse control
//----------------------------------------------

const float pi = 3.14159;


vec4 Loadv4 (int idVar)
{
  float fi = float (idVar);
  return texture (iChannel0, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     iChannelResolution[0].xy);
}
/*
vec4 QtMul(vec4 q1, vec4 q2) {
    return vec4(cross(q1.xyz,q2.xyz) + q1.w*q2.xyz + q2.w*q1.xyz, q1.w*q2.w - dot(q1.xyz,q2.xyz));
}
*/

vec4 QMul (vec4 q1, vec4 q2)
{
  return vec4 (
     q1.w * q2.x - q1.z * q2.y + q1.y * q2.z + q1.x * q2.w,
     q1.z * q2.x + q1.w * q2.y - q1.x * q2.z + q1.y * q2.w,
   - q1.y * q2.x + q1.x * q2.y + q1.w * q2.z + q1.z * q2.w,
   - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z + q1.w * q2.w);
}


vec4 EulToQ (vec3 e)
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


vec4 qtVu;


vec3 VInit (int n)
{
  float fn;
  fn = float (n);
  return 2. * normalize (vec3 (Hashff (fn), Hashff (fn + 0.3),
     Hashff(fn + 0.6)) - 0.5);
}

void OrientVu (inout vec4 qtVu, vec4 mPtr, inout vec4 mPtrP, bool init)
{
  vec3 vq1, vq2;
  vec2 dm;
  float mFac;
    
  if (! init) {
    qtVu = vec4 (0., 0., 0., 1.);
    mPtrP = vec4 (99.,0., -1., 0.);
      
  } else {
      
    if (mPtr.z > 0.) {
      if (mPtrP.x == 99.) mPtrP = mPtr;
      mFac = 1.5;
      dm = - mFac * mPtrP.xy;
      vq1 = vec3 (dm, sqrt (max (1. - dot (dm, dm), 0.)));
      dm = - mFac * mPtr.xy;
      vq2 = vec3 (dm, sqrt (max (1. - dot (dm, dm), 0.)));
      qtVu = normalize(QMul(vec4(cross (vq1, vq2), dot (vq1, vq2)), qtVu));
      mPtrP = mPtr;
    } else {
        mPtrP = vec4 (99., 0., -1., 0.);
    }
  }
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 mPtr, mPtrP, stDat;
  float tCur;
  int pxId = int(fragCoord.x);
 
  if (pxId > 2) discard;
    
  tCur = 5.*(1.+.5*sin(.5*iTime))+2.*iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / iResolution.xy - 0.5;
    
  qtVu = Loadv4 (1);
  mPtrP = Loadv4 (2);
  
  if (iFrame < 10) {
    OrientVu(qtVu, mPtr, mPtrP, false);
   
  } else {
      
    OrientVu (qtVu, mPtr, mPtrP, true);
    stDat = Loadv4(0);
    ++stDat.x;
      
    if (mPtrP.z < 0.) 
        qtVu = normalize(QMul (EulToQ (0.2 * (tCur - stDat.z) * pi * vec3 (-0.27, -0.34, -0.11)), qtVu));
      
    stDat.z = tCur;
  }

  if (pxId == 1) stDat = qtVu;
  else if (pxId == 2) stDat = mPtrP;
        
  Savev4 (pxId, stDat, fragColor, fragCoord);
}
