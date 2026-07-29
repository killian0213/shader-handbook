// Image (image) — Interactive fluid with caustics by tmst
// https://www.shadertoy.com/view/ttdXRf

//#define DEBUG_OUTPUT

#define W_0 0.05675675675
#define W_1 0.1581081081
#define W_2 0.03513513515

#define BLUR_MAX_PCT 0.004

#define VIGNETTE_INTENSITY 0.4

vec3 blurSample(sampler2D tex, vec2 uv, float blurAmount) {
    float pct = blurAmount*BLUR_MAX_PCT;
    vec2 sampleRBase = vec2(1.0, iResolution.y/iResolution.x);
    vec3 finalColor = vec3(0.0);

    vec2 sampleR = pct * sampleRBase;
    float ra = rand(uv)*PI_OVER_4;
    float rs = sin(ra);
    float rc = cos(ra);
    finalColor += W_0 * textureLod(tex, uv + vec2( rc, rs)*sampleR, 0.0).rgb;
    finalColor += W_0 * textureLod(tex, uv + vec2(-rs, rc)*sampleR, 0.0).rgb;
    finalColor += W_0 * textureLod(tex, uv + vec2(-rc,-rs)*sampleR, 0.0).rgb;
    finalColor += W_0 * textureLod(tex, uv + vec2( rs,-rc)*sampleR, 0.0).rgb;

    sampleR = 2.0 * pct * sampleRBase;
    ra += PI_OVER_4;
    rs = sin(ra);
    rc = cos(ra);
    finalColor += W_1 * textureLod(tex, uv + vec2( rc, rs)*sampleR, 0.0).rgb;
    finalColor += W_1 * textureLod(tex, uv + vec2(-rs, rc)*sampleR, 0.0).rgb;
    finalColor += W_1 * textureLod(tex, uv + vec2(-rc,-rs)*sampleR, 0.0).rgb;
    finalColor += W_1 * textureLod(tex, uv + vec2( rs,-rc)*sampleR, 0.0).rgb;

    sampleR = 3.0 * pct * sampleRBase;
    ra += PI_OVER_4;
    rs = sin(ra);
    rc = cos(ra);
    finalColor += W_2 * textureLod(tex, uv + vec2( rc, rs)*sampleR, 0.0).rgb;
    finalColor += W_2 * textureLod(tex, uv + vec2(-rs, rc)*sampleR, 0.0).rgb;
    finalColor += W_2 * textureLod(tex, uv + vec2(-rc,-rs)*sampleR, 0.0).rgb;
    finalColor += W_2 * textureLod(tex, uv + vec2( rs,-rc)*sampleR, 0.0).rgb;

    return finalColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    float blurAmount = textureLod(iChannel0, uv, 0.0).a;
    vec3 blurColor = blurSample(iChannel0, uv, blurAmount);

    float dCorner = length(uv - vec2(0.5)) * 1.414214;
    float vignetteFactor = 1.0 - mix(0.0, VIGNETTE_INTENSITY, smoothstep(0.3, 0.9, dCorner));

    fragColor = vec4(vignetteFactor*blurColor, 1.0);

    #ifdef DEBUG_OUTPUT
        vec2 r = uv * vec2(3.0, 2.0);
        int page = 1 + int(floor(r.y))*3 + int(floor(r.x));
        vec2 fragCoordDebug = fract(r) * vec2(1024.0);

        vec4 debugColor = texture(iChannel1, vcubeFromFragCoord(page, fragCoordDebug));
        float debugAlpha = 0.6;
        fragColor = mix(fragColor, debugColor, debugAlpha);
    #endif
}
