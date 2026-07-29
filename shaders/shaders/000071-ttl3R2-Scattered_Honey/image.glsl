// Image (image) — Scattered Honey by fizzer
// https://www.shadertoy.com/view/ttl3R2


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord / iResolution.xy * 2. - 1.;
    p.x *= iResolution.x / iResolution.y;

    fragColor = vec4(0);

    float wsum = 0.;

    const int maxRadius = 16;

    int rsq = clamp(int(pow(abs(p.x / 2. + p.y), 1.5) * iResolution.x / 300.), 0, maxRadius);

    if(rsq > 0)
    {
        rsq *= rsq;

        vec2 sz = vec2(textureSize(iChannel0, 0).xy);

        // Depth of field posteffect
        
        for(int y = -maxRadius; y <= +maxRadius; ++y)
            for(int x = -maxRadius; x <= +maxRadius; ++x)
            {
                if(x * x + y * y < rsq)
                {
                    float w = mix(.5, 1., smoothstep(0., 1., length(vec2(x, y)) / float(rsq)));
                    vec4 samp = texelFetch(iChannel0, ivec2(clamp(fragCoord.xy + vec2(x, y), vec2(.5), sz - .5)), 0);
                    samp /= samp.w;
                    fragColor += samp * w;
                    wsum += w;
                }
            }

        fragColor /= wsum;
    }
    else
    {
        fragColor = texelFetch(iChannel0, ivec2(fragCoord.xy), 0);
        fragColor /= fragColor.w;
    }

    // Tonemap and "colourgrade"

    fragColor /= (fragColor + .4) / 2.;
    fragColor.rgb = pow(fragColor.rgb, mix(vec3(1), vec3(1,1.4,1.8), .5));

    // Gamma correction

    fragColor.rgb = pow(clamp(fragColor.rgb, 0., 1.), vec3(1. / 2.2)) +
        texelFetch(iChannel1, ivec2(fragCoord) & 1023, 0).rgb / 100.;
    
    fragColor.a = 1.;
}

