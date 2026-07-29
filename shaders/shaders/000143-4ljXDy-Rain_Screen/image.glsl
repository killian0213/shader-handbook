// Image (image) — Rain Screen by jt
// https://www.shadertoy.com/view/4ljXDy

// https://www.shadertoy.com/view/4ljXDy Rain Screen - written 2015 by Jakob Thomsen
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


#define pi 3.1415926

// iq's hash function from https://www.shadertoy.com/view/MslGD8
vec2 hash( vec2 p ) { p=vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))); return fract(sin(p)*18.5453); }

float grid_noise(float t, vec2 v)
{
    float s = 1.0 / 256.0;
    vec2 fl = floor(v), fr = fract(v);
    float mindist = 1e9;
    for(int y = -1; y <= 1; y++)
        for(int x = -1; x <= 1; x++)
        {
            vec2 offset = vec2(x, y);
            vec2 pos = 0.5 + 0.5 * cos(2. * pi * (t*0.1 + hash(fl+offset)) + vec2(0,1.6));
            mindist = min(mindist, length(pos+offset -fr));
        }
    
    return mindist;
}

float blob_noise(float t, vec2 v, float s)
{
    return pow(0.5 + 0.5 * cos(pi * clamp(grid_noise(t, v)*2.0, 0.0, 1.0)), s);
}

vec3 blob_noise_normal(float t, vec2 v, float s)
{
    vec2 e = vec2(.01,0);
    return normalize(
           vec3(blob_noise(t, v + e.xy, s) - blob_noise(t, v -e.xy, s),
                blob_noise(t, v + e.yx, s) - blob_noise(t, v -e.yx, s),
                1.0));
}

float blob_noises(float t, vec2 p, float s)
{
    float h = 0.0;
    const float n = 3.0;
    for(float i = 0.0; i < n; i++)
    {
        vec2 p = vec2(0.0, 1.0 * t * (i + 1.0) / n) + 1.0 * p;
    	h += pow(0.5 + 0.5 * cos(pi * clamp(grid_noise(t, p * (i + 1.0)) * 2.0, 0.0, 1.0)), s);
    }
    
    return h / n;
}

vec3 blob_noises_normal(float t, vec2 p, float s)
{
    float d = 0.01;
    return normalize(
           vec3(blob_noises(t, p + vec2(  d, 0), s) - blob_noises(t, p + vec2( -d, 0), s),
                blob_noises(t, p + vec2(0,   d), s) - blob_noises(t, p + vec2(0,  -d), s),
                d));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t = iTime;

    vec2 r = vec2(1, iResolution.y / iResolution.x);
	vec2 p = fragCoord.xy / iResolution.xy;
    vec3 n = blob_noises_normal(t, 25.0 * p * r, 1.0);
    fragColor = texture(iChannel0, p + 0.05 * n.xy);
}

/*
vec2 drop(vec2 uv, vec2 pos, float r)
{
    pos.y = fract(pos.y);
    if(length(uv - pos) > r)
        return vec2(0.0, 0.0);
    
    vec3 n = normalize(vec3(uv - pos, r));
    
    return n.xy;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 uv2 = vec2(uv.x * iResolution.x / iResolution.y, uv.y);
    
    vec2 d = vec2(0.0, 0.0);
    const int n = 10000; // NOTE: simpler but MUCH SLOWER version!
    for(int i = 0; i < n; i++)
    {
        vec4 r = texture(iChannel1, vec2(float(i) / float(n), 0.5));
        vec2 pos = r.xy;
        pos.x *= iResolution.x / iResolution.y;
        pos.y -= 10.0 * iTime * 0.02 * r.a;
        //pos.x += sin(t + r.z);
    	d += 0.01 * drop(uv2.xy, pos, 0.03); // * step(fract(pos.y), r.z);
    }

	fragColor = texture(iChannel0, -uv.xy + d);
    //if(length(d) > 0.0) fragColor.rgb *= 0.5;
    
}
*/
