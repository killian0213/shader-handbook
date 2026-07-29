// Image (image) — Crude by igneus
// https://www.shadertoy.com/view/73fXDH

/*  
    Keyboard commands:
    
    Q - Show the heighfield and wetmap
    W - Preview the aperture for the lens bokeh
    E - Disable defocus blur
    R - Hide heightfield
*/

float SigmoidStep(float x, float alpha)
{
    if(alpha < 1e-15) { return step(0.5, x); }
    else
    {
        alpha = 1. / sqr(alpha);
        float limit = 1. / (1. + exp(-alpha));
        return (1. / (1. + exp(mix(-alpha, alpha, saturate(x)))) - limit) / (1. - 2.*limit);
    }
}

float Vignette(ivec2 xyFrag, float gain, float offset, float falloff)
{
    return mix(1., SigmoidStep(saturate(1. - length((vec2(xyFrag) - iResolution.xy * 0.5) / iResolution.xy) + offset), falloff), gain);
}

vec3 BlendOverlay(vec3 a, vec3 b)
{
    return mix(2. * a * b, 1. - 2.*(1. - a) * (1. - b), step(0.5, b));
}

vec3 FilmGrain(vec3 L, int type, vec2 xy, float gain, float sharpness)
{    
    #define FILM_GRAIN_UNIFORM 0
    #define FILM_GRAIN_GAUSSIAN 1
    
    float noise;
    switch(type)
    {
    case 0:
        noise = mix(SmoothNoise(xy, 0.5, HashOf(uvec2(21323487u, iFrame))), 
                    HashOfAsFloat(uvec3(xy.x, xy.y, iFrame)), sharpness);  
        break;
    case 1:
        const float sigma = .5;
        noise = mix(SmoothNoiseGaussian(xy, 0.5, sigma, HashOf(uvec2(21323487u, iFrame))), 
                    SampleGaussian(sigma, uvec4(xy.x, xy.y, iFrame, 21323487u)), sharpness);  
        break;
    }   
                   
    return max(kZero, BlendOverlay(L, vec3(mix(0.5, noise, gain))));
}

vec3 Hue(float phi)
{
    float phiColour = 6.0 * phi;
    int i = int(phiColour);
    vec3 c0 = vec3(((i + 4) / 3) & 1, ((i + 2) / 3) & 1, ((i + 0) / 3) & 1);
    vec3 c1 = vec3(((i + 5) / 3) & 1, ((i + 3) / 3) & 1, ((i + 1) / 3) & 1);             
    return mix(c0, c1, phiColour - float(i));
}


vec3 LensAberration( sampler2D sampler, in vec2 xyScreen )
{   
    #define kMaxBlurSteps 10
    #define kAberrationMagnitude 0.015
    #define kExclusionRadius 0. 
    #define kZoomFalloff 0.5
    #define kZoomScale 0.7
    
    float d = max(0., length(xyScreen - iResolution.xy * 0.5) / iResolution.x - kExclusionRadius);
    
    d = 1. - SigmoidStep(saturate(1. - d / kZoomScale + kExclusionRadius), kZoomFalloff);
    //return vec3(d);

    float magnitude = kAberrationMagnitude * d;
    
    if(OrderedDither(ivec2(xyScreen)) > magnitude / (float(kMaxBlurSteps) / iResolution.x))
    {
        vec4 texel = texelFetch(sampler, ivec2(xyScreen), 0);
        return texel.xyz / max(1., texel.w);
    }   
    
    vec2 uvScreen = vec2(1., iResolution.y/iResolution.x) * xyScreen / iResolution.xy;     
    vec2 originRelative = (uvScreen - 0.5);
    
    float sumWeights = 0.;
    vec3 sigma = vec3(0.);
    for(int idx = 0; idx < kMaxBlurSteps; ++idx)
    {
        float xi = OrderedDither(ivec2(xyScreen));
        float t = (xi + float(idx)) / float(kMaxBlurSteps);        
        vec2 uvSample = uvScreen + originRelative * magnitude * -pow(t, 2.);
        float weight = 1.;// - t;
        vec4 texel = texture(sampler, uvSample / vec2(1., iResolution.y/iResolution.x), 0.);
        vec3 spectrum = mix(kOne, 2. * Hue(float(idx) / float(kMaxBlurSteps)), d);
        sigma += spectrum * (texel.xyz / max(1., texel.w)) * weight;
        sumWeights += weight;
    }
    
    return sigma / float(sumWeights);
}

int Interfere(inout vec2 xy, int iFrame, vec2 iRes)
{
    #define kStatic true
    #define kStaticFrequency 0.05
    #define kStaticLowMagnitude 0.0
    #define kStaticHighMagnitude 0.05
    
    #define kVDisplace true
    #define kVDisplaceFrequency 0.05
    
    #define kHDisplace true
    #define kHDisplaceFrequency 0.1
    #define kHDisplaceVMagnitude 0.1
    #define kHDisplaceHMagnitude 0.5
    
    float frameHash = HashOfAsFloat(uint(iFrame / 10));
    int dispCode = 0;
        
    if(kStatic)
    {
        // Every now and then, add a ton of static
        float interP = 0.0, displacement = iRes.x * kStaticLowMagnitude;
        if(frameHash < kStaticFrequency)
        {
            interP = 0.5;
            displacement = kStaticHighMagnitude * iRes.x;
            dispCode |= 1;
        }

        // CRT interference at PAL refresh rate
        vec4 xi = HashOfAsVec4(uvec2(xy.y / 2., iFrame / int(60.0 / 24.0 )));
        if(xi.x < interP) 
        {  
            float mag = mix(-1.0, 1.0, xi.y);        
            xy.x -= displacement * sign(mag) * sqr(abs(mag)); 
            dispCode |= 2;
        }
    }
    
    // Vertical displacment
    if(kVDisplace && frameHash > 1.0 - kVDisplaceFrequency)
    {
        float dispX = HashOfAsFloat(uvec2(8783u, iFrame / 10));
        float dispY = HashOfAsFloat(uvec2(364719u, iFrame / 12));
        
        if(xy.y < dispX * iRes.y) 
        { 
            xy.y -= mix(-1.0, 1.0, dispY) * iRes.y * 0.2; 
            dispCode |= 4;
        }
    }
    // Horizontal displacment
    else if(kHDisplace && frameHash > 1.0 - kHDisplaceFrequency - kVDisplaceFrequency)
    {
        float dispX = HashOfAsFloat(uvec2(147251u, iFrame / 9));
        float dispY = HashOfAsFloat(uvec2(287512u, iFrame / 11));
        float dispZ = HashOfAsFloat(uvec2(8756123u, iFrame / 7));
        
        if(xy.y > dispX * iRes.y && xy.y < (dispX + mix(0.0, kHDisplaceVMagnitude, dispZ)) * iRes.y) 
        { 
            xy.x -= mix(-1.0, 1.0, dispY) * iRes.x * kHDisplaceHMagnitude; 
            dispCode |= 8;
        }
    }
    
    return dispCode;
}

vec4 UnsharpMask(vec2 xyFrag, float highPassGain, float lowPassGain, float threshold, float radius, int stride, sampler2D sampler)
{
    //if(highPassGain <= 0.) { return texelFetch(sampler, ivec2(xyFrag), 0); }
    
    vec4 lowPass = vec4(0.);
    float sumW = 0.;
    int kUnsharpRadius = int(ceil(radius));
    for(int v = -kUnsharpRadius; v <= kUnsharpRadius; ++v)
    {
        for(int u = -kUnsharpRadius; u <= kUnsharpRadius; ++u)
        {
            //float w = 1.; 
            float w =  1.0 - max(0., float(u*u + v*v) - 0.5) / float(radius*radius + 0.25);
            if(w > 0.)
            {
                //ivec2 xy = clamp(ivec2(xyFrag) + ivec2(u, v) * stride, ivec2(0), textureSize(sampler, 0) - 1);
                vec2 xy = clamp(vec2(xyFrag) + vec2(u, v) * float(stride), vec2(0), vec2(textureSize(sampler, 0) - 1));
                //if(xy.x >= 0 && xy.x < textureSize(sampler, 0).x && xy.y >= 0 && xy.y <= textureSize(sampler, 0).y)
                {
                    vec4 texel = (texelFetch(sampler, ivec2(xy), 0));
                    lowPass += w * max(vec4(0), texel - threshold) * (1. - threshold);
                    sumW += w;
                }
            }
        }
    }

    vec4 thisPixel = texelFetch(sampler, ivec2(xyFrag), 0);
    vec4 highPass = max(vec4(0), (thisPixel) - threshold) * (1. - threshold) - (lowPass / sumW);

    return max(vec4(0.), lowPassGain * thisPixel + highPassGain * highPass);
}

void mainImage( out vec4 rgbaFrag, in vec2 xyFrag )
{         
    // Show the heighfield data 
    if(IsKeyDown(iChannel1, iRes.xy, 0))
    {
        rgbaFrag = texelFetch(iChannel1, ivec2(xyFrag), 0); 
        rgbaFrag.xyz = rgbaFrag.xyz * 0.5 + 0.5;
        if(xyFrag.x > iRes.y) { rgbaFrag.xyz = mix(rgbaFrag.xyz, 1. - rgbaFrag.xyz, saturate(rgbaFrag.w)); }
        return;
    }
    // Show the iris 
    float previewSize = iResolution.y * 0.3;
    if(xyFrag.x < previewSize && xyFrag.y < previewSize && IsKeyDown(iChannel1, iRes.xy, 1))
    {
        rgbaFrag.xyz = vec3(EvaluateAperture(xyFrag, previewSize * 0.5) / kApertureGain);
        return;
    }
    
    int interCode = 0;
    if(kApplyInterferenceDamage)
    {
        interCode = Interfere(xyFrag, iFrame, iRes.xy);
    }

    vec3 L = (kSharpening > 0.) ? UnsharpMask(xyFrag, (interCode <= 1) ? kSharpening : 50., 1., 0., 2.0, 1, iChannel0).xyz :
                                  texelFetch(iChannel0, ivec2(xyFrag), 0).xyz;
    //vec3 L = LensAberration(iChannel0, xyFrag);
  
    // Gamma and saturation
    L = pow(L * 1.1, vec3(1. / 1.5));
    L = mix(vec3(luminance(L)), L, 2.);
    ivec2 xy = ivec2(xyFrag);

    if(kApplyVignette)
    {
        L *= Vignette(xy, 1., 0.2, 1.);
    }
    
    if(kApplyFilmGrain)
    {
        L = FilmGrain(L, FILM_GRAIN_GAUSSIAN, xyFrag, 0.1, .6);
    }

    if(kApplyColourGrade)
    {        
        #if kColourfulMode == 0
            const float level = 0.15;
        #else
            const float level = 0.4;
        #endif
        
        L = mix(L, ApplyRedGrade(L), level);
    }
 
    rgbaFrag = vec4(L, 1);
}