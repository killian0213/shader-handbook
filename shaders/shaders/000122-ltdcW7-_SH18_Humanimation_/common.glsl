// Common (common) — [SH18]  Humanimation  by pellicus
// https://www.shadertoy.com/view/ltdcW7

// my SH18 Entry:  
// inspired by this ref https://www.youtube.com/watch?v=kT-I26uFv9M
// The idea is: 
// what ever you draw .. if it's animated like a human... becomes a human!
// i've tons of ideas to try and for sure could be an interesting starting
// point to make some demoscene stuff :D. at least for me.
//
// Animation: 
// 	Samba Dance fbx from www.mixamo.com 
// 	
// Music:
//	BarretoVSLujan Feat. Rozalla E Nikki - Everybody Free Samba (Edih Bueno Mega Mush! Work)
//
// bufA : playback and interpolation of the animation points (pin)
// bufB : modeling and rendering and very simple lighting of the scene
// Image: compositing with some little fx activated by camera change

// a lot of glitches, bugs to fix and to optimize but...i had a looot of fun
// making this stuff. In holydays, few minutes each morning before my 
// family woke up... i think i'll remember this experience for a loong time :D.
// thanks to the Shadertoy community... it's a gold mine of ideas, tricks and usefull code :D


// CONSTANTS

#define SQRT2 1.4142135623730950488016887242096980785696
#define PI    3.1415926535897932384626433832795
#define HPI   1.57079632679489661923132169
#define QPI   0.785398163397448309615660845819875721
#define TAU   6.283185307179586476925286766559
#define PI2   TAU

#define D2R(x) ((x)*0.0174532925)
#define R2D(x) ((x)*57.295779513)


#define PINS_NUM 20


#define ROOT 0

#define RHIP 1
#define RKNEE 2
#define RANKLE 3
#define RFOOT 4
//#define RTOE 5  removed and calculated on the fly

#define LHIP 6
#define LKNEE 7
#define LANKLE 8
#define LFOOT 9
//#define LTOE 10  removed and calculated on the fly

#define SPINE 11

#define NECK  12
#define HEAD  13

#define RSHOULDER 14
#define RELBOW 15
#define RHAND 16

#define LSHOULDER 17
#define LELBOW 18
#define LHAND 19
