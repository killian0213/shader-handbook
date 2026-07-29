// Image (image) — Ink Ghost by zguerrero
// https://www.shadertoy.com/view/4t3GDj

vec4 color1 = vec4(1.0,0.25,0.15,1.0);
vec4 color2 = vec4(0.5,0.1,0.1,1.0);
vec4 color3 = vec4(0.0,0.0,0.0,1.0);
float multiplier = 1.0;
float midPosition = 0.5;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 c = texture(iChannel0, uv);
    uv.x *= iResolution.x/iResolution.y;
    
    vec4 tex = texture(iChannel1, uv);
    
    float l = clamp(((c.x+c.y+c.z)/3.0)*multiplier,0.0,1.0);
    
    vec4 res1 = mix(color1, color2, smoothstep(0.0,midPosition,l));
    vec4 res2 = mix(res1, color3, smoothstep(midPosition,1.0,l));
    
    fragColor = res2*(0.9 + tex*0.1);
}