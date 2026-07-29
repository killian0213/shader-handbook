// Buffer B (buffer) — subway of the death by zguerrero
// https://www.shadertoy.com/view/llGfzc

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy/iResolution.xy;
    
    vec4 t_old = clamp(texture(iChannel1, uv), vec4(0.0), vec4(1.0));
    vec4 t_new = clamp(texture(iChannel0, uv), vec4(0.0), vec4(1.0));
    
    vec3 prev = t_old.xyz;
	vec3 new = t_new.xyz * t_new.w;

	fragColor = vec4(mix(prev, new, 0.25), 1.0);
}