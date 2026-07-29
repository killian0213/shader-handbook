// Image (image) — oilArt by and
// https://www.shadertoy.com/view/lsKGDW

// oilArt - Image
//
// Final shader in the pipeline. Draw thumbnail when resolution is too small
// or when in sort of preview mode. Fit image to avoid cropping.
// Increase sharpness and additionally refine edges without introducing ringing.
// Render decoder's internal state for debugging.
// 
// Created by Dmitry Andreev - and'2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define DO_SHARPEN       1
#define DO_OILIFY        1

#define DEBUG_DECODER    0
#define DEBUG_SAMPLERATE 0

//

void drawThumbnail(out vec4 fragColor, in vec2 fragCoord)
{
    // 3rd order 2D polynomial.

    vec3 c0  = vec3(  0.94,  0.70,  0.43);
    vec3 c1  = vec3(  0.41,  0.52, -0.06);
    vec3 c2  = vec3( -1.39, -0.94,  2.21);
    vec3 c3  = vec3(  0.78,  0.51, -1.62);
    vec3 c4  = vec3( -0.75, -0.96, -0.79);
    vec3 c5  = vec3(  6.46, 10.74,  1.49);
    vec3 c6  = vec3(-11.55,-21.27, -0.07);
    vec3 c7  = vec3(  5.77, 11.48, -0.64);
    vec3 c8  = vec3(  1.14,  1.16,  3.35);
    vec3 c9  = vec3(-11.94,-22.10,-14.41);
    vec3 c10 = vec3( 23.46, 48.26, 21.20);
    vec3 c11 = vec3(-12.36,-27.09,-10.25);
    vec3 c12 = vec3( -0.70, -0.62, -2.90);
    vec3 c13 = vec3(  5.93, 12.16, 14.62);
    vec3 c14 = vec3(-11.05,-26.58,-24.21);
    vec3 c15 = vec3(  5.60, 14.77, 12.52);

    vec2  t = floor(fragCoord / 12.0) * 12.0 / iResolution.xy;
    float x = t.x;
    float y = 1.0 - t.y;

    vec3 f = vec3(
           ( c0 + ( c1 + ( c2 +  c3*x)*x)*x) +
        y*(( c4 + ( c5 + ( c6 +  c7*x)*x)*x) +
        y*(( c8 + ( c9 + (c10 + c11*x)*x)*x) +
        y*( c12 + (c13 + (c14 + c15*x)*x)*x))));

    vec3 clr = smoothstep(0.0, 1.0, f*f*f*f);

    // Playback triangle.

    vec2 tc = fragCoord / iResolution.xy;
    vec2 p = 1.5 * (tc - 0.5) * vec2(1.0, iResolution.y / iResolution.x);
    float d = length( p );

    clr = mix(clr, vec3(0), 0.6 * clamp(23.0 - 128.0 * d, 0.0, 1.0));
    clr = mix(clr, vec3(1), clamp(3.0 - 128.0 * abs(0.5 - d * 3.0), 0.0, 1.0));

    p *= 1.5;
    p += vec2(0.06, 0);

    float m = dot(p, vec2(2.0, 0.0));
    m = min(m, dot(p + vec2(0.0, 0.15), vec2(-0.8, 1.0)));
    m = min(m, dot(p + vec2(0.0,-0.15), vec2(-0.8,-1.0)));
    m = max(m, 0.0);

    fragColor.rgb = mix(clr, vec3(1.0), vec3(m * 200.0));
}

void oilify3(inout vec2 h[16], float d, vec2 tc, vec2 tc_max)
{
    vec3 c = texture(iChannel1, min(tc / iResolution.xy, tc_max)).rgb;

    float luma = dot(c, vec3(0.33));
    float L = floor(0.5 + luma * 15.0 + d);

    #define H(n) h[n] += L == float(n) ? vec2(luma, 1) : vec2(0);

    H(0)H(1)H(2)H(3)H(4)H(5)H(6)H(7)
    H(8)H(9)H(10)H(11)H(12)H(13)H(14)H(15)
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    if (iResolution.x < 500.0 || iResolution.y < 280.0)
    {
        drawThumbnail(fragColor, fragCoord);
        return;
    }

    // Fit image to touch screen from inside.

    vec2 img_res = vec2(496, 279);
    vec2 res = iResolution.xy / img_res;
    vec2 img_size = img_res * min(res.x, res.y);
    vec2 img_org = 0.5 * (iResolution.xy - img_size);
    vec2 tc = (fragCoord - img_org) / img_size;

    fragColor = texture(iChannel1, tc * img_res / iResolution.xy);

    #if DO_SHARPEN
    {
        // Regular high-pass filter to recover some sharpness.

        fragColor *= 8.0;
        fragColor -= texture(iChannel1, min((tc * img_res + vec2( 1,0)) / iResolution.xy, vec2(img_res) / iChannelResolution[1].xy));
        fragColor -= texture(iChannel1, min((tc * img_res + vec2(-1,0)) / iResolution.xy, vec2(img_res) / iChannelResolution[1].xy));
        fragColor -= texture(iChannel1, min((tc * img_res + vec2(0, 1)) / iResolution.xy, vec2(img_res) / iChannelResolution[1].xy));
        fragColor -= texture(iChannel1, min((tc * img_res + vec2(0,-1)) / iResolution.xy, vec2(img_res) / iChannelResolution[1].xy));
        fragColor *= 0.25;
    }
    #endif

    #if DO_OILIFY
    {
        // Additinal edge sharpening assuming it is a painting.
        // Effect similar to GIMP's Oilify.
        // Calculate 16 bin histogram for 3x3 neighborhood
        // and pick averaged color of bin that had most pixels.

        vec2 h[16];

        for (int i = 0; i < 16; i++) h[i] = vec2(0);

        // Add some noise to hide low bin count.

        float d = 0.5 * texture(iChannel2, 0.95 * fragCoord / iChannelResolution[2].xy).x;

        for (int y = -1; y <= 1; y++)
        {
            oilify3(h, d, tc * img_res + vec2(-1, y), img_res / iChannelResolution[1].xy);
            oilify3(h, d, tc * img_res + vec2( 0, y), img_res / iChannelResolution[1].xy);
            oilify3(h, d, tc * img_res + vec2( 1, y), img_res / iChannelResolution[1].xy);
        }

        vec2 q = vec2(0);

        #define Q(n) q = h[n].y > q.y ? h[n] : q;

        Q(0)Q(1)Q(2)Q(3)
        Q(4)Q(5)Q(6)Q(7)
        Q(8)Q(9)Q(10)Q(11)
        Q(12)Q(13)Q(14)Q(15)

        vec4 org = texture(iChannel1, tc * img_res / iResolution.xy);
        float luma = dot(org.rgb, vec3(0.33));
        vec3 clr = org.rgb - luma + q.x / q.y;

        fragColor.rgb = mix(fragColor.rgb, clr.rgb, 0.3);

        float emb =
            texture(iChannel2, 0.95 * (fragCoord + vec2(0.5, -0.5)) / iChannelResolution[2].xy).x -
            texture(iChannel2, 0.95 * (fragCoord - vec2(0.5, -0.5)) / iChannelResolution[2].xy).x;

        fragColor.rgb *= 0.95 + 0.20 * d + 0.1 * emb;
    }
    #endif

    // Add black bars around the image when needed.

    fragColor = any(greaterThan(abs(tc - 0.5), vec2(0.5))) ? vec4(0) : fragColor;

    #if DEBUG_DECODER
    {
        fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
        if (all(equal(fragColor, vec4(0)))) fragColor = vec4(0.5,0,0,0);
    }
    #endif

    #if DEBUG_SAMPLERATE
    {
        if (fragCoord.x > iResolution.x - 5.0)
        {
            float n = texture(iChannel0, vec2(0.5, 1.5) / iChannelResolution[0].xy).w;
            fragColor.xyz = mix(fragColor.xyz, vec3(1,0,0), 0.5 * float(fragCoord.y < n * 20.0));
            fragColor.xyz = mix(fragColor.xyz, vec3(1,0,0), pow(fract(fragCoord.y / 20.0), 8.0));
        }
    }
    #endif
}
