// Buffer A (buffer) — MountainBytes: PPPP 4KiB Windows by mrange
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


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  // High resolution FBM
  //  Used for normal computation and raymarching of the detailed mountain
  vec3 col = fbm(p, 6);
  
  fragColor = vec4(col, 1.0);
}