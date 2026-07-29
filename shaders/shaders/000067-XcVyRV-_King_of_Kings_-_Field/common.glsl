// Common (common) — [♪]King of Kings - Field by Catzpaw
// https://www.shadertoy.com/view/XcVyRV

//==================================================
// King of Kings - Field
// Common:settings

#define BPM 112.68
#define FAR 40.
#define ZERO min(0,iFrame)
const float pi=acos(-1.);
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}
