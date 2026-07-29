// Image (image) — fluidcube by zguerrero
// https://www.shadertoy.com/view/Xlc3R4

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    float v = smoothstep(0.3, 0.8, length(vec2(0.5, 0.5) - uv));
	vec4 baseCol = texture(iChannel0, uv);    
    
    fragColor = mix(baseCol, pow(baseCol, vec4(3.0)), v);
}