// Image (image) — Inky by huwb
// https://www.shadertoy.com/view/4d3SD8

// Music is Save Me by Majik: https://soundcloud.com/majikband/save-me-majik-2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    // read for accum buffer
    fragColor = 1. - textureLod( iChannel0, uv, 0. );
    
    // tint
    fragColor.xyz *= .8;
    fragColor.xyz += 1.5*vec3(.15,.3,.8);
    
    // vign, treatment
    fragColor *= 1. - .17*length(2. * uv - 1.);
    fragColor.xyz = clamp(fragColor.xyz,0.,1.);
    fragColor.xyz *= 0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.1 );
}
