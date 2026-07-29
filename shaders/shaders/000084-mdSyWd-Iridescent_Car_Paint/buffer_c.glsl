// Buffer C (buffer) — Iridescent Car Paint by piyushslayer
// https://www.shadertoy.com/view/mdSyWd

/**
    TAA pass for anti-aliasing, and getting rid of some of that nasty noise. Enable or disable TAA in the common tab.
*/

#if TAA_ENABLED

#define TAA_USE_NEAREST_DEPTH 1

#define TAA_PERFORM_TONEMAP 1
#define TAA_CONVERT_TO_YCOCG 1

#define TAA_FILTERED_INPUT 1
#if TAA_FILTERED_INPUT
    #define TAA_FILTERED_PLUS_WEIGHTS 1
#endif

#define TAA_ANTI_GHOSTING 1

const ivec2 NeighborhoodOffsets[9] = ivec2[](
    ivec2(-1,  0),
    ivec2( 1,  0),
    ivec2( 0,  1),
    ivec2( 0, -1),
    ivec2( 0,  0),
    ivec2(-1, -1),
    ivec2( 1, -1),
    ivec2(-1,  1),
    ivec2( 1,  1)
);

const float GaussianWeights[3] = float[](0.25, 0.125, 0.0625);

float GetLuma(in vec3 color)
{
    // ITU-R BT.2020 color space
    // return dot(color, vec3(0.2627, 0.6780, 0.0593);

    // ITU-R BT.709 color space
    // return dot(color, vec3(0.2126, 0.7152, 0.0722));
    
    // ITU-R BT.601 color space
    return dot(color, vec3(0.299, 0.587, 0.114));
}

float HDRTonemap(in float luma)
{
    return 1.0 / (1.0 + luma);
}

float HDRTonemapInverse(in float luma)
{
    return 1.0 / (1.0 - luma);
}

vec3 RGBToYCoCg(in vec3 RGB)
{
#if 0
    return vec3(dot(RGB, vec3(0.25f, 0.5f, 0.25f)),
                dot(RGB, vec3(0.5f, 0.0f, -0.5f)),
                dot(RGB, vec3(-0.25f, 0.5f, -0.25f)));
#else
    return RGB * mat3(0.25f, 0.5f,  0.25f,
                      0.5f,  0.0f, -0.5f,
                     -0.25f, 0.5f, -0.25f); // inverse multiply because per channel weights stored as columns (instead of rows) to match the above for readability. 
#endif
}


vec3 YCoCgToRGB(in vec3 YCoCg)
{
    return vec3(YCoCg.x + YCoCg.y - YCoCg.z,
                YCoCg.x + YCoCg.z,
                YCoCg.x - YCoCg.y - YCoCg.z);
}

vec4 FromRGB(in vec4 color)
{
    color.xyz = max(color.xyz, vec3(SMOL_EPS));
    
#if TAA_PERFORM_TONEMAP
    color.xyz *= HDRTonemap(GetLuma(color.xyz));
#endif

#if TAA_CONVERT_TO_YCOCG 
    color.xyz = RGBToYCoCg(color.xyz);
#endif

    return color;
}

vec3 ToRGB(in vec3 color)
{
#if TAA_CONVERT_TO_YCOCG
    vec3 result = YCoCgToRGB(color);
#endif

#if TAA_PERFORM_TONEMAP
    result *= HDRTonemapInverse(GetLuma(result));
#endif
    
    return max(result, vec3(SMOL_EPS));
}

float FindNearestDepth(in vec4 neighborhoodSamples[9u])
{
    float nearestDepth = neighborhoodSamples[4u].w;
    
#if TAA_USE_NEAREST_DEPTH
    vec4 diagonalNeighbors = vec4(neighborhoodSamples[5u].w, neighborhoodSamples[6u].w,
                                  neighborhoodSamples[7u].w, neighborhoodSamples[8u].w);
                                  
    float nearestBottom    = min(diagonalNeighbors.x, diagonalNeighbors.y);
    float nearestTop       = min(diagonalNeighbors.z, diagonalNeighbors.w);
    float nearestDiagonal  = min(nearestBottom, nearestTop);
    
    nearestDepth = min(nearestDepth, nearestDiagonal);
#endif

    return nearestDepth;
}

vec2 CalculateHistoryUV(in vec4 worldPosition, in vec2 historyCameraAngles, in vec2 haltonOffset)
{
    mat4 historyWorldToView = GetCameraWorldToView(historyCameraAngles);
                        
    vec3 viewPosition = (worldPosition * historyWorldToView).xyz; // Note: view matrix is stored in row major, hence the inverse multiply.
    vec2 uvHistory = CAMERA_ZOOM * viewPosition.xy / viewPosition.z;
    uvHistory = 0.5 + uvHistory * vec2(iResolution.y / iResolution.x, 1.0);
    uvHistory -= haltonOffset / iResolution.xy; // remove jitter
    return uvHistory;
}

void FetchNeighborhoodSamples(in sampler2D inputColor, in ivec2 texCoord, out vec4 neighborhoodSamples[9u])
{
    for (uint i = 0u; i < 9u; ++i)
    {
        neighborhoodSamples[i] = FromRGB(texelFetch(inputColor, texCoord + NeighborhoodOffsets[i], 0));
    }
}

vec4 FilterInput(in vec4 neighborhoodSamples[9u], in vec2 jitter)
{
#if TAA_FILTERED_INPUT
    float totalWeight = 0.0;
    vec2 pixelOffset = vec2(0.0);
    
#if TAA_FILTERED_PLUS_WEIGHTS
    float plusWeights[5u];
    for (uint i = 0u; i < 5u; ++i)
    {
        pixelOffset = vec2(NeighborhoodOffsets[i]) - jitter * 1.0;
        plusWeights[i] = exp(-2.29f * dot(pixelOffset, pixelOffset));
        totalWeight += plusWeights[i];
    }
    
    for (uint i = 0u; i < 5u; ++i)
    {
        plusWeights[i] *= 1.0 / totalWeight;
    }
    
    return neighborhoodSamples[0u] * plusWeights[0u] + neighborhoodSamples[1u] * plusWeights[1u]
         + neighborhoodSamples[2u] * plusWeights[2u] + neighborhoodSamples[3u] * plusWeights[3u]
         + neighborhoodSamples[4u] * plusWeights[4u];
#else
    float gaussianWeights[9u];
    for (uint i = 0u; i < 9u; ++i)
    {
        pixelOffset = vec2(NeighborhoodOffsets[i]) - jitter * 1.0;
        gaussianWeights[i] = exp(-2.29f * dot(pixelOffset, pixelOffset));
        totalWeight += gaussianWeights[i];
    }
    
    for (uint i = 0u; i < 9u; ++i)
    {
        gaussianWeights[i] *= 1.0 / totalWeight;
    }
    
    return neighborhoodSamples[0u] * gaussianWeights[0u] + neighborhoodSamples[1u] * gaussianWeights[1u]
         + neighborhoodSamples[2u] * gaussianWeights[2u] + neighborhoodSamples[3u] * gaussianWeights[3u]
         + neighborhoodSamples[4u] * gaussianWeights[4u] + neighborhoodSamples[5u] * gaussianWeights[5u]
         + neighborhoodSamples[6u] * gaussianWeights[6u] + neighborhoodSamples[7u] * gaussianWeights[7u]
         + neighborhoodSamples[8u] * gaussianWeights[8u];
#endif
#else
    return neighborhoodSamples[4u];
#endif
}

// Courtesy of TheRealMJP: https://gist.github.com/TheRealMJP/c83b8c0f46b63f3a88a5986f4fa982b1
vec4 SampleHistoryCatmullRom(in sampler2D history, in vec2 uv, in vec2 texSize)
{
    // We're going to sample a a 4x4 grid of texels surrounding the target UV coordinate. We'll do this by rounding
    // down the sample location to get the exact center of our "starting" texel. The starting texel will be at
    // location [1, 1] in the grid, where [0, 0] is the top left corner.
    vec2 samplePos = uv * texSize;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;

    // Compute the fractional offset from our starting texel to our original sample location, which we'll
    // feed into the Catmull-Rom spline function to get our filter weights.
    vec2 f = samplePos - texPos1;

    // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
    // These equations are pre-expanded based on our knowledge of where the texels will be located,
    // which lets us avoid having to evaluate a piece-wise function.
    vec2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
    vec2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
    vec2 w3 = f * f * (-0.5 + 0.5 * f);

    // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
    // simultaneously evaluate the middle 2 samples from the 4x4 grid.
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / (w1 + w2);

    // Compute the final UV coordinates we'll use for sampling the texture
    vec2 texPos0 = texPos1 - 1.0;
    vec2 texPos3 = texPos1 + 2.0;
    vec2 texPos12 = texPos1 + offset12;

    texPos0 /= texSize;
    texPos3 /= texSize;
    texPos12 /= texSize;

    vec4 result = vec4(0.0);
    result += textureLod(history, vec2(texPos0.x, texPos0.y), 0.0) * w0.x * w0.y;
    result += textureLod(history, vec2(texPos12.x, texPos0.y), 0.0) * w12.x * w0.y;
    result += textureLod(history, vec2(texPos3.x, texPos0.y), 0.0) * w3.x * w0.y;

    result += textureLod(history, vec2(texPos0.x, texPos12.y), 0.0) * w0.x * w12.y;
    result += textureLod(history, vec2(texPos12.x, texPos12.y), 0.0) * w12.x * w12.y;
    result += textureLod(history, vec2(texPos3.x, texPos12.y), 0.0) * w3.x * w12.y;

    result += textureLod(history, vec2(texPos0.x, texPos3.y), 0.0f) * w0.x * w3.y;
    result += textureLod(history, vec2(texPos12.x, texPos3.y), 0.0) * w12.x * w3.y;
    result += textureLod(history, vec2(texPos3.x, texPos3.y), 0.0f) * w3.x * w3.y;

    return result;
}

void ComputeMeanVariance(in vec4 neighborhoodSamples[9u], out vec3 mean, out vec3 variance)
{
    const float totalNeighborhoodSamplesInv = 1.0 / 9.0;
    vec3 m1  = neighborhoodSamples[0u].xyz + neighborhoodSamples[1u].xyz + neighborhoodSamples[2u].xyz + neighborhoodSamples[3u].xyz 
             + neighborhoodSamples[4u].xyz + neighborhoodSamples[5u].xyz + neighborhoodSamples[6u].xyz + neighborhoodSamples[7u].xyz
             + neighborhoodSamples[8u].xyz;
    vec3 m2  = neighborhoodSamples[0u].xyz * neighborhoodSamples[0u].xyz + neighborhoodSamples[1u].xyz * neighborhoodSamples[1u].xyz 
             + neighborhoodSamples[2u].xyz * neighborhoodSamples[2u].xyz + neighborhoodSamples[3u].xyz * neighborhoodSamples[3u].xyz 
             + neighborhoodSamples[4u].xyz * neighborhoodSamples[4u].xyz + neighborhoodSamples[5u].xyz * neighborhoodSamples[5u].xyz
			 + neighborhoodSamples[6u].xyz * neighborhoodSamples[6u].xyz + neighborhoodSamples[7u].xyz * neighborhoodSamples[7u].xyz
             + neighborhoodSamples[8u].xyz * neighborhoodSamples[8u].xyz;
    mean     = m1 * totalNeighborhoodSamplesInv;
    variance = sqrt(abs(m2 * totalNeighborhoodSamplesInv - mean * mean));
}

float DisocclusionAntiGhosting(in float nearestDepth, in vec2 uvHistory, in sampler2D inputBuffer)
{
#if TAA_ANTI_GHOSTING
    const ivec2 offset = ivec2(-1, 1);
    
    ivec2 historyCoord = ivec2(uvHistory * iResolution.xy);
    float nearestHistoryDepth = texelFetch(inputBuffer, historyCoord, 0).w; 
    
    vec4 historyDepthCorners = vec4(texelFetch(inputBuffer, historyCoord + offset.xx, 0).w,
                                    texelFetch(inputBuffer, historyCoord + offset.yx, 0).w,
                                    texelFetch(inputBuffer, historyCoord + offset.xy, 0).w,
                                    texelFetch(inputBuffer, historyCoord + offset.yy, 0).w);
                                    
    float nearestHistoryDepthCorner = min(min(historyDepthCorners.x, historyDepthCorners.y), min(historyDepthCorners.z, historyDepthCorners.w));
    nearestHistoryDepth = min(nearestHistoryDepthCorner, nearestHistoryDepth);
    
    return Saturate((abs(nearestDepth - nearestHistoryDepth) - 0.001) * 10.0);
#else
    return 0.0;
#endif
}

vec4 ClipHistoryColor(in vec4 historyColor, in vec4 neighborhoodSamples[9u], float disocclusionFactor)
{
    vec3 mean, variance;
    ComputeMeanVariance(neighborhoodSamples, mean, variance);
    
    float varianceScale = 1.25;
    varianceScale *= max(0.25, 1.0 - disocclusionFactor);
    variance *= varianceScale;
    
    vec3 historyMin = mean - variance;
    vec3 historyMax = mean + variance;
    historyColor.xyz = clamp(historyColor.xyz, historyMin, historyMax);
    return historyColor;
}

#endif

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
#if TAA_ENABLED
    // Halton sequence generated offline within range [-0.5, 0.5]
    vec2 offset = HaltonSequence[uint(iFrame) % 16u];
    // Pixel coordinates [-0.5, 0.5]
    vec2 halfNdc = (fragCoord + offset - 0.5 * iResolution.xy) / iResolution.y;
    // Normalized camera angles in range [0.0, 1.0], xy - history, zw - current frame.
    vec4 cachedCameraAngles = texelFetch(iChannel1, ivec2(0), 0);
    
    vec4 neighborhoodSamples[9u];
    FetchNeighborhoodSamples(iChannel1, ivec2(fragCoord), neighborhoodSamples);
    
    // Current frame data, xyz - color, w - ray hit distance    
    vec4 currentColor = FilterInput(neighborhoodSamples, offset);
    float nearestDepth = FindNearestDepth(neighborhoodSamples);
    
    Ray sceneRay = GetCameraRay(halfNdc, cachedCameraAngles.zw);
    vec2 uvHistory = CalculateHistoryUV(vec4(sceneRay.origin + sceneRay.direction * nearestDepth, 1.0), cachedCameraAngles.xy, offset);
    
    float velocityMagnitude = length(fragCoord / iResolution.xy - uvHistory);
    
    float disocclusionFactor = DisocclusionAntiGhosting(nearestDepth, uvHistory, iChannel1);
    vec4 historyColor = FromRGB(min(max(SampleHistoryCatmullRom(iChannel0, uvHistory, iResolution.xy), vec4(1e-6)), FLT_MAX));
    historyColor = ClipHistoryColor(historyColor, neighborhoodSamples, disocclusionFactor);
    
    float blendWeight = mix(0.05, 0.3, Saturate(velocityMagnitude * 2.5));
    blendWeight = mix(blendWeight, 1.0, disocclusionFactor);
    
    if (any(lessThan(uvHistory, vec2(0.0))) || any(greaterThanEqual(uvHistory, vec2(1.0))) || any(isnan(uvHistory)) || any(isinf(uvHistory)))
    {
        blendWeight = 1.0;
    }
    
    currentColor.xyz = mix(historyColor.xyz, currentColor.xyz, blendWeight);
    
    fragColor = vec4(ToRGB(currentColor.xyz), nearestDepth);    
#else
    fragColor = texelFetch(iChannel1, ivec2(fragCoord), 0);
#endif
}