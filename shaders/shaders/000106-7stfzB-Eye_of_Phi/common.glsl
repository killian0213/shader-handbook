// Common (common) — Eye of Phi by ChunderFPV
// https://www.shadertoy.com/view/7stfzB

#define SCALE 8.0
#define R iResolution.xy
#define PI radians(180.0)
#define TAU (PI*2.0)
#define CS(a) vec2(cos(a), sin(a))
#define PT(u,r) smoothstep(0.0, r, r-length(u))

// gradient map ( color, equation, time, width, shadow, reciprocal )
vec3 gm(vec3 c, float n, float t, float w, float d, bool i)
{
    float g = min(abs(n), 1.0/abs(n));
    float s = abs(sin(n*PI-t));
    if (i) s = min(s, abs(sin(PI/n+t)));
    return (1.0-pow(abs(s), w))*c*pow(g, d)*6.0;
}

// denominator spiral, use 1/n for numerator
// ( screen xy, spiral exponent, decimal, line width, hardness, rotation )
float ds(vec2 u, float e, float n, float w, float h, float ro)
{
    float ur = length(u); // unit radius
    float sr = pow(ur, e); // spiral radius
    float a = round(sr)*n*TAU; // arc
    vec2 xy = CS(a+ro)*ur; // xy coords
    float l = PT(u-xy, w); // line
    float s = mod(sr+0.5, 1.0); // gradient smooth
    s = min(s, 1.0-s); // darken filter
    return l*s*h;
}
