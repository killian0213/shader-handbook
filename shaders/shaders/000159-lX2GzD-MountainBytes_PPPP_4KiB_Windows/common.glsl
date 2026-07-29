// Common (common) — MountainBytes: PPPP 4KiB Windows by mrange
// https://www.shadertoy.com/view/lX2GzD

// ----------------------------------------------
// CC0: Phosphorescent Purple Pixel Peaks
// ----------------------------------------------
//  `----- - --- ---------?\___/?\/zS!?\___/?\/-o
//                mrange & virgill              |
//  `----- - --- ------ -----\___/?\/!?\___/?\/-o
//                                              |
//   release: Phosphorescent Purple Pixel Peaks |
//      type: Windows 4k intro                  |
//      date: 17.02.2024                        |
//     party: Mountainbytes 2024                |
//                                              |
//                                              |
//  code: mrange                                |
//  music: Virgill                              |
//                                              |
//                                              |
// mrange - So, in this release, I set out to   |
// whip up a terrain marcher in a snug 4KiB     |
// space. Started with your usual terrain,      |
// thinking, "Let's give it a synthwave twist." |
// Now, my previous attempts at a synthwave-    |
// style terrain marcher were kinda meh, but    |
// guess what? Lightning struck, and I managed  |
// to sculpt some visually pleasing mountains.  |
//                                              |
// They're not a perfect match for the synthwave|
// vibe, but hey, check out these transparent,  |
// glowing ice cream peaks. Cool, right?        |
//                                              |
// Big shoutout to Virgill for dropping another |
// killer tune that totally catches the vibe.   |
// Sadly, we had to ditch some funky sound      |
// effects this time around—blame it on the     |
// space crunch. Fingers crossed, next time,    |
// we'll pack in the funk.                      |
//                                              |
// Oh, and a quick nod to sointu by our main    |
// man Pestis. This nifty tool churns out tunes |
// that sound fantastic, and even a music novice|
// like me could tinker around with its         |
// user-friendly tracker.                       |
//                                              |
// We're banking on you having a blast with our |
// creation, hoping it dishes out that feel-good|
// synthwave goodness. Cheers!                  |
//                                              |
//                                         _  .:!
//  <----- ----- -  -   -     - ----- ----\/----'

#define TIME        iTime
#define RESOLUTION  iResolution

const float 
  pi        = acos(-1.)
;

const vec3 
  Units     = vec3(0, 1, 1E-2)
;

mat2 rot(float a) {
  float c=cos(a),s=sin(a);
  return mat2(c,s,-s,c);
}

// License: Unknown, author: Unknown, found: don't remember
float hash2(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}


// License: MIT, author: Inigo Quilez, found: https://www.shadertoy.com/view/lsf3WH
//  Value noise function
float vnoise(vec2 p) {
 vec2 i = floor(p);
 vec2 f = fract(p);
    
 vec2 u = f*f*(3.-2.*f);

 float a = hash2(i);
 float b = hash2(i+Units.yx);
 float c = hash2(i+Units.xy);
 float d = hash2(i+Units.yy);
   
 float m0 = mix(a, b, u.x);
 float m1 = mix(c, d, u.x);
 float m2 = mix(m0, m1, u.y);
    
 return m2;
}


// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/articles/fbm/
//  Scales and rotates and aggregates multiple layers of value noise
//  to create something that looks like mountains
vec3 fbm(vec2 p, int ii) {
  vec2 np = p;
  vec2 cp = p;
  float nh = 0.0;
  float na = 1.0;
  float ns = 0.0;
  for (int i = 0; i < ii; ++i) {
    nh += na*vnoise(np);
    np += 123.4;
    np *= 2.11*rot(1.);
    ns += na;
    na *= 0.5;
  }
  
  nh /= ns;

  return vec3(nh);
}

