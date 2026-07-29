// Buffer B (buffer) — Bulb detail by loicvdb
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


vec4 voxelClosest(vec3 p)
{
    return voxelFetch(clamp(ivec3(p * vec3(vResolution)), ivec3(0), vResolution - 1));
}


vec4 colDepth(vec3 ro, vec3 rd)
{
    rd += (1.0 - abs(sign(rd))) * 0.00001;   // avoids div/0 for clipping planes & voxel marching
    
    vec2 cp = clippingPlanes(ro, rd);
    
    float depth = 3.0;
    
    if (cp.y <= cp.x)
    {
        return vec4(background(rd), depth);
    }
    
    vec3 cubeSize = 1.0 / vec3(vResolution);
    vec3 col = vec3(0.0);
    float att = 1.0;
    float t = cp.x;
    
    #if GI_DEBUG_MODE
    
    // voxel marching w/ analytical volume integration
    
    int maxSteps = vResolution.x + vResolution.y + vResolution.z;
    
    for (int i = 0; i < maxSteps && att > .03 && t < cp.y; i++)
    {
        vec3 p = ro + t * rd;
        vec3 l = (cubeSize * floor(p / cubeSize + sign(rd) * 0.50001 + 0.5) - p) / rd;
        float stepSize = min(min(l.x, l.y), l.z) + 0.00001;
        
        vec4 v = voxelClosest(p);
        
        if(v.a > 0.0)
        {
            depth = min(depth, t);
            float a = exp(-stepSize * v.a * density);
            col += att * (1.0 - a) * v.rgb;
            att *= a;
        }
        
        t += stepSize;
    }
    
    #else
    
    // volume raymarching + SDF raymarching
    float phase = random();
    
    for (int i = 0; i < 1024 && att > .03 && t < cp.y; i++)
    {
        const float stepSize = stepFactor / density;
    
        vec3 p = ro + rd * t;
        
        volume v = getVolume(p);
        
        if (v.density > 0.0)
        {
            float a = exp(-stepSize * v.density * density);
            col += att * (1.0 - a) * (v.col * voxelLinear(p).rgb + v.emission);
            att *= a;
        }
        
        if(v.dist < 0.0 && t < depth)
        {
            depth = t;
        }
        
        // SDF raymarching
        t += max(v.dist, 0.0);
        
        // rounding t to the next point
        t += (1.0 - fract(t / stepSize + phase) - 0.000001) * stepSize;
    }
    
    #endif
    
    return vec4(att * background(rd) + col, depth);
}


void mainImage(out vec4 o, vec2 u)
{
    float samples = texelFetch(iChannel0, ivec2(0, 0), 0).a;
    
    if (samples < 16.0)
    {
        // not enough samples, don't render to sample faster
        o = vec4(0);
        return;
    }
    
    seed = hash(uint(floor(u.x) + floor(u.y) * 12345.0)) ^ hash(uint(iFrame));
    
    vResolution = getVoxelResolution();
    
    vec2 rot = vec2(0.3, 0.7);
    if(iMouse != vec4(0.0))
    {
        rot += (iMouse.xy - iResolution.xy * 0.5) / iResolution.y * 3.0;
    }
    
    vec2 c = cos(rot);
    vec2 s = sin(rot);
    
    mat3 rx = mat3(1, 0, 0, 0, c.y, s.y, 0, -s.y, c.y);
    mat3 ry = mat3(c.x, 0, s.x, 0, 1, 0, -s.x, 0, c.x);
    mat3 cam = ry * rx;
    
    vec3 rd = cam * normalize(vec3((u - iResolution.xy * 0.5) / iResolution.y, -3.5));
    vec3 ro = cam * vec3(0.0, 0.0, 1.5);
    
    ro += vec3(0.5, 0.3, 0.77);
    
    o = colDepth(ro, rd);
    
    // fading animation
    o.rgb *= smoothstep(16.0, 64.0, samples);
    
    
    #if !GI_DEBUG_MODE
    
    // quick accumulation to remove a little bit of noise
    
    #ifdef HIGH_QUALITY
    const float saticAcc = 0.9;
    const float dynamicAcc = 0.2;
    #else
    const float saticAcc = 0.9;
    const float dynamicAcc = 0.6;
    #endif
    
    vec4 prev = texelFetch(iChannel1, ivec2(u), 0);
    if (iMouse.z <= 0.0 && samples > 16.0)
    {
        o.rgb = mix(o.rgb, prev.rgb, saticAcc);
        o.a = min(o.a, prev.a);
    }
    else
    {
        o.rgb = mix(o.rgb, prev.rgb, dynamicAcc);
    }
    
    #endif
}