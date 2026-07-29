// Common (common) — Bulb detail by loicvdb
// https://www.shadertoy.com/view/stc3Ws

// uncomment for high quality version (about 4x slower)
//#define HIGH_QUALITY


#ifdef HIGH_QUALITY
const float stepFactor = 0.2;
#else
const float stepFactor = 0.6;
#endif


// show voxel GI
#define GI_DEBUG_MODE 0

#define getVoxelResolution() ivec3(pow(iResolution.x * iResolution.y + 1.0, 0.333333))

const float density = 128.0;

struct volume
{
    vec3 col;
    vec3 emission;
    float density;
    float dist;
};


volume getVolume(vec3 p)
{
    const float scale = 0.8;
    
    p = p / scale + vec3(-0.65, -1.0, -0.15);
	vec3 w = p, ot = vec3(1.0);
    float dr = 1.0, r = length(w);
    
    #ifdef HIGH_QUALITY
    const int iterations = 7;
    #else
    const int iterations = 5;
    #endif
    
	for (int i = 0; i < iterations && r < 1.2; i++)
    {
		dr = dr * r*r*r*r*r*r*r * 8.0 + 1.0;
        
        float x2 = w.x * w.x;
		float y2 = w.y * w.y;
		float z2 = w.z * w.z;
        float x4 = x2 * x2;
        float z4 = z2 * z2;
        float k1 = x2 * z2;
		float k2 = x2 + z2 + 0.00001;
		float k3 = x4 + z4 + y2 * (y2 - 6.0 * k2) + 2.0 * k1;
        float k4 = k2 * k2 * k2;
		float k5 = k3 * inversesqrt(k4 * k4 * k2);
		float k6 = w.y * (k2 - y2);
		w.x = p.x + 64.0 * k6 * k5 * w.x * w.z * (x2 - z2) * (x4 - 6.0 * k1 + z4);
		w.y = p.y - 16.0 * k6 * k6 * k2 + k3 * k3;
		w.z = p.z - 8.0 * k6 * k5 * (x4 * (x4 - 28.0 * k1 + 70.0 * z4) + z4 * (z4 - 28.0 * k1));
        
        r = length(w);
		ot = min(abs(w * 1.2), ot);
	}
    
    volume v;
    v.dist = scale * 0.5 * log(r) * r / dr;
	v.col = mix(vec3(0.6, 1.0, 0.9), vec3(1.0, 0.0, 0.0), ot);
	v.emission = mix(vec3(0.4, 0.6, 0.0), vec3(0.0, 0.2, 1.0), ot.z) * step(ot.y * ot.x, 0.001);
    v.density = step(r, 1.2);
    
    return v;
}

vec2 clippingPlanes(vec3 ro, vec3 rd)
{
    vec3 cv = (0.5 - ro - sign(rd) * 0.5) / rd;
    vec3 fv = (0.5 - ro + sign(rd) * 0.5) / rd;
    
    float cp = max(max(max(cv.x, cv.y), cv.z), 0.0);
    float fp = min(min(fv.x, fv.y), fv.z);
    
    return vec2(cp, fp);
}


vec3 background(vec3 rd)
{
    return mix(vec3(1.1, 0.6, 0.6), vec3(0.2, 0.2, 0.3), rd.y * 0.5 + 0.5);
}


uint hash(uint i)
{
	i *= 0xB5297A4Du;
	i ^= i >> 8;
	i += 0x68E31DA4u;
	i ^= i << 8;
	i *= 0x1B56C4E9u;
	i ^= i >> 8;
	return i;
}


float fhash(uint i)
{
    return float(hash(i))/4294967295.;
}


uint seed;


float random()
{
    return fhash(seed++);
}


vec3 randomNormal()
{
    vec2 r = vec2(6.28318530718 * random(), acos(2.0 * random() - 1.0));
    vec2 c = cos(r), s = sin(r);
    return vec3(s.y * s.x, s.y * c.x, c.y);
}
