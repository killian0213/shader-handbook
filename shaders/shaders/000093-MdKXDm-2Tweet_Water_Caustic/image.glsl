// Image (image) — 2Tweet Water Caustic by Dave_Hoskins
// https://www.shadertoy.com/view/MdKXDm

// A simple water caustic effect.
// David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Inspired by akohdr's "Fluid Fields"
// https://www.shadertoy.com/view/XsVSDm

#define F length(.5-fract(k.xyw*=mat3(-2,-1,2, 3,-2,1, 1,2,2)*

void mainImage(out vec4 k, vec2 p)
{
    k.xy = p*(sin(k=iDate*.2).w+2.)/2e2;
    k = pow(min(min(F.5)),F.4))),F.3))), 7.)*25.+vec4(0,.35,.5,1);
}
