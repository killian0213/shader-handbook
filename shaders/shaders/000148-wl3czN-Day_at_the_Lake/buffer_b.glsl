// Buffer B (buffer) — Day at the Lake by nimitz
// https://www.shadertoy.com/view/wl3czN

// Day at the Lake by nimitz, 2020 (twitter: @stormoid)
// https://www.shadertoy.com/view/wl3czN
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

// Naive Pre-Blur for water reflections

const int vTaps = 3;
const int hTaps = 1;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
	vec2 q = fragCoord.xy / iResolution.xy;
    vec4 col = vec4(0);
    
    for(int j = -hTaps; j <= hTaps; j++)
    for(int i = -vTaps; i <= vTaps; i++)
    {
        vec2 tap = vec2(j,i);
        tap *= vec2(2./iResolution.x, 4./iResolution.y);
        col += texture(iChannel0, q+tap);
    }
    
    float totTaps = (float(vTaps)*2.0 + 1.0) * (float(hTaps)*2.0 + 1.0);
    col /= totTaps;
    
	fragColor = clamp(col, 0., 1.);
}