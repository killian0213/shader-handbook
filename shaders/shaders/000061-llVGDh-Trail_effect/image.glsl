// Image (image) — Trail effect by Gaktan
// https://www.shadertoy.com/view/llVGDh

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
	fragColor = texture(iChannel0, uv);
}