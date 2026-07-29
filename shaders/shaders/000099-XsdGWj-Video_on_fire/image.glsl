// Image (image) — Video on fire by Andre
// https://www.shadertoy.com/view/XsdGWj

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = max(texture(iChannel0,uv),texture(iChannel1,uv+0.002));
}