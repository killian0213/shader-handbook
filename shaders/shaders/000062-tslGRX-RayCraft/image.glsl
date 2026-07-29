// Image (image) — RayCraft by jolle
// https://www.shadertoy.com/view/tslGRX


#define MULTISAMPLES 1 // Max 4

const float pi = 3.1415926536;
const float fov = 2.2;
const float cloud_height = 18.0;
const float threshold = 0.5;
const float clouds_threshold = 0.525;
const float sun_movement = 0.1;
const vec3 eye_movement = vec3(-4.0, 0.0, -1.0);
const vec3 cloud_movement = vec3(-1.0, 0.0, -1.5);
const vec3 eye_start = vec3(-40.0, 10.0, 20.0);

vec3 sun_dir;
vec3 eye;
vec3 clouds_offset;

float sq(float x) { return x * x; }
float sq(vec2 x) { return dot(x, x); }
float sqi(float x) { return 1.0 - sq(1.0 - x); }
float sqi(vec2 x) { return 1.0 - sq(1.0 - x); }

vec3 background(vec3 d)
{
	const float sun_intensity = 1.0;
    vec3 sun = (pow(max(0.0, dot(d, sun_dir)), 48.0) + pow(max(0.0, dot(d, sun_dir)), 4.0) * 0.25) * sun_intensity * vec3(1.0, 0.85, 0.5);
    vec3 sky = mix(vec3(0.6, 0.65, 0.8), vec3(0.15, 0.25, 0.65), d.y) * 1.15;
    return sun + sky;
}

float noise(vec3 p)
{
    return textureLod(iChannel1, p, 0.0).x;
}

float cnoise(vec3 p)
{
    vec3 size = 1.0 / vec3(textureSize(iChannel1, 0));
    return (
        noise(p * size * 1.0 + vec3(0.52, 0.78, 0.43)) * 0.5 + 
        noise(p * size * 2.0 + vec3(0.33, 0.30, 0.76)) * 0.25 + 
        noise(p * size * 4.0 + vec3(0.70, 0.25, 0.92)) * 0.125) * 1.14;
}

bool voxel(vec3 vp)
{
    if (vp.y < cloud_height - 2.0)
        return cnoise(vp * 0.05) + vp.y * -0.02 > threshold; 
    return false;
}

bool cloudVoxel(vec3 vp)
{
    if (vp.y == cloud_height)
        return cnoise(vp * 0.2) > clouds_threshold;
        //return cnoise(vec3(vp.xz * 0.2, floor(iTime * 5.0) * 0.01)) > clouds_threshold; // Animated clouds, somewhat distracting
    return false;
}

struct TraceResult
{
    vec3 vp;
    vec3 p;
    vec3 n;
    float r;
    bool hit;
};

TraceResult traceVoxel(vec3 p, vec3 d, float dist)
{
    TraceResult r;
    r.hit = false;
    r.n = -d;
    r.r = dist;

    vec3 id = 1.0 / d;
    vec3 sd = sign(d);
    vec3 nd = max(-sd, 0.0);
    vec3 vp = floor(p) - nd * vec3(equal(floor(p), p));

    for (int i = 0; i < 128; ++i)
    {
        if (dist <= 0.0 || p.y > cloud_height && d.y > 0.0)
        	break;

        if (voxel(vp))
        {
			r.vp = vp;
			r.p = p;
			r.r = dist;
			r.hit = true;
			return r;
        }

        vec3 n = mix(floor(p + 1.0), ceil(p - 1.0), nd);
		vec3 ls = (n - p) * id;
		float l = min(min(ls.x, ls.y), ls.z);
		vec3 a = vec3(equal(vec3(l), ls));

        p = mix(p + d * l, n, a);
        vp += sd * a;
        r.n = -sd * a;
        dist -= l;
    }

    return r;
}

TraceResult traceClouds(vec3 p, vec3 d, float dist)
{
    TraceResult r;
    r.hit = false;
    r.n = -d;
    r.r = dist;
    
    p += clouds_offset;
    
    if (p.y < cloud_height && d.y > 0.0)
    {
        float c = (cloud_height - p.y) / d.y;
        p += d * c;
        r.n = vec3(0.0, -1.0, 0.0);        
        dist -= c;
    }
    else if (p.y > cloud_height + 1.0 && d.y < 0.0)
    {
        float c = (cloud_height + 1.0 - p.y) / d.y;
        p += d * c;
        r.n = vec3(0.0, 1.0, 0.0);
        dist -= c;
    }

    vec3 id = 1.0 / d;
    vec3 sd = sign(d);
    vec3 nd = max(-sd, 0.0);
    vec3 vp = floor(p) - nd * vec3(equal(floor(p), p));

    for (int i = 0; i < 16; ++i)
    {
        if (dist <= 0.0 || p.y < cloud_height && d.y < 0.0 || p.y > cloud_height + 1.0 && d.y > 0.0)
	        break;

        if (cloudVoxel(vp))
        {
			r.vp = vp;
			r.p = p - clouds_offset;
			r.r = dist;
			r.hit = true;
			return r;
        }

        vec3 n = mix(floor(p + 1.0), ceil(p - 1.0), nd);
		vec3 ls = (n - p) * id;
		float l = min(min(ls.x, ls.y), ls.z);
		vec3 a = vec3(equal(vec3(l), ls));

        p = mix(p + d * l, n, a);
        vp += sd * a;
        r.n = -sd * a;
        dist -= l;
    }

    return r;
}

float sample_ao(vec3 vp, vec3 p, vec3 n)
{
    const float s = 0.5;
    const float i = 1.0 - s;
    vec3 b = vp + n;
    vec3 e0 = n.zxy;
    vec3 e1 = n.yzx;
    float a = 1.0;
    if (voxel(b + e0))
        a *= i + s * sqi(fract(dot(-e0, p)));
    if (voxel(b - e0))
        a *= i + s * sqi(fract(dot(e0, p)));
    if (voxel(b + e1))
        a *= i + s * sqi(fract(dot(-e1, p)));
    if (voxel(b - e1))
        a *= i + s * sqi(fract(dot(e1, p)));
    if (voxel(b + e0 + e1))
        a = min(a, i + s * sqi(min(1.0, length(fract((-e0 - e1) * p)))));
    if (voxel(b + e0 - e1))
        a = min(a, i + s * sqi(min(1.0, length(fract((-e0 + e1) * p)))));
    if (voxel(b - e0 + e1))
        a = min(a, i + s * sqi(min(1.0, length(fract((e0 - e1) * p)))));
    if (voxel(b - e0 - e1))
        a = min(a, i + s * sqi(min(1.0, length(fract((e0 + e1) * p)))));
    return a;
}

vec3 ray(vec3 p, vec3 d)
{
    const vec3 grass_color = vec3(0.63, 1.0, 0.31);
    const vec3 dirt_color = vec3(0.78, 0.56, 0.4);
    const vec3 ambient_color = vec3(0.5, 0.5, 0.5);
    const vec3 sun_color = vec3(0.5, 0.5, 0.5);
    const float view_distance = 75.0;

    TraceResult r = traceVoxel(p, d, view_distance);
    TraceResult rc = traceClouds(p, d, view_distance);
    if (rc.hit && (!r.hit || rc.r > r.r))
        r = rc;
    if (r.hit)
    {
        float sun_factor = max(0.0, dot(r.n, sun_dir));
        
        float fog_factor = min(1.0, sq(length(r.p - p) / view_distance));
        vec3 fog_color = background(d);

        if (r.vp.y == cloud_height)
        {
            vec3 c = 1.9 * ambient_color + sun_factor * sun_color;
            return mix(c, fog_color, fog_factor * 0.6 + 0.4);
        }

        if (sun_factor > 0.0)
        {
        	float sd = (cloud_height - r.p.y) / sun_dir.y;
            if (traceVoxel(r.p, sun_dir, sd).hit)
                sun_factor = 0.0;
            else if (traceClouds(r.p, sun_dir, sd + 2.0).hit)
                sun_factor *= 0.3;
        }

        float ambient_factor = sample_ao(r.vp, r.p, r.n);

        float texel_noise = textureLod(iChannel0, r.p * 0.5, 0.0).r;

		float grass_mix = 0.0;
        if (!voxel(r.vp + vec3(0, 1, 0)))
        {
            if (texel_noise * 4.0 + floor(fract(r.p.y) * 16.0) > 15.0)
                grass_mix = 1.0;
            else
                grass_mix = max(0.0, r.n.y);
        }

        vec3 texel = vec3(texel_noise) * 0.3 + 0.7;
        vec3 diffuse = texel * mix(dirt_color, grass_color, grass_mix);
        vec3 c = diffuse * (ambient_factor * ambient_color + sun_factor * sun_color);

        return mix(c, fog_color, fog_factor);
    }
    return background(d);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    clouds_offset = cloud_movement * iTime;

    vec2 sxz = cos(vec2(0.0, -pi * 0.5) - iTime * sun_movement);
    sun_dir = normalize(vec3(sxz.x, 1.1, sxz.y));

    eye = eye_start + vec3(0.01) + mod(eye_movement * iTime, 640.0);
    TraceResult r = traceVoxel(vec3(eye.x, cloud_height, eye.z), vec3(0.0, -1.0, 0.0), cloud_height - eye.y);
    if (r.hit)        
    	eye.y = max(eye.y, r.p.y + 1.0);

    float ry = iMouse.x / iResolution.x * pi * 2.0 + pi * 0.85;
    float rx = -iMouse.y / iResolution.y * pi * 0.5 + pi * 0.95;

    vec4 cs = cos(vec4(ry, rx, ry - pi * 0.5, rx - pi * 0.5));
    vec3 forward = -vec3(cs.x * cs.y, cs.w, cs.z * cs.y);
	vec3 up = vec3(cs.x * cs.w, -cs.y, cs.z * cs.w);
	vec3 left = cross(up, forward);

	vec2 uv = fov * (fragCoord.xy - iResolution.xy * 0.5) / iResolution.x;
    vec3 dir = normalize(vec3(forward + uv.y * up + uv.x * left));    
    vec3 color = ray(eye, dir);
#if MULTISAMPLES > 1
    vec2 uvh = fov * vec2(0.5) / iResolution.x;
    color += ray(eye, normalize(forward + (uv.y + uvh.y) * up + (uv.x + uvh.x) * left));
#if MULTISAMPLES > 2
    color += ray(eye, normalize(forward + (uv.y + uvh.y) * up  + uv.x * left));
#if MULTISAMPLES > 3
    color += ray(eye, normalize(forward + uv.y * up + (uv.x + uvh.x) * left));
#endif
#endif
    color /= float(MULTISAMPLES);
#endif
    fragColor = vec4(color, 1.0);
}
