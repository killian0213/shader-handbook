// Image (image) — ExplosionEffect by kuvkar
// https://www.shadertoy.com/view/4sByWz

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy/iResolution.xy;
    vec4 c1 = texture(iChannel0, uv);
    vec4 c2 = texture(iChannel1, uv);
    fragColor = c1+c2;
    fragColor.rgb *= mix(1.0, rand(uv)+rand(uv*.5), 0.05); 
}