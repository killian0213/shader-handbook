// Image (image) — Romanesco Broccoli by Klems
// https://www.shadertoy.com/view/XlcfRs

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
    
    // number of samples is stored in the alpha channel
    fragColor.rgb /= max(1.0, fragColor.a);
    // exposition
    fragColor.rgb *= 0.05;
    // clamp
    fragColor.rgb = min(fragColor.rgb, vec3(1));
    // gamma correction
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0/2.2));
	// vigneting
    vec2 p = uv * 2.0 - 1.0;
    fragColor.rgb = mix(fragColor.rgb, vec3(0), dot(p, p)*0.2);
    
    fragColor.a = 1.0;
}