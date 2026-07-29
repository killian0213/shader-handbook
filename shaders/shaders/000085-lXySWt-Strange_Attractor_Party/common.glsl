// Common (common) — Strange Attractor Party by leon
// https://www.shadertoy.com/view/lXySWt


mat2 rot (float a) { float c=cos(a),s=sin(a);return mat2(c,-s,s,c); }
float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }
float fbm (vec3 seed)
{
    float result = 0., a = .5;
    for (int i = 0; i < 3; ++i, a/=2.)
    {
        result += (gyroid(seed/a))*a;
    }
    return result;
}


float easeInOut (float x)
{
    return x * x * (3. - 2. * x);
}

// https://suricrasia.online/blog/shader-functions/
vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax, p)*ax, p, cos(ro)) + cross(ax,p)*sin(ro);
}
vec3 rndrot(vec3 p, vec4 rnd) {
  return erot(p, normalize(tan(rnd.xyz)), rnd.w*acos(-1.));
}

// https://iquilezles.org/articles/distfunctions2d/
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

// Dave Hoskins https://www.shadertoy.com/view/4djSRW
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}
vec4 hash41(float p)
{
	vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}