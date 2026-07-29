// Image (image) — Photon's journey by zguerrero
// https://www.shadertoy.com/view/4tK3Wd

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    vec2 uv = fragCoord/iResolution.xy;
	vec4 col = texture(iChannel0, uv);
    
    fragColor = col;
}