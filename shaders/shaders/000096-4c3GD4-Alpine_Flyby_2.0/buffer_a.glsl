// Buffer A (buffer) — Alpine Flyby 2.0 by loicvdb
// https://www.shadertoy.com/view/4c3GD4

// render

uint mangle(uint a, uint b)
{
    return a * 0xB5297A4Du + b * 0x1B56C4E9u;
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
    return float(hash(i)) / float(~0u);
}

vec4 heightmap(vec2 uv)
{
    return texture(iChannel0, vec3(uv, 1.0), 0.0);
}

float treeDensity(vec4 h)
{
    return clamp(h.z * h.z * h.z * (h.w - 0.0002) * 30.0, 0.0, 1.0);
}

float cloudVolume(vec4 h, vec3 p)
{
    float d = cloudSdf(h, p);
    return smoothstep(-0.01, 0.01, -d) * CLOUD_DENSITY;
}

float stepSize(float d)
{
    return 0.7 * max(d - TREE_HEIGHT, 0.0) + TREE_STEP_SIZE;
}

vec2 treeVolume(vec4 h, vec3 p)
{
    if (p.z - h.w > TREE_HEIGHT)
    {
        return vec2(0.0);
    }
    
    vec2 gp = p.xy / TREE_HEIGHT * 5.0;
    
    float d = 1000.0;
    float c = 0.0;
    
    for(int j = 0; j <= 1; j++)
    {
        for(int i = 0; i <= 1; i++)
        {
            ivec2 cell = ivec2(floor(gp)) + ivec2(i, j);
            float ha = fhash(mangle(uint(cell.x), uint(cell.y)));
            
            vec2 cuv = gp - vec2(cell) - 0.5 + fract(ha * vec2(16.231546, 7.11654));
            vec3 blob = vec3(cuv, (p.z - h.w) / (TREE_HEIGHT * (0.5 + 0.5 * fract(ha * 9.1564))) - 0.5);
            
            float dist2 = dot(blob, blob);
            if (ha < treeDensity(h) && dist2 < d)
            {
                d = dist2;
                c = fract(ha * 29.1564);
            }
        }
    }

    return vec2(step(d, 0.25) * TREE_VOLUME_DENSITY, c);
}

float shadow(vec3 ro)
{
    float optic = 0.0;
    float soft = 1.0;
    
    float t = 0.0;
    
    for (int i = 0; i < 48; i++)
    {
        vec3 p = ro + t * LIGHT_DIR;
        vec4 tex = heightmap(clamp(p.xy, vec2(-1023.0 / 1024.0), vec2(1023.0 / 1024.0)));
        
        float d = p.z - tex.a;
        
        float s = stepSize(d);
        
        optic += treeVolume(tex, p).x * s;
        optic += cloudVolume(tex, p) * s;
        
        soft = clamp(3.0 * d / t, 0.0, soft);
        
        t += s;
    }
    
    return exp(-optic) * soft * soft;
}

void mainImage(out vec4 o, vec2 u)
{
    uint seed = mangle(mangle(uint(u.x), uint(u.y)), uint(iFrame));
    
    vec2 jitter = vec2(fhash(uint(iFrame)), fhash(uint(iFrame) + 10u)) - 0.5;
    
    mat3 r = rotation(iTime);
    
    vec3 ro = r * CAM_POS;
    vec3 rd = r * normalize(vec3((u + jitter - iResolution.xy * 0.5) / iResolution.y, -CAM_FLENGTH));
    
    vec3 cv = -(ro + sign(rd) * 1023.0 / 1024.0) / rd;
    vec3 fv = -(ro - sign(rd) * 1023.0 / 1024.0) / rd;
    
    float cp = max(max(max(cv.x, cv.y), cv.z), 0.0);
    float fp = min(min(fv.x, fv.y), fv.z);
    
    float t = ro.z + cp * rd.z < heightmap(ro.xy + cp * rd.xy).w ? fp : cp;
    
    float optic = fhash(seed + 2u);
    
    float d = ro.z + t * rd.z - heightmap(ro.xy + t * rd.xy).w;
    
    t += fhash(seed + 3u) * stepSize(d);
    
    for (int i = 0; i < 128 && t < fp && optic > 0.0 && d > TREE_HEIGHT * 0.1; i++)
    {
        vec3 p = ro + t * rd;
        vec4 tex = heightmap(p.xy);
        
        d = p.z - tex.a;
        
        float s = stepSize(d);
        optic -= treeVolume(tex, p).x * s;
        t += s;
    }
    
    vec3 col = vec3(0.0);
    
    float f = 0.65 + 0.5 * rd.z;
    
    if (t < fp)
    {
        vec3 p = ro + t * rd;
        
        vec4 h = heightmap(p.xy);
        
        p.z = max(p.z, h.w + TREE_HEIGHT * 0.1);
        
        float cloudAo = 0.6 + 0.4 * smoothstep(-0.18, -0.05, -p.z);
        float treeAo = exp(0.15 * TREE_VOLUME_DENSITY * (p.z - (h.w + TREE_HEIGHT)) * treeDensity(h));
        
        vec3 ambient = AMBIENT_COL * cloudAo * treeAo;
        vec3 direct = LIGHT_COL * shadow(p + rd * fhash(seed + 4u) * TREE_STEP_SIZE);
        
        if (optic < 0.0)
        {
            col = (direct + ambient) * mix(vec3(0.25, 0.25, 0.10), vec3(0.35, 0.45, 0.15), treeVolume(h, p).y);
        }
        else
        {
            vec3 albedo = mix(vec3(0.80, 0.70, 0.40), vec3(0.25, 0.30, 0.10), smoothstep(0.0, 0.005, p.z));
        
            col += albedo * direct * max(dot(h.rgb, LIGHT_DIR), 0.0);
            col += albedo * ambient;
            col *= exp(-vec3(700.0, 600.0, 500.0) * max(0.0, t + ro.z / rd.z));
            col = mix(col, AMBIENT_COL, step(0.0, t + ro.z / rd.z) * f);
        }
    }
    else
    {
        col = mix(col + step(0.0, rd.z) * AMBIENT_COL, AMBIENT_COL, f);
        t = 100.0;
    }
    
    o = vec4(col, t);
}