// Buffer D (buffer) — Fully ray traced water by michael0884
// https://www.shadertoy.com/view/w3sXzs

float Density(vec3 p)
{
    return trilinear(ch0, p).z;
}

float TraceDensity(vec3 ro, vec3 rd)
{
    float dens = 0.0;
    float td = 0.0;
    for(int i = 0; i < 100; i++)
    {
        vec3 p = ro + rd * td;
        if(any(lessThan(p, vec3(1.0))) || any(greaterThan(p, size3d - 1.0))) return dens;
        float d = Density(p);
        dens += d * 2.0;
        td += 2.0;
    }
    return dens;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    InitGrid(iResolution.xy);
    fragCoord = floor(fragCoord);
    vec3 pos = dim3from2(fragCoord);
    
    //Compute volume shadows
    float shadow_d = 0.0;//TraceDensity(pos+light_dir*1.0, light_dir);
    fragColor = vec4(0.0);
    fragColor.z = shadow_d;
    
    vec3 pos4x = pos * float(BLOCK_SIZE);
    
    //Compute surface mask
    if(any(greaterThanEqual(pos4x, size3d))) 
    {
        return;
    }
    
    uvec2 hasSurface = uvec2(0, 0);
    loop(i, BLOCK_SIZE) loop(j, BLOCK_SIZE) loop(k, BLOCK_SIZE)
    {
        vec3 p = pos4x + vec3(i, j, k);
        uint surface = 0u;
        loop(ii, 2) loop(jj, 2) loop(kk, 2)
        {
            vec3 pp = p + vec3(ii, jj, kk);
            float density = LOAD3D(ch0, pp).z;
            surface |= (density >= IsoValue) ? 2u : 1u;
        }
        uint id = uint((i * BLOCK_SIZE + j) * BLOCK_SIZE + k);
        uint id0 = id / 32u;
        uint id1 = id - id0 * 32u;
        if(surface == 3u) { // Has both higher and lower than iso value, so it's a surface
           if(id0 == 0u) hasSurface.x |= 1u << id1;
           if(id0 == 1u) hasSurface.y |= 1u << id1;
        }
    }

    fragColor.xy = uintBitsToFloat(hasSurface);
}