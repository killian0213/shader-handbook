// Buffer B (buffer) — grass field with blades by MonterMan
// https://www.shadertoy.com/view/dd2cWh

// credit to TheRealMJP for for CatmullRom sampling code: https://gist.github.com/TheRealMJP/c83b8c0f46b63f3a88a5986f4fa982b1
// The following code is licensed under the MIT license: https://gist.github.com/TheRealMJP/bc503b0b87b643d3505d41eab8b332ae
// Samples a texture with Catmull-Rom filtering, using 9 texture fetches instead of 16.
// See http://vec3.ca/bicubic-filtering-in-fewer-taps/ for more details
vec4 sampleHistCatmullRom(in vec2 uv, in vec2 texSize)
{
    // We're going to sample a a 4x4 grid of texels surrounding the target UV coordinate. We'll do this by rounding
    // down the sample location to get the exact center of our "starting" texel. The starting texel will be at
    // location [1, 1] in the grid, where [0, 0] is the top left corner.
    vec2 samplePos = uv * texSize;
    vec2 texPos1 = floor(samplePos - 0.5f) + 0.5f;

    // Compute the fractional offset from our starting texel to our original sample location, which we'll
    // feed into the Catmull-Rom spline function to get our filter weights.
    vec2 f = samplePos - texPos1;

    // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
    // These equations are pre-expanded based on our knowledge of where the texels will be located,
    // which lets us avoid having to evaluate a piece-wise function.
    vec2 w0 = f * (-0.5f + f * (1.0f - 0.5f * f));
    vec2 w1 = 1.0f + f * f * (-2.5f + 1.5f * f);
    vec2 w2 = f * (0.5f + f * (2.0f - 1.5f * f));
    vec2 w3 = f * f * (-0.5f + 0.5f * f);

    // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
    // simultaneously evaluate the middle 2 samples from the 4x4 grid.
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / (w1 + w2);

    // Compute the final UV coordinates we'll use for sampling the texture
    vec2 texPos0 = texPos1 - vec2(1);
    vec2 texPos3 = texPos1 + vec2(2);
    vec2 texPos12 = texPos1 + offset12;

    texPos0 /= texSize;
    texPos3 /= texSize;
    texPos12 /= texSize;

    vec4 result = vec4(0);
    result += texture(iChannel1, vec2(texPos0.x, texPos0.y)) * w0.x * w0.y;
    result += texture(iChannel1, vec2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += texture(iChannel1, vec2(texPos3.x, texPos0.y)) * w3.x * w0.y;

    result += texture(iChannel1, vec2(texPos0.x, texPos12.y)) * w0.x * w12.y;
    result += texture(iChannel1, vec2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += texture(iChannel1, vec2(texPos3.x, texPos12.y)) * w3.x * w12.y;

    result += texture(iChannel1, vec2(texPos0.x, texPos3.y)) * w0.x * w3.y;
    result += texture(iChannel1, vec2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += texture(iChannel1, vec2(texPos3.x, texPos3.y)) * w3.x * w3.y;

    return result;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = 2.0 * uv - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    if (iFrame == 0)
    {
        fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
        return;
    }

    // iChannel0 (buffer A): curr buffer
    // iChannel1 (buffer C): hist buffer
    
    int currIndex = iFrame & 1;
    int prevIndex = (currIndex + 1) & 1;
    vec3 currCamOrigin = texelFetch(iChannel0, ivec2(currIndex*2 + 0, 0), 0).rgb;
    vec3 currCamAt = texelFetch(iChannel0, ivec2(currIndex*2 + 1, 0), 0).rgb;
    vec3 prevCamOrigin = texelFetch(iChannel0, ivec2(prevIndex*2 + 0, 0), 0).rgb;
    vec3 prevCamAt = texelFetch(iChannel0, ivec2(prevIndex*2 + 1, 0), 0).rgb;

    float currDepth = texelFetch(iChannel0, ivec2(fragCoord), 0).a;
    if (currDepth > 100000.0)
    {
        fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
        return;
    }
    
    float filmDist = 1.3;
    mat3 cameraMat = calcCameraMat(currCamOrigin, currCamAt);
    vec3 rd = normalize(cameraMat * vec3(uv, filmDist));
    
    // reprojection
    vec3 currPos = currCamOrigin + currDepth * rd;
    vec3 prevRd = normalize(currPos - prevCamOrigin);
    vec2 prevUv = rd2uv(prevRd, prevCamOrigin, prevCamAt, filmDist, iResolution.x/iResolution.y);

    vec3 curr = texelFetch(iChannel0, ivec2(fragCoord), 0).rgb;
    //vec3 hist = texture(iChannel1, prevUv.xy).rgb;
    vec3 hist = sampleHistCatmullRom(prevUv.xy, iResolution.xy).rgb;
    
    float histWeight = 0.9;
    if (any(greaterThan(prevUv.xy, vec2(1.0))) ||
        any(lessThan(prevUv.xy, vec2(0.0))))
    {
        histWeight = 0.0;
    }
    
    // neighborhood clamping
    vec3 neighborMin = vec3(10e31);
    vec3 neighborMax = vec3(0);
    float neighborSize = 0.5;
    for (int dy = -1; dy <= 1; ++dy)
    {
        for (int dx = -1; dx <= 1; ++dx)
        {
            vec2 neighborTexelAddr = (fragCoord + neighborSize*vec2(dx, dy))/iResolution.xy;
            vec3 neighborSample = texture(iChannel0, neighborTexelAddr).rgb;
            neighborSample = rgb2yCoCg(neighborSample);
            neighborMin = min(neighborMin, neighborSample);
            neighborMax = max(neighborMax, neighborSample);
        }
    }
    hist = rgb2yCoCg(hist);
    hist = clipToBox(hist, neighborMin, neighborMax);
    hist = yCoCg2rgb(hist);
    
    fragColor = vec4(mix(curr, hist, vec3(histWeight)), 1.0);
    //fragColor = vec4(abs(uv - prevUv), 0.0, 1.0);
}