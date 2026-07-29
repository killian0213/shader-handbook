// Buffer B (buffer) — Lens Flare Post-Processing by gelami
// https://www.shadertoy.com/view/mtVSRd


// Bloom pass based from:
// 2-Pass Buffer Bloom - gelami
// https://www.shadertoy.com/view/cty3R3

const int rad = 5;
const float sigma = float(rad) * 0.4;

#if 1
vec4 prefilter(vec4 col)
{
    const float threshold = BLOOM_THRESHOLD;
    float brightness = max(max(col.r, col.g), col.b);
    float contrib = max(brightness - threshold, 0.0) / max(brightness, 1e-5);
    return col * contrib;
}
#else
vec4 prefilter(vec4 col)
{
    return col;
}
#endif

float gaussian(vec2 i, float sigma) {
    return exp(-(dot(i,i) / (2.0 * sigma*sigma)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 hres = floor(iResolution.xy / 2.0);
        
    vec2 res = hres;
    float xpos = 0.0;
    int lod = 0;
    for (; lod < BLOOM_MAX_LOD; lod++)
    {
        xpos += res.x;
        
        if (xpos > fragCoord.x || res.x <= 1.0)
            break;
        res = floor(res / 2.0);
    }
    
    if (fragCoord.y >= res.y)
    {
        fragColor = vec4(0);
        return;
    }
    
    fragColor = vec4(0);
    
    vec2 px = 1.0 / iResolution.xy;
    vec2 p = (fragCoord - vec2(xpos - res.x, 0)) / iResolution.xy;
    vec2 uv = (fragCoord - vec2(xpos - res.x, 0)) / vec2(res);
    
    // Skip blurring LOD 0 for performance
    #if 1
    if (lod == 0)
    {
        fragColor = prefilter(textureLod(iChannel0, uv, 1.0));
        return;
    }
    #endif
    
    float sc = exp2(float(lod));
    float w = 0.0;
    for (int x = -rad; x <= rad; x++)
    {
        for (int y = -rad; y <= rad; y++)
        {
            vec2 o = vec2(x, y);
            float wg = gaussian(o, sigma);
            vec2 p = uv + o / vec2(res);
            
            //p = clamp(p, 0.5 / res, (res - 0.5) / res);
            
            if (p == clamp(p, vec2(0.5) / res, (res - 0.5) / res))
                fragColor += wg * prefilter(textureLod(iChannel0, p, float(lod)));
            w += wg;
        }
    }
    fragColor /= w;
}
