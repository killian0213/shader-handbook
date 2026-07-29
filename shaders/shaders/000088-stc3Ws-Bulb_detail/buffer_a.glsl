// Buffer A (buffer) — Bulb detail by loicvdb
// https://www.shadertoy.com/view/stc3Ws

ivec3 vResolution;


vec4 voxelFetch(ivec3 v)
{
    int id = 1 + (v.x + (v.y + (v.z) * vResolution.y) * vResolution.x);
    return texelFetch(iChannel0, ivec2(id % int(iResolution.x), id / int(iResolution.x)), 0);
}


vec4 voxelLinear(vec3 p)
{
    p = p * vec3(vResolution) - 0.5;
    
    ivec3 v = clamp(ivec3(p), ivec3(0), vResolution - 2);
    
    vec4 xmymzm = voxelFetch(v + ivec3(0, 0, 0));
    vec4 xpymzm = voxelFetch(v + ivec3(1, 0, 0));
    vec4 xmypzm = voxelFetch(v + ivec3(0, 1, 0));
    vec4 xpypzm = voxelFetch(v + ivec3(1, 1, 0));
    vec4 xmymzp = voxelFetch(v + ivec3(0, 0, 1));
    vec4 xpymzp = voxelFetch(v + ivec3(1, 0, 1));
    vec4 xmypzp = voxelFetch(v + ivec3(0, 1, 1));
    vec4 xpypzp = voxelFetch(v + ivec3(1, 1, 1));
    
    vec4 ymzm = mix(xmymzm, xpymzm, fract(p.x));
    vec4 ypzm = mix(xmypzm, xpypzm, fract(p.x));
    vec4 ymzp = mix(xmymzp, xpymzp, fract(p.x));
    vec4 ypzp = mix(xmypzp, xpypzp, fract(p.x));
    
    vec4 zm = mix(ymzm, ypzm, fract(p.y));
    vec4 zp = mix(ymzp, ypzp, fract(p.y));
    
    return mix(zm, zp, fract(p.z));
}


float trace(vec3 ro, vec3 rd)
{
    const float stepSize = 2.0 / density;
    float t = random() * stepSize;
    float tMax = clippingPlanes(ro, rd).y;
    float oDepth = -log(random()) / density;
    
    for (int i = 0; i < 512 && oDepth > 0.0 && t < tMax; i++)
    {
        volume v = getVolume(ro + rd * t);
        oDepth -= stepSize * v.density;
        t += max(stepSize, v.dist);
    }
    
    return mix(-1.0, t, step(oDepth, 0.0));
}


void mainImage(out vec4 o, vec2 u)
{
    seed = hash(uint(iFrame));
    
    vResolution = getVoxelResolution();
    
    vec4 prevResSamples = texelFetch(iChannel0, ivec2(0, 0), 0);
    int samples = int(prevResSamples.a);
    
    vec4 pVol = texelFetch(iChannel0, ivec2(u), 0);
    
    int id = int(u.x) + int(u.y) * int(iResolution.x) - 1;
    
    if (vResolution != ivec3(prevResSamples.xyz))
    {
        samples = 0;
    }
    
    int frameSamples = int(step(float(samples), 64.0));
    
    if (id == -1)
    {
        o = vec4(vResolution, samples + frameSamples);
        return;
    }
    
    if (id >= vResolution.x * vResolution.y * vResolution.z)
    {
        return;
    }
    
    float x = float((id) % vResolution.x);
    float y = float((id / vResolution.x) % vResolution.y);
    float z = float((id / vResolution.x / vResolution.y) % vResolution.z);
    
    vec4 nVol = vec4(0.0);
    
    for (int i = 0; i < frameSamples; i++)
    {
        const vec3 lDir = normalize(vec3(1.0, 0.4, -0.3));
        
        vec3 p = vec3(x + random(), y + random(), z + random()) / vec3(vResolution);
        vec3 li = 0.25 * step(trace(p, lDir), 0.0) * vec3(8.0);
        
        if (samples > 0)
        {
            // reusing the volumetric data for "infinite" bounce GI
            vec3 rd = randomNormal();
            float t = trace(p, rd);
            volume v = getVolume(p + t * rd);
            li += mix(background(rd), voxelLinear(p + t * rd).rgb * v.col + v.emission, step(0.0, t));
        }
        
        nVol += vec4(li, getVolume(p).density) / float(frameSamples);
    }
    
    o = mix(pVol, nVol, float(frameSamples) / float(samples + frameSamples));
    
}