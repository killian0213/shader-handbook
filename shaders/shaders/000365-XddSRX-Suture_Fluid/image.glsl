// Image (image) — Suture Fluid by cornusammonis
// https://www.shadertoy.com/view/XddSRX

// Visualization of the system in Buffer A

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 texel = 1. / iResolution.xy;
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 c = texture(iChannel0, uv).xyz;
    vec3 norm = normalize(c);
    
    vec3 div = vec3(0.1) * norm.z;    
    vec3 rbcol = 0.5 + 0.6 * cross(norm.xyz, vec3(0.5, -0.4, 0.5));
    
    fragColor = vec4(rbcol + div, 0.0);
}