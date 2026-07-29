// Buf B (buffer) — peaceful post-apocalyptic by zguerrero
// https://www.shadertoy.com/view/ltSyzd

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;

    vec4 prev = texture(iChannel1, uv);
    vec4 new = texture(iChannel0, uv);
    
	fragColor = mix(prev, new, 0.2);
}