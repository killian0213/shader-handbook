// Common (common) — Saturday weirdness by mrange
// https://www.shadertoy.com/view/43jXWt

// CC0: Saturday weirdness
//  I saw a tweet from Kali where I thought I understood how he did something cool.
//  Turns out I didn't understand . Instead ended up with weird stuff.

#define TIME        iTime
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)

#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

