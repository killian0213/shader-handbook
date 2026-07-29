// Common (common) — [SH18] Hoooman: Human head by ThomasSchander
// https://www.shadertoy.com/view/XttczS

float saturate(float x)
{
    return clamp(x, 0.0, 1.0);
}

vec2 saturate(vec2 x)
{
    return clamp(x, vec2(0.0), vec2(1.0));
}

float seed = 0.0;

float floatRand()
{
    return fract(sin(seed+=0.1)*43758.5453 );
}

vec2 floatRand2()
{
	return fract(sin(vec2(seed+=0.1,seed+=0.1))*vec2(43758.5453123,22578.1459123));
}

vec2 floatRand2(float fixedSeed)
{
	return fract(sin(vec2(fixedSeed, fixedSeed+0.1))*vec2(43758.5453123,22578.1459123));
}

vec3 floatRand3()
{
	return fract(sin(vec3(seed+=0.1,seed+=0.1,seed+=0.1))*vec3(43758.5453123,22578.1459123,19642.3490423));
}

vec2 signNotZero(vec2 v)
{
	return vec2((v.x >= 0.0) ? +1.0 : -1.0, (v.y >= 0.0) ? +1.0 : -1.0);
}

vec3 oct_to_float32x3(vec2 e) 
{
	vec3 v = vec3(e.xy, 1.0 - abs(e.x) - abs(e.y));
	if(v.z < 0.0) v.xy = (1.0 - abs(v.yx))*signNotZero(v.xy);
	return normalize(v);
}

vec2 PackNormals(in vec3 v)
{
	vec2 p = v.xy * (1.0 / (abs(v.x) + abs(v.y) + abs(v.z)));
	return (v.z <= 0.0) ? ((1.0 - abs(p.yx)) * signNotZero(p)) : p;
}
const float blendDistA = 0.486;
const vec3 VOL_DIMS = vec3(0.91, 0.83, 0.28); // WIDTH, HEIGHT; DEPTH