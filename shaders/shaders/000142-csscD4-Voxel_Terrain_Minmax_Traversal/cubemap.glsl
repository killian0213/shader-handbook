// Cube A (cubemap) — Voxel Terrain Minmax Traversal by gelami
// https://www.shadertoy.com/view/csscD4

void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 px = 1.0 / iResolution.xy;
    
    // Doesn't do anything on my maching T_T
    #if 0
    if (iFrame > MAX_LOD)
    {
        fragColor = texture(iChannel0, rayDir);
        return;
    }
    #endif
    
    vec3 n;
    vec3 pos = cubeIntersect(rayDir, n);
    int id = cubeID(n);
    
    if (id == 0)
    {
        fragColor = vec4(0);
        
        vec2 fl = floor(fragCoord / 4.0);
        
        vec3 tex = sRGBToLinear(texture(iChannel1, uv).rgb);
        
        float h = luminance(tex);
        float ha = h;
        h = floor(h * 1024.0 * SCALE);
        
        if (hash12(fragCoord) < 0.08 * smoothstep(0.25, 0.0, ha))
        {
            fragColor.a = 1.0;
            h++;
        } else if (hash12(-fragCoord.yx) < 0.0035 * smoothstep(0.1, 0.0, ha))
        {
            fragColor.a = floor(hash12(fragCoord.yx) * 4.0) + 2.0;
            h += fragColor.a;
        }
        
        h /= (1024.0 * SCALE);
        
        fragColor.r = saturate(h);
        
    } else if (id == 1)
    {
        fragColor = vec4(0);
        
        vec4 prev = textureLod(iChannel0, cubeUVToPos(uv, 0), 1.0);
        vec2 hres = floor(iResolution.xy / 2.0);
        
        int lod = 0;
        for(; lod <= MAX_LOD; lod++)
        {
            if (fragCoord.x < float(LOD_TEX_END[lod]))
                break;
        }
        lod += 1;
        
        vec2 res = vec2(getLodSize(lod));
        float xpos = float(LOD_TEX_START[lod-1]);
        
        if (lod > MAX_LOD || fragCoord.y >= res.y)
        {
            fragColor = vec4(0);
            return;
        }

        vec2 p = (fragCoord - vec2(xpos, 0)) / iResolution.xy;
        vec2 uv = (fragCoord - vec2(xpos, 0)) / vec2(res);
        
        vec2 res2 = vec2(getLodSize(lod-1));
        vec2 px2 = 1.0 / res2;
        vec2 uv2 = ((uv * res2) + 0.5) / res2;
        
        vec4 tex00 = SampleCubemapLodNearest(iChannel0, uv2, iResolution.xy, lod-1);
        vec4 tex10 = SampleCubemapLodNearest(iChannel0, uv2 - vec2(px2.x, 0), iResolution.xy, lod-1);
        vec4 tex01 = SampleCubemapLodNearest(iChannel0, uv2 - vec2(0, px2.y), iResolution.xy, lod-1);
        vec4 tex11 = SampleCubemapLodNearest(iChannel0, uv2 - px2, iResolution.xy, lod-1);
        
        fragColor.r = max(max(tex00.x, tex10.x), max(tex01.x, tex11.x));
        
    } else
    {
        fragColor = vec4(0);
    }
}