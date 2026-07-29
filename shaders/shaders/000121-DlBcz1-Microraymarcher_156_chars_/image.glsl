// Image (image) — Microraymarcher (156 chars) by iq
// https://www.shadertoy.com/view/DlBcz1

// The MIT License
// Copyright © 2023 Inigo Quilez
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// A raymarching shader using no more than the two input variables
// Original was 161 chars long. -1 by SnoopethDuckDuck. -4 chars by Xor.

void mainImage(out vec4 p,vec2 f){for(
p=vec4(f/iResolution.y,1,0)-.6;                                  // First set up camera
f.x-->0.;                                                        // Then while not done
p*=.9+.1*length(cos(.7*p.x+vec3(p.z+iTime,p)))+.01*cos(4.*p.y)); // march forward
p=(p+p.z)*.1;}                                                   // Finally, do color



// Basic idea:
//
// p += f(p)*rd              Start with a regular SDF raymarcher
// p += f(p)*normalized(p)   and note ray direction is normalized position.
// p += f(p)*p/p.z           But our Signed Field f(p) need NOT be an SDF,
// p += f(p)*p*step          so we migh as well use a constant here.
// p *= 1+f(p)*step          Then factor out ray position.
// p *= (1-k*step)+step*g(p) Now, if f(p) has some level set constant k,
//                           f(p)=g(p)-k, we can propagate it out of f(p).
//
// Notes:
//
// +4 chars, to fix clipping issue:       p=.1*vec4(f/iResolution.y,1,0)-.06;
// +2 chars, to fix screen-left issue:    f.x-->-2e2;
// +2 chars, to fix compatibility issues: vec3(p.z+iTime,p.xy)
//
// These fixes above applied makes 165 chars:
//
// void mainImage(out vec4 p,vec2 f){for(
// p=.1*vec4(f/iResolution.y,1,0)-.06;
// f.x-->-2e2;
// p*=.9+.1*length(cos(.7*p.x+vec3(p.z+iTime,p.xy)))+.01*cos(4.*p.y));
// p=(p+p.z)*.1;}