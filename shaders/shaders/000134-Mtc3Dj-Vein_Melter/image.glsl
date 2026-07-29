// Image (image) — Vein Melter by cornusammonis
// https://www.shadertoy.com/view/Mtc3Dj

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord.xy/iResolution.xy;
    float d = length(texture(iChannel0, uv).xy);
    vec3 tx = texture(iChannel1, uv, 1.0).xyz;
    vec3 col = mix(0.25 * (tx + 3.0 * vec3(1,0.85,0.7)), vec3(0.4,0,0.1), 5.0*d);
	fragColor = vec4(col, 1.);
}