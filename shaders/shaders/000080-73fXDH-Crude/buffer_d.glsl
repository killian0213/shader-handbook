// Buffer D (buffer) — Crude by igneus
// https://www.shadertoy.com/view/73fXDH

/*
    SEPARABLE DEFOCUS BLUR PASS 2
    -------------------------------------------------------------------------------------------------------
    
    The objective function being optimized expects the terms corresponding to each principle component to be stored
    separately during accumulation. This means packing 4x signed RGB triples into the vec4 output using 
    shared-exponent RGBE representation.
    
    Though this example only uses the first 4 singular values, in tests I was able to pack in up to 8 by reducing 
    precision to only 4 bits per floating point mantissa. This level of quantization creates severe artefacts,
    however the final accumulation in the second blur pass, plus some careful dithering renders them largely invisible.   
    
*/

void mainImage( out vec4 rgbaFrag, in vec2 xyFrag )
{ 
     //rgbaFrag.xyz = vec3(step(texelFetch(iChannel2, ivec2(xyFrag.x, iResolution.y * 0.5), 0).w, xyFrag.y / iResolution.y));
     //return;
    
    // Passthrough mode
    if(IsKeyDown(iChannel2, iRes.xy, 2))
    {
        rgbaFrag.xyz = texelFetch(iChannel0, ivec2(xyFrag), 0).xyz;
        return;
    }
    
    rgbaFrag *= 0.;
    ivec2 xy = ivec2(xyFrag);    
    //float alpha = GetBlurAlpha(xyFrag, iResolution.xy, GetTime());
    float alpha = GetBlurAlpha(xyFrag, iResolution.xy, GetTime(), iChannel2);
    float stride = kDofKernelAtrousStride * iRes.y / kReferenceResolution;
    RNGCtx rng = InitRNG(HashOf(uvec3(xyFrag.x, xyFrag.y, iFrame+1)));

    // Second pass of defocus blur
    vec3 L = kZero;

    for(int i = -kDoFKernelRadius; i <= kDoFKernelRadius; ++i)
    {
        float xi = OrderedDither(xy + ivec2(i, 0));
            
        int k = clamp(int(float(kDoFKernelSize) * (0.5 * (xi + float(i)) / float(kDoFKernelRadius) + 0.5)), 0, kDoFKernelSize);
        ivec2 uv = abs(xy + ivec2(alpha * stride * (float(i) + xi), 0));
        if(uv.x >= int(iResolution.x)) { uv.x = 2 * int(iResolution.x) - uv.x ; }
        if(uv.y >= int(iResolution.x)) { uv.y = 2 * int(iResolution.y) - uv.y; }
        vec4 t = texelFetch(iChannel1, uv, 0);

        //vec4 V = texelFetch(iChannel0, ivec2((kDoFKernelSize + k) % int(iResolution.x), (kDoFKernelSize + k) / int(iResolution.x)), 0); 
        vec4 V = texelFetch(iChannel2, ivec2(kDoFParamsX + kDoFKernelSize + k, kDoFParamsY), 0);
        for(int j = 0; j < 4; ++j)
        {                
            L += V[j] * RGBE8ToRGB(t[j]);
        }        
    }
        
    L = max(kZero, L) / float(kDoFKernelArea);
 
    rgbaFrag = vec4(L, 1);
}