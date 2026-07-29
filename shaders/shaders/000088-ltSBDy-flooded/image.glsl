// Image (image) — flooded by zguerrero
// https://www.shadertoy.com/view/ltSBDy

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    
    vec4 tex = texture(iChannel0, uv, 0.0);
    
    vec4 lf;
    lf.x = texture(iChannel0, ((1.0-uv) - vec2(0.5))*0.4 + vec2(0.5)).w;
    lf.y = texture(iChannel0, ((1.0-uv) - vec2(0.5))*1.0 + vec2(0.5)).w;
    lf.z = texture(iChannel0, ((1.0-uv) - vec2(0.5))*1.75 + vec2(0.5)).w;
    lf.w = texture(iChannel0, ((1.0-uv) - vec2(0.5))*10.0 + vec2(0.5)).w;
    
    lf = smoothstep(vec4(0.0, 0.75, 0.1, 0.0), vec4(0.25, 0.95, 0.4, 0.5), lf);
 	float v = length(uv - 0.5);
    
    vec3 res = mix(tex.xyz, tex.xyz*tex.xyz*tex.xyz, v);
    
    vec3 lff = vec3(lf.x) * vec3(0.8, 0.7, 1.0)*0.125
        		+ vec3(lf.y) * vec3(1.0, 0.5, 0.6)*0.1
     			+ vec3(lf.z) * vec3(0.9, 0.6, 0.8)*0.2
        		+ vec3(lf.w) * vec3(1.0, 0.8, 0.5)*0.1;
    
	fragColor = vec4(res + lff, 1.0);
}