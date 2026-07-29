// Buffer C (buffer) — oilArt by and
// https://www.shadertoy.com/view/lsKGDW

// oilArt - Buf C
//
// Take DCT luminance coefficients from decoders that correspond to blocks with
// smaller error, perform standard JPEG-like de-zigzagging and apply
// Inverse Discrete Cosine Transform (IDCT) to get reconstructed luminance.
// Then add interpolated chrominance that was reconstructed by corresponding
// decoder to build final 496x280 image.
//
// Perform continious reconstruction (fill-in) of missing blocks in a stylized way
// by scattering exising blocks around. And play brush-like revealing effect
// on newly arrived blocks.
//
// Created by Dmitry Andreev - and'2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define STYLIZED_FILLIN    1
#define DO_FILLIN_MISSING  1
#define DO_PAINING_EFFECT  1
#define DO_DUAL_DECODING   1

#define PI 3.14159265

vec4 loadA(int x, int y)
{
    return textureLod(iChannel0, (vec2(x, y) + 0.5) / iChannelResolution[0].xy, 0.0);
}

vec4 loadB(int x, int y)
{
    return textureLod(iChannel1, (vec2(x, y) + 0.5) / iChannelResolution[1].xy, 0.0);
}

vec4 sampleSelf(vec2 pos)
{
    return textureLod(iChannel2, pos / iChannelResolution[2].xy, 0.0);
}

vec4 dct(vec2 cpos, vec4 x, vec4 y)
{
    vec4 wx = 2.0 * cos(PI * x * float(cpos.x * 2.0 + 1.0) / 16.0);
    vec4 wy = 2.0 * cos(PI * y * float(cpos.y * 2.0 + 1.0) / 16.0);

    const float a = 0.17677669; // sqrt(1.0 / (4.0 * 8.0));
    const float b = 0.25;       // sqrt(1.0 / (2.0 * 8.0));

    wx.x *= x.x == 0.0 ? a : b;
    wx.y *= x.y == 0.0 ? a : b;
    wx.z *= x.z == 0.0 ? a : b;
    wx.w *= x.w == 0.0 ? a : b;

    wy.x *= y.x == 0.0 ? a : b;
    wy.y *= y.y == 0.0 ? a : b;
    wy.z *= y.z == 0.0 ? a : b;
    wy.w *= y.w == 0.0 ? a : b;

    return wx * wy;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    if (any(greaterThan(fragCoord, vec2(500, 280)))) discard;

    vec2 bpos = floor(fragCoord / 8.0);
    vec2 cpos = fract(floor(fragCoord) / 8.0) * 8.0;
    cpos.y = 7.0 - cpos.y;

    vec4 old = sampleSelf(bpos * 8.0 + 0.5);

    int cx = int(bpos.x * 4.0);
    int cy = int(bpos.y * 4.0) + 140-60;

    vec4 chroma = vec4(0);
    vec4 val4 = vec4(0);
    vec4 c[12];

    bool is_best_A = true;
    float blockA = loadA(cx+0, cy-3).x;
    float blockB = loadB(cx+0, cy-3).x;

#if DO_DUAL_DECODING
    // Take the best result of two decoders.

    if (blockA > 0.0 && blockB > 0.0)
    {
        is_best_A = blockA <= blockB;
    }
    else if (blockA > 0.0)
    {
        is_best_A = true;
    }
    else
    {
        is_best_A = false;
    }
#else
    is_best_A = true;
#endif

    if (is_best_A)
    {
        chroma = texture(iChannel0, (vec2(260+70, 150-60) + vec2(-1,1) * fragCoord.yx / 4.0) / iChannelResolution[0].xy);
    }
#if DO_DUAL_DECODING
    else
    {
        chroma = texture(iChannel1, (vec2(260+70, 150-60) + vec2(-1,1) * fragCoord.yx / 4.0) / iChannelResolution[1].xy);
    }

    #define C(x,y) (is_best_A ? loadA(cx+x, cy+y) : loadB(cx+x, cy+y))
#else
    #define C(x,y) (loadA(cx+x, cy+y))
#endif

    // 8x8 IDCT of luminance with standard Jpeg zigzag.

    val4 += C(0, 0) * dct(cpos, vec4(0,1,0,0), vec4(0,0,1,2));
    val4 += C(1, 0) * dct(cpos, vec4(1,2,3,2), vec4(1,0,0,1));
    val4 += C(2, 0) * dct(cpos, vec4(1,0,0,1), vec4(2,3,4,3));
    val4 += C(3, 0) * dct(cpos, vec4(2,3,4,5), vec4(2,1,0,0));
    val4 += C(0,-1) * dct(cpos, vec4(4,3,2,1), vec4(1,2,3,4));
    val4 += C(1,-1) * dct(cpos, vec4(0,0,1,2), vec4(5,6,5,4));
    val4 += C(2,-1) * dct(cpos, vec4(3,4,5,6), vec4(3,2,1,0));
    val4 += C(3,-1) * dct(cpos, vec4(7,6,5,4), vec4(0,1,2,3));
    val4 += C(0,-2) * dct(cpos, vec4(3,2,1,0), vec4(4,5,6,7));
    val4 += C(1,-2) * dct(cpos, vec4(1,2,3,4), vec4(7,6,5,4));
    val4 += C(2,-2) * dct(cpos, vec4(5,6,7,7), vec4(3,2,1,2));
    val4 += C(3,-2) * dct(cpos, vec4(6,5,4,3), vec4(3,4,5,6));

    float val = 0.5 + dot(val4, vec4(0.135));

    fragColor = vec4(clamp(val + chroma * 0.55, 0.0, 1.0));

#if DO_PAINING_EFFECT
    // Simple brush-like strokes in empty areas.

    vec2 offs = vec2(
        cos((fragCoord.x + fragCoord.y) * 0.05) * 3.0 + 0.0 -
        cos((fragCoord.x + fragCoord.y) * 3.47) * 0.5,
        sin((fragCoord.x - fragCoord.y) * 0.05) * 3.0 + 3.0 -
        sin((fragCoord.x - fragCoord.y) * 3.47) * 0.5
        );

    float noise = textureLod(iChannel3, (floor(fragCoord) + 0.5) / iChannelResolution[3].xy, 0.0).x;
    vec4 prev = sampleSelf(fragCoord + offs * (0.1 + 0.9 * noise));

    fragColor.rgb = mix(prev.rgb, fragColor.rgb, old.a * old.a);
#endif

    fragColor.rgb = clamp(fragColor.rgb, 0.0, 1.0);

#if DO_FILLIN_MISSING || DO_PAINING_EFFECT
    float block = is_best_A ? blockA : blockB;

    fragColor.a = old.a;

    if (block <= 0.0001)
    {
    #if STYLIZED_FILLIN
        vec2 noise2 = texture(iChannel3, (floor(fragCoord * 1.9) + 0.5) / iChannelResolution[3].xy).xy;
        fragCoord += (noise2 * 2.0 - 1.0) * 2.5;
        fragCoord = min(fragCoord, vec2(498, 278));
    #endif

        // Diffuse surrounding if block doesn't exist.

        fragCoord = min(fragCoord, vec2(498, 278));

        vec3 c  = sampleSelf(fragCoord).rgb;
        vec3 v0 = sampleSelf(fragCoord + vec2(-1, 0)).rgb;
        vec3 v1 = sampleSelf(fragCoord + vec2( 1, 0)).rgb;
        vec3 v2 = sampleSelf(fragCoord + vec2( 0,-1)).rgb;
        vec3 v3 = sampleSelf(fragCoord + vec2( 0, 1)).rgb;

        vec3 avg = (v0 + v1 + v2 + v3) * 0.25;
        float wx = abs(v0.g - v1.g);
        float wy = abs(v2.g - v3.g);

        // Make it less uniform by using horizontal and vertical gradients.
    #if DO_FILLIN_MISSING
        fragColor.xyz = wx > wy ?
              mix(avg, (v0 + v1) * 0.5, 0.75)
            : mix(avg, (v2 + v3) * 0.5, 0.75);

        fragColor.rgb = mix(fragColor.rgb, (v3 * 8.0 + v2 * 6.0 + v0 + v1) / 16.0, 0.5);
    #endif
    }
    else
    {
        // Advance time of existing block for painting effect.
        fragColor.a = min(1.0, old.a + (1.0 / 45.0));
    }
#endif

    // Initialize with paper color.
    fragColor = iFrame == 0 ? vec4(0.815, 0.815, 0.815, 0) : fragColor;
}
