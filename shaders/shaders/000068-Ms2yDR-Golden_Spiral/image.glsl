// Image (image) — Golden Spiral. by TinyTexel
// https://www.shadertoy.com/view/Ms2yDR

/*
TODO:
- frame rate independence
- linear segments instead of individual spots
- fix esthetics of the center part
*/

#define Time iTime
#define Frame iGlobalFrame
#define PixelCount iResolution.xy

vec3 GammaEncode(vec3 x) {return pow(x, vec3(1.0 / 2.2));}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //vec2 uv = floor(fragCoord.xy);
	vec2 tex = fragCoord.xy / PixelCount;
    
    vec3 col = textureLod(iChannel0, tex, 0.0).rgb;
	//col = col.bgr;    

    float vig = tex.x * tex.y * (1.0 - tex.x) * (1.0 - tex.y) * 16.0;
    vig = sqrt(vig);
    vig = mix(0.6, 1.0, vig);
    col *= vec3(vig);
    
    //col = (1.0 - exp2(-col*col * 5.1));
    //col *= col;
    
    fragColor = vec4(GammaEncode(col), 0.0);
    //fragColor = vec4(col, 0.0);
}