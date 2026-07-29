// Image (image) — peaceful post-apocalyptic by zguerrero
// https://www.shadertoy.com/view/ltSyzd

const float sharpenAmount = 0.3f;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
	
    //Sharpening using mipmap, recommended by FabriceNeyret2
    vec4 t0 = texture(iChannel0, uv, 0.0);
    vec4 t1 = textureLod(iChannel0, uv, 1.0);  
    vec4 sharpened = t0*5.0 + t1*-4.0;
    
    vec2 vignet = smoothstep(vec2(1.5), vec2(0.0), abs(uv-0.5));
    float v = vignet.x*vignet.y;
    
	fragColor = pow(mix(t0, sharpened, sharpenAmount) * v, vec4(1.75));
}