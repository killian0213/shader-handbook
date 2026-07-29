// Buffer B (buffer) — Alpine Flyby 2.0 by loicvdb
// https://www.shadertoy.com/view/4c3GD4

// taa

void mainImage(out vec4 o, vec2 u)
{
    vec4 a = texelFetch(iChannel0, ivec2(u), 0);
    
    float t = a.a;
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            t = min(t, texelFetch(iChannel0, ivec2(u) + ivec2(i, j), 0).a);
        }
    }
    
    vec3 mi = +vec3(1000.0);
    vec3 ma = -vec3(1000.0);
    
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            vec4 tex = texelFetch(iChannel0, ivec2(u) + ivec2(i, j), 0);
            
            mi = min(mi, tex.rgb);
            ma = max(ma, tex.rgb);
        }
    }
    
    mat3 r = rotation(iTime);
    vec3 ro = r * CAM_POS;
    vec3 rd = r * normalize(vec3((u - iResolution.xy * 0.5) / iResolution.y, -CAM_FLENGTH));
    
    vec3 p = ro + t * rd;
    
    mat3 pr = rotation(iTime - iTimeDelta);
    vec3 prd = transpose(pr) * normalize(pr * CAM_POS - p);
    vec2 puv = 0.5 - CAM_FLENGTH * prd.xy / prd.z * vec2(iResolution.y / iResolution.x, 1.0);
    
    vec2 f = fract(puv * iResolution.xy + 0.5); 
    float blurring = abs(f.x - 0.5) + abs(f.x - 0.5);
    float blendFactor = mix(0.8, 0.9, blurring);
    
    vec3 b = clamp(texture(iChannel1, puv, 0.0).rgb, mi, ma);
    o = vec4(mix(a.rgb, b, blendFactor), a.a);
}