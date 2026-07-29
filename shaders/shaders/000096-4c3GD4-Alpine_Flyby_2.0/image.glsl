// Image (image) — Alpine Flyby 2.0 by loicvdb
// https://www.shadertoy.com/view/4c3GD4

vec3 tonemap(vec3 c)
{
    return (c * (2.51 * c + 0.03)) / (c * (2.43 * c + 0.59) + 0.14);
}

vec4 heightmap(vec2 uv)
{
    return texture(iChannel1, vec3(uv, 1.0), 0.0);
}

vec2 cloudVolume(vec3 p)
{
    // 3D textures (slow)
    //p += 0.01 * (texture(iChannel2, p * vec3(6.0), 0.0).xyz - 0.5);
    //p += 0.03 * (texture(iChannel2, p * vec3(2.0), 0.0).xyz - 0.5);
    //p += 0.05 * (texture(iChannel2, p * vec3(0.5), 0.0).xyz - 0.5);
    
    // 2D textures (ugly)
    //p += 0.01 * (texture(iChannel3, p.xy * vec2(3.00), 0.0).xyz - 0.5);
    //p += 0.03 * (texture(iChannel3, p.xy * vec2(1.00), 0.0).xyz - 0.5);
    //p += 0.05 * (texture(iChannel3, p.xy * vec2(0.25), 0.0).xyz - 0.5);
    
    // both 2D and 3D
    p += 0.01 * (texture(iChannel3, p.xy * vec2(3.00), 0.0).xyz - 0.5);
    p += 0.03 * (texture(iChannel2, p    * vec3(2.00), 0.0).xyz - 0.5);
    p += 0.05 * (texture(iChannel3, p.xy * vec2(0.25), 0.0).xyz - 0.5);
    
    vec4 h = heightmap(clamp(p.xy, vec2(-1023.0 / 1024.0), vec2(1023.0 / 1024.0)));
    float d = cloudSdf(h, p);
    return vec2(smoothstep(-0.008, 0.008, -d) * CLOUD_DENSITY, d);
}

void mainImage(out vec4 o, vec2 u)
{
    vec4 tex = texelFetch(iChannel0, ivec2(u), 0);
    
    mat3 r = rotation(iTime);
    vec3 ro = r * CAM_POS;
    vec3 rd = r * normalize(vec3((u - iResolution.xy * 0.5) / iResolution.y, -CAM_FLENGTH));
    
    vec3 cv = -(ro + sign(rd) * 1023.0 / 1024.0) / rd;
    vec3 fv = -(ro - sign(rd) * 1023.0 / 1024.0) / rd;
    
    float cp = max(max(max(cv.x, cv.y), cv.z), 0.0);
    float fp = min(min(min(fv.x, fv.y), fv.z), tex.a);
    
    float t = cp;
    float extinction = 1.0;
    vec3 cloudColor = vec3(0.0);
    for (int i = 0; i < 96 && t < fp; i++)
    {
        vec3 p = ro + t * rd;
        
        vec2 d = cloudVolume(p);
        
        float s = max(0.005 / extinction, d.y * 0.9 - 0.05);
        float a = exp(-s * d.x);
        
        if (d.x > 0.0)
        {
            vec3 direct = 0.5 * LIGHT_COL * exp((cloudVolume(p + LIGHT_DIR / CLOUD_DENSITY).y - d.y) * CLOUD_DENSITY);
            vec3 ambient = AMBIENT_COL * exp(d.y * CLOUD_DENSITY);
            cloudColor += extinction * (1.0 - a) * (ambient + direct);
        }
        
        extinction *= a;
        t += s;
    }
    
    vec3 col = tex.rgb;
    
    
    o = vec4(tonemap(col * extinction + cloudColor), 1.0);
}