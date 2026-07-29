// Image (image) — Gaussian SmoothLife by cornusammonis
// https://www.shadertoy.com/view/XtVXzV

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec4 col = texture(iChannel0, uv);
    
    fragColor = col.x*vec4(1.0) + col.y*vec4(1,0.5,0,0) + col.z*vec4(0,0.5,1,0);
}