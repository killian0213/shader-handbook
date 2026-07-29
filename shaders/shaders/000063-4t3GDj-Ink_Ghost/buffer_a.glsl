// Buf A (buffer) — Ink Ghost by zguerrero
// https://www.shadertoy.com/view/4t3GDj


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec4 cam = texture(iChannel1, uv);
    float keying = smoothstep(0.0,1.0,distance(cam.xyz, vec3(13.0/255.0,163.0/255.0,37.0/255.0))*1.0);
    
    fragColor = vec4(clamp(cam.xyz + vec3(0.8), vec3(0.0), vec3(1.0))*keying, keying);
}