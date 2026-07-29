// Buffer C (buffer) — Lens Flare Post-Processing by gelami
// https://www.shadertoy.com/view/mtVSRd


// Glare pass

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 fc = fragCoord * 2.0;
    
    if (fc.x >= iResolution.x || fc.y >= iResolution.y)
        discard;

    vec2 uv = fragCoord / iResolution.xy * 2.0;
    
    #ifdef GLARE
    
    vec2 gdir = normalize(vec2(sqrt(0.5))) / iResolution.xy;
    vec2 gdir2 = normalize(vec2(-1, 1)) / iResolution.xy;
    
    vec3 glare = vec3(0);
    float glarew = 0.0;
    
    for (int i = -GLARE_COUNT; i <= GLARE_COUNT; i++)
    {
        float d = float(i) * GLARE_STEP_SIZE;
        vec2 p = uv + gdir * d;
        vec2 p2 = uv + gdir2 * d;
        
        float k = float(i) / float(GLARE_COUNT);
        
        vec3 c = palette2(k * 3.0) * 0.8 + 0.2;
        
        const float sigma = float(GLARE_COUNT) * GLARE_STEP_SIZE * 0.45;
        float w = exp(-d*d / (2.0 * sigma*sigma));
        //glare += textureLod(iChannel0, p, 1.0).rgb;
        //glare += textureLod(iChannel0, p2, 1.0).rgb;
        
        glare += sampleBufferLod(iChannel0, p, 1.0) * w * c;
        glare += sampleBufferLod(iChannel0, p2, 1.0) * w * c;
        glarew += w;
    }
    
    vec3 col = glare / (2.0 * glarew);
    
    fragColor = vec4(col, 1);
    
    #else
    
    fragColor = vec4(0,0,0,1);
    
    #endif
}