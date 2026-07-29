// Image (image) — BloOoOoOoOoOom by TinyTexel
// https://www.shadertoy.com/view/Xljcz1

// BloOoOoOoOoOom
// by TinyTexel
// Creative Commons Attribution-ShareAlike 4.0 International Public License

/*
variation of https://www.shadertoy.com/view/XlfyWl
*/

#define Time iTime
#define Frame iGlobalFrame
#define PixelCount iResolution.xy
#define clamp01(x) clamp(x, 0.0, 1.0)

vec3 GammaEncode(vec3 x) {return pow(x, vec3(1.0 / 2.2));}

void mainImage( out vec4 fragColor, in vec2 uv0 )
{
	vec2 tex = uv0.xy / PixelCount;
    
    vec3 col = textureLod(iChannel0, tex, 0.0).rgb;
    
    
    fragColor = vec4(GammaEncode(clamp01(col)), 0.0);
    //fragColor = vec4(col, 0.0);
}