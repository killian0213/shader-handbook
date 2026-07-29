// Image (image) — Islamic Art by Klems
// https://www.shadertoy.com/view/ltdXRr


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 col = texture(iChannel0, uv);
    
    // number of samples is stored in alpha channel
    fragColor.rgb = col.rgb / col.a;
    // exposition
    fragColor.rgb *= 0.4;
    // gamma correction
    fragColor.rgb = pow( fragColor.rgb, vec3(1.0/2.2) );
    // color grading
    fragColor.rgb = pow( fragColor.rgb, vec3(0.8,0.85,0.9) );
    // vigneting
    vec2 p = uv * 2.0 - 1.0;
    fragColor.rgb = mix(fragColor.rgb, vec3(0), dot(p, p)*0.2);
    
    fragColor.a = 1.0;
}
