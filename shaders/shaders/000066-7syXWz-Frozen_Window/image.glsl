// Image (image) — Frozen Window by davidar
// https://www.shadertoy.com/view/7syXWz

#define AA 2

#define T(p) texture(iChannel0, mat2(1,0,.5,1) * mat2(1,0,0,1.25) * (p) / (1.25 * iResolution.xy)).x

vec4 render(vec2 fragCoord)
{
    float cell  = T(fragCoord);
    float cellx = T(fragCoord + vec2(1,0));
    float celly = T(fragCoord + vec2(0,1));

    vec4 fragColor = 0.75 * texture(iChannel2, vec3((fragCoord - iResolution.xy/2.)/iResolution.y, -0.5));
    fragColor = mix(fragColor, vec4(1), smoothstep(0., 1., cell));
    fragColor = mix(fragColor, vec4(0.25), smoothstep(1., 6., cell));

    float focus = 6. - clamp(cell, 0., 4.);
    vec2 grad = vec2(cellx, celly) - cell;
    vec2 uv = (fragCoord + 100. * grad) / iResolution.xy;
    vec3 ray = vec3(uv, -0.5) - vec3(0.5,0.1,0);
    fragColor = textureLod(iChannel2, ray, focus);
    fragColor = mix(fragColor, texture(iChannel3, ray), smoothstep(0., 0.9, cell) - smoothstep(0.9, 1., cell));
    fragColor += 0.2 * dot(grad, vec2(1));
    return fragColor;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0);
    for (int i = 0; i < AA; i++) for (int j = 0; j < AA; j++)
        fragColor += render(fragCoord + vec2(i,j)/2.) / float(AA*AA);
}
