// Buffer D (buffer) — Swiss Alps by piyushslayer
// https://www.shadertoy.com/view/ttcSD8

/**
  Buffer D performs TXAA on the clouds from buffer C to hide some blue noise and
  ghosting artifacts.
*/

const ivec2 offsets[8u] = ivec2[]
(
    ivec2(-1,-1), ivec2(-1, 1), 
	ivec2(1, -1), ivec2(1, 1), 
	ivec2(1, 0), ivec2(0, -1), 
	ivec2(0, 1), ivec2(-1, 0)
);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec4 currentBuffer = textureLod(iChannel0, uv, 0.);
    vec4 historyBuffer = textureLod(iChannel1, uv, 0.);

    vec4 colorAvg = currentBuffer;
    vec4 colorVar = currentBuffer * currentBuffer;
    
    // Marco Salvi's Implementation (by Chris Wyman)
    for(int i = 0; i < 8; i++)
    {
        vec4 neighborTexel = texelFetch(iChannel0, ivec2(fragCoord.xy) + offsets[i], 0);
        colorAvg += neighborTexel;
        colorVar += neighborTexel * neighborTexel;
    }
    colorAvg /= 9.;
    colorVar /= 9.;
    float gColorBoxSigma = .75;
	vec4 sigma = sqrt(max(vec4(0.), colorVar - colorAvg * colorAvg));
	vec4 colorMin = colorAvg - gColorBoxSigma * sigma;
	vec4 colorMax = colorAvg + gColorBoxSigma * sigma;
    
    historyBuffer = clamp(historyBuffer, colorMin, colorMax);

	fragColor = mix(currentBuffer, historyBuffer, 0.95);
}