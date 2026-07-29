// Image (image) — 80's raymarching by villedieumorgan
// https://www.shadertoy.com/view/lsVSRt

#define RGBSHIFT true
#define OLDSCREENLINES
#define NUMBER_LINES 269.

/* 
MADE BY MORGAN VILLEDIEU
TW : https://twitter.com/VilledieuMorgan
Click and drag to rotate the camera
*/

vec4 rgbShift( in vec2 p , in vec4 shift) {
    shift *= 1.02*shift.w - 1.0;
    vec2 rs = vec2(shift.x,-shift.y);
    vec2 gs = vec2(shift.y,-shift.z);
    vec2 bs = vec2(shift.z,-shift.x);
    
    float r = texture(iChannel0, p+rs/2., 0.0).x;
    float g = texture(iChannel0, p+gs/2., 0.0).y;
    float b = texture(iChannel0, p+bs/2., 0.0).z;
    
    return vec4(r,g,b,1.0);
}

float rand(vec2 co) { 
    return fract(sin(dot(co.xy ,vec2(12.98,78.23))) * 43758.54);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float numberLines = 269.;
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 oldScreenLines = vec3(sin(uv.y*NUMBER_LINES+sin(iTime)*20.));
    
    #ifdef RGBSHIFT
		vec3 col = mix(rgbShift(uv, vec4(0.015, 0.0, 0.015, 0.0)).xyz, oldScreenLines, 0.01) ;
    #else
    	vec3 col = texture(iChannel0, uv).rgb;
    #endif
    
    col -= .028*rand( uv.xy * iTime);
    fragColor = vec4(col*2.5, 1.);
}