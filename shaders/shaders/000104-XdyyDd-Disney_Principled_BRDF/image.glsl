// Image (image) — Disney Principled BRDF by markusm
// https://www.shadertoy.com/view/XdyyDd

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = texture(iChannel0, uv);
    fragColor.rgb = pow(fragColor.rgb, vec3(0.4545));
}