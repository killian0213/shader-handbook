// Buffer C (buffer) — Crude by igneus
// https://www.shadertoy.com/view/73fXDH

/*
    SEPARABLE DEFOCUS BLUR PASS 1
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
    ivec2 xy = ivec2(xyFrag);

    // Passthrough
    if(IsKeyDown(iChannel3, iRes.xy, 2))    
    {
        rgbaFrag.xyz = texelFetch(iChannel1, xy, 0).xyz;
        return;
    }
    
    RNGCtx rng = InitRNG(HashOf(uvec3(xyFrag.x, xyFrag.y, iFrame)));
    
    float stride = kDofKernelAtrousStride * iRes.y / kReferenceResolution;
    //float alpha = GetBlurAlpha(xyFrag, iResolution.xy, GetTime());
    float alpha = GetBlurAlpha(xyFrag, iResolution.xy, GetTime(), iChannel3);
    vec3[4] sum = vec3[4](kZero, kZero, kZero, kZero);    
    for(int j = -kDoFKernelRadius; j <= kDoFKernelRadius && j <= kDoFKernelRadius; ++j)
    {
        float xi = OrderedDither(xy + ivec2(0, j));
        vec2 uv = vec2(xy) + vec2(0, alpha * stride * (float(j) + xi));
        
        // Mirror coordinates to reduce boundary artefacts from very large kernels
        uv = abs(uv / iResolution.xy);
        if(uv.x >= 1.) { uv.x = 2. - uv.x; }
        if(uv.y >= 1.) { uv.y = 2. - uv.y; }
        vec4 texel = texture(iChannel1, uv, 0.);
        vec3 L = texel.xyz / texel.w;
            
        int k = clamp(int(float(kDoFKernelSize) * (0.5 + 0.5 * (float(j) + xi) / float(kDoFKernelRadius))), 0, kDoFKernelSize);
        //vec4 U = texelFetch(iChannel0, ivec2(k % int(iResolution.x), k / int(iResolution.x)), 0);
        vec4 U = texelFetch(iChannel3, ivec2(kDoFParamsX + k, kDoFParamsY), 0);
        for(int i = 0; i < 4; ++i)
        {
            sum[i] += U[i] * L;          
        }                       
    }
    
    // Pack the 4 intermediate values into 32-bit RGBE
    rgbaFrag = vec4(RGBToRGBE8(sum[0]), RGBToRGBE8(sum[1]), RGBToRGBE8(sum[2]), RGBToRGBE8(sum[3]));   
}