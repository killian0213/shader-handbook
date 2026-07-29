// Buffer A (buffer) — Normal Mapping Shadows (NMS) by BorisVorontsov
// https://www.shadertoy.com/view/7lBBR3

//++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Prepass generates normal map from picture
//++++++++++++++++++++++++++++++++++++++++++++++++++++++
#define invNormalMapScale		5.0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2	uv;
	vec2	offset;
	vec3	normal;
	vec3	height;
	offset = 1.0 / iResolution.xy;
	uv = fract(fragCoord.xy / iResolution.xy);
	height.x = texture(iChannel0, uv).x;
	height.y = texture(iChannel0, uv + vec2(offset.x, 0.0)).x;
	height.z = texture(iChannel0, uv + vec2(0.0, offset.y)).x;
	normal.xy = (height.x - height.yz);
	normal.xy /= offset;
	normal.z = invNormalMapScale;
	normal = normalize(normal);
	normal = normal * 0.5 + 0.5;
	fragColor = vec4(normal, 1.0);
}
