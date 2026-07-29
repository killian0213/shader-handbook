// Image (image) — Phoenix Ascending by igneus
// https://www.shadertoy.com/view/WclSWl

// *******************************************************************************************************
//    Composite pass
// *******************************************************************************************************

vec3 Vignette(in vec3 rgb, in vec2 xyFrag)
{
    #define kVignetteStrength         1.             // The strength of the vignette effect
    #define kVignetteScale            0.6            // The scale of the vignette effect
    #define kVignetteExponent         2.5            // The rate of attenuation of the vignette effect
    
    vec2 uv = xyFrag / iResolution.xy;
    uv.x = (uv.x - 0.5) * (iResolution.x / iResolution.y) + 0.5;     
    
    float x = 2.0 * (uv.x - 0.5);
    float y = 2.0 * (uv.y - 0.5);
    
    float dist = sqrt(x*x + y*y) / kRoot2;
    
    float v = mix(1.0, max(0.0, 1.0 - pow(dist * kVignetteScale, kVignetteExponent)), kVignetteStrength);
    return rgb * v;
    //return pow(rgb, vec3(1. + (1. - v)));
}

float Stipple(vec2 uvView, float scale, float radius, float dPdXY)
{
    vec3 bary;
    ivec2 ij;
    uvView = Cartesian2DToHexagonalTiling(uvView * scale, bary, ij);
    
    return SDFCircle(uvView, vec2(0.), radius, 2. * dPdXY * scale);
}

vec3 EvaluateBackground(vec2 uvView)
{
    uvView = uvView * RotMat2(kTime * 0.02) * 0.25;
    
    if(!InverseSternograph(uvView, 1.2)) { return kZero; }

    #define kCellScale 5.
    uvView *= kCellScale;
    
    float dPdXY = kCellScale / iResolution.y;    
    vec3 bary;
    ivec2 ij;
    vec2 uvCell = Cartesian2DToHexagonalTiling(uvView, bary, ij);
    
    
    float time = kTime * 0.1;
    int tInterval = int(time);
    float tPhase = fract(time);    
    float t0 = HaltonBase2(HashOf(uint(tInterval)));
    float t1 = HaltonBase2(HashOf(uint(tInterval+1)));
    float delta = Sigmoid(mix(-1., 1., tPhase) * 20.);
    float r =  mix(mix(0.5, 1.5, t0), mix(0.5, 1.5, t1), delta);
    uvCell *= RotMat2(kPi * mix(round(t0 * 6.) / 6., round(t1 * 6.) / 6., delta));
    
    // Evaluate circles at multiples of 60 degree angles to the origin of the cell
    int fill = 0;
    float line = 0.;
    for(int j = -1; j <= 1; ++j)
    {
        for(int i = -1; i <= 1 - abs(j); ++i)
        {
            vec2 ij = vec2((float(i) + 0.5 * float(abs(j) % 2 == 1)) / 1., 0.8660254037844387 * float(j) / 1.);
            vec2 p = uvCell - vec2(ij);           
            if(length(uvCell - ij) < r)
            {
                fill = ~fill;
            }
            
            float n = clamp(sin(atan(float(j), float(i)) + kTime + 5. * atan(p.y, p.x)) - 0.5, -1., 1.);
            float thickness = 0.015 * mix(1., 3., Sigmoid(n * 5.));
            line = max(line, SDFTorus(p, vec2(0.), r, thickness, 2. * dPdXY));
        }
    }
    
    vec3 L = kZero;
    L = kOne * 0.2 * float(fill & 1) * Stipple(uvView, 30., 0.6, dPdXY);
    L = mix(L, kOne * .25, line);
    
    return L;
}

vec3 ZoomBlur( in vec2 xyFrag, vec2 blurCentroid, float blurMagnitude, float spectralMag, sampler2D sampler )
{
    #define kMaxBlurSteps 20
    
    float d = length(xyFrag - iResolution.xy * blurCentroid) / iResolution.x;
    d = 1. - exp(-sqr(d * 3.));
    float gain = 1.;
    int kBlurSteps = int(float(kMaxBlurSteps) * d);
    float kBlurMag = blurMagnitude * d;
    
    if(kBlurSteps <= 1)
    {
        vec4 texel = texelFetch(sampler, ivec2(xyFrag), 0);
        return gain * texel.xyz / max(1., texel.w);
    }    
    
    vec2 uvScreen = xyFrag / iResolution.xy;
    
    vec3 sumWeights = kZero;
    vec3 sigma = vec3(0.);
    for(int idx = 0; idx < kBlurSteps; ++idx)
    {
        float xi = OrderedDither(ivec2(xyFrag));
        float t = (xi + float(idx)) / float(kBlurSteps);        
        vec2 uvSample = blurCentroid + (uvScreen - blurCentroid) * (1. + kBlurMag * mix(-0.5, 0.5, pow(t, 2.)));        
      
        vec3 spectrum = (spectralMag <= 0.) ? kOne : mix(kOne, 2. * Hue(1. - float(idx) / float(kBlurSteps - 1)), d * spectralMag);
        vec4 texel = texture(sampler, uvSample, 0.);
        sigma += spectrum * gain * (texel.xyz / max(1., texel.w));
        sumWeights += spectrum;
    }
    
    return sigma / sumWeights;
}


vec3 EvaluateBloom(vec2 uv, float radius)
{   
    vec3 bloom;
    bloom = SeparableBlurUp(uv, ivec2(iResolution), vec2(0.2), vec3(1.5, 1.8, 2.4), 0, iChannel3); 
    bloom += SeparableBlurUp(uv, ivec2(iResolution), vec2(radius), vec3(2.0, 2.8, 2.4), 1, iChannel3);
    
    return pow(bloom * 0.3, vec3(0.49, 0.54, 0.588)) * 2.15766927997459;
}

void mainImage( out vec4 rgbaFrag, in vec2 xyFrag )
{    
    rgbaFrag = vec4(0.);    
    vec2 xyView = ScreenToNormalisedScreen(xyFrag, iResolution.xy);
    //vec4 hawkTex = SampleHawkUnsharpMask(xyView, iResolution.xy, 2. / iResolution.y, 3., iChannel1);
    vec4 hawkTex = SampleHawk(xyView, iResolution.xy, kTime, iChannel1);

    
    vec3 L = kZero;
    
    // Retrieve the particle field with a small amount of zoom blur
    L += ZoomBlur(xyFrag, vec2(0.5, 0.7), 0.01, 0., iChannel2);
    
    // Evaluate the second bloom pass with adjustments based on the hawk's body
    float radius = mix(0.02, 0.3, hawkTex.w);
    vec3 bloom = EvaluateBloom(xyFrag + hawkTex.xy * 20., radius);
        
    // Displace the background based on the intensity of the bloom to create heat shimmer
    float lumBloom = max(0., cwiseMax(bloom) - 0.1);
    float shimmerTheta = 10. * kTwoPi * lumBloom + Noise(xyView * 2. + kTime);
    vec2 shimmerDisplace = lumBloom * 0.05 * vec2(cos(shimmerTheta), sin(shimmerTheta));
    L = max(L, Vignette(EvaluateBackground(xyView + shimmerDisplace), xyFrag));        
    L = max(L, bloom);
    
    // Construct the body of the hawk from the background bloom. Add contrast and definition using its motion channels.
    vec3 hawkBody = pow(max(kZero, bloom + 0.2) * mix(0.2, 1.5, max(0., hawkTex.y * 0.5 + 0.5)), vec3(2., 1.5, 1.)) * 0.7;
    hawkBody = mix(hawkBody, kOne, hawkTex.z);    
    
    // Composite in the hawk's body
    L = mix(L, hawkBody, hawkTex.w);    
    
    // Apply colour grading more aggressively on the hawk's body
    #define kColourGrade 1.
    rgbaFrag.xyz = mix(L, ApplyRedGrade(L), mix(0.7, 1., hawkTex.w) * kColourGrade);
    rgbaFrag.w = 0.;

}