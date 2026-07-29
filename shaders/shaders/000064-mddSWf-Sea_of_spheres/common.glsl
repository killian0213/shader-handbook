// Common (common) — Sea of spheres by z0rg
// https://www.shadertoy.com/view/mddSWf

// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

#define sat(a) clamp(a, 0., 1.)

float hash11(float seed)
{
    return mod(sin(seed*123.456789)*123.456,1.);
}

vec3 getCam(vec3 rd, vec2 uv)
{
    float fov = .5;
    vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
    vec3 u = normalize(cross(rd, r));
    return normalize(rd+fov*(r*uv.x+u*uv.y));
}

vec2 _min(vec2 a, vec2 b)
{
    if (a.x < b.x)
        return a;
    return b;
}