// Image (image) — Lorenz Attractor Scope by Flyguy
// https://www.shadertoy.com/view/XddGWj

#define COLOR_BACK vec3(0.10, 0.10, 0.10)
#define COLOR_TRACE vec3(0.10, 1.10, 0.50)

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    float b = texture(iChannel0, uv).x;
    
	fragColor = vec4(mix(COLOR_BACK, COLOR_TRACE, b), 1.0);
}