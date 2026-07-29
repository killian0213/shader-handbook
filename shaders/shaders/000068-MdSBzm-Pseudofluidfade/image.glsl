// Image (image) — Pseudofluidfade by noby
// https://www.shadertoy.com/view/MdSBzm

//#define POINTS
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord.xy/iResolution.xy;
    fragColor = 1.0-(texture(iChannel0, uv));
    vec4 temp = fragColor;
    fragColor = smoothstep(0.0, 1.1, pow(fragColor, vec4(0.4545)));
    #ifdef POINTS
    fragColor.rgb = mix(fragColor.rgb, vec3(1,0,0), texture(iChannel1, uv).a);
    #endif
}