// Image (image) — Sea the Night by crocidb
// https://www.shadertoy.com/view/ssG3Wt

//
// Sea the Night
// by Bruno Croci - https://bruno.croci.me/
// 
// Inspired by: https://instagram.com/matialonsor
// Depth of Field code: https://www.shadertoy.com/view/lstBDl
//

#define DISPLAY_GAMMA 1.9

#define GOLDEN_ANGLE 2.39996323
#define MAX_BLUR_SIZE 30.0

#define RAD_SCALE 0.5 // Smaller = nicer blur, larger = faster
#define uFar 12.0
#define FOCUS_SCALE 35.0

float getBlurSize(float depth, float focusPoint, float focusScale)
{
	float coc = clamp((1.0 / focusPoint - 1.0 / depth)*focusScale, -1.0, 1.0);
    return abs(coc) * MAX_BLUR_SIZE;
}

vec3 depthOfField(vec2 texCoord, float focusPoint, float focusScale)
{
    vec4 Input = texture(iChannel0, texCoord).rgba;
    float centerDepth = Input.a * uFar;
    float centerSize = getBlurSize(centerDepth, focusPoint, focusScale);
    vec3 color = Input.rgb;
    float tot = 1.0;
    
    vec2 texelSize = 1.0 / iResolution.xy;

    float radius = RAD_SCALE;
    for (float ang = 0.0; radius < MAX_BLUR_SIZE; ang += GOLDEN_ANGLE)
    {
        vec2 tc = texCoord + vec2(cos(ang), sin(ang)) * texelSize * radius;
        
        vec4 sampleInput = texture(iChannel0, tc).rgba;

        vec3 sampleColor = sampleInput.rgb;
        float sampleDepth = sampleInput.a * uFar;
        float sampleSize = getBlurSize(sampleDepth, focusPoint, focusScale);
        
        if (sampleDepth > centerDepth)
        {
        	sampleSize = clamp(sampleSize, 0.0, centerSize*2.0);
        }

        float m = smoothstep(radius-0.5, radius+0.5, sampleSize);
        color += mix(color/tot, sampleColor, m);
        tot += 1.0;
        radius += RAD_SCALE/radius;
    }
    
    return color /= tot;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec4 color = texture(iChannel0, uv).rgba;
    
    float focusPoint = 58.0 - sin(iTime * 0.3) * 20.0;
    color.rgb = depthOfField(uv, focusPoint, FOCUS_SCALE);

    //tone mapping
    color.rgb = vec3(1.7, 1.8, 1.6) * color.rgb / (1.0 + color.rgb);
    
    //inverse gamma correction
	fragColor = vec4(pow(color.rgb, vec3(1.0 / DISPLAY_GAMMA)), 1.0);
    
    // Debug depth
    //fragColor.rgb = vec3(color.a)*0.015;
}