// Image (image) — fractal shake  by macbooktall
// https://www.shadertoy.com/view/llXBRH

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 uuv = uv * 2.0 - 1.0;
    
    vec4 tex = texture(iChannel0, uv);
    vec4 col = min(vec4(.795), pow(tex, vec4(3.75)));
    fragColor = mix(vec4(0.), col, 1.-smoothstep(0.,1.,length(uuv)*0.7));
}