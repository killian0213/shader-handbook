// Image (image) — [SH18] The Eye by knarkowicz
// https://www.shadertoy.com/view/MsKBDG

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
 	vec2 UV = fragCoord.xy / iResolution.xy;
    
    // Chromatic Abberation
    vec2 CAOffset = (UV - 0.5) * 0.005;

    vec3 Color;
    Color.x = texture(iChannel0, UV - CAOffset).x;
    Color.y = texture(iChannel0, UV).y;
    Color.z = texture(iChannel0, UV + CAOffset).z; 
    
    // Vignette
    float Vignette = UV.x * UV.y * (1.0 - UV.x) * (1.0 - UV.y);
    Vignette = clamp(pow(16.0 * Vignette, 0.3), 0.0, 1.0);
    Color *= 0.5 * Vignette + 0.5;
    
    Color = pow(Color, vec3(1.0 / 2.2));
    
    fragColor = vec4(Color, 1.0);
}