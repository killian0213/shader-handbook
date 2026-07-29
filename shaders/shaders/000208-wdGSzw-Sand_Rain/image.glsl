// Image (image) — Sand Rain by Kali
// https://www.shadertoy.com/view/wdGSzw

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv=fragCoord/iResolution.xy;
    vec4 part = texture(iChannel0,uv);
	float c = step(0.1,part.x);
	vec3 col=vec3(1.,.9,.8)*c*(1.-abs(uv.x-.5));
    fragColor = vec4(col,1.);
}