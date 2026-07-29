// Common (common) — Moon voxels by nimitz
// https://www.shadertoy.com/view/tdlSR8

// Moon voxels
// by nimitz 2019 (twitter: @stormoid)
// https://www.shadertoy.com/view/tdlSR8
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

//Utility hash and noise functions here

vec2 hash2(uint x)
{
    uvec2 p = x * uvec2(3266489917U, 668265263U);
    p = (p.x ^ p.y) *  uvec2(2654435761U, 2246822519U);
    return vec2(p)*2.3283064365386962890625e-10;
}

float hash12(vec2 p)
{
    p  = 50.*fract( p*0.3183099 + vec2(0.71,0.113));
    return fract( p.x*p.y*(p.x+p.y) )*1.8-0.6;
}

vec3 hash33(vec3 p)
{
    p = fract(p * vec3(443.8975,397.2973, 491.1871));
    p += dot(p.zxy, p.yxz+19.27);
    return fract(vec3(p.x * p.y, p.z*p.x, p.y*p.z));
}

float valueNoise(vec2 p)
{
    vec2 ip = floor(p);
    vec2 fp = fract(p);
	vec2 ramp = fp*fp*(3.0-2.0*fp);

    float rz= mix( mix( hash12(ip + vec2(0.0,0.0)), hash12(ip + vec2(1.0,0.0)), ramp.x),
                   mix( hash12(ip + vec2(0.0,1.0)), hash12(ip + vec2(1.0,1.0)), ramp.x), ramp.y);
    
    return rz;
}
