// Image (image) — [SH16B] Speed Drive 80 by knarkowicz
// https://www.shadertoy.com/view/4ldGz4

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
 	vec2 screenUV = fragCoord.xy / iResolution.xy;
    
    // chromatic abberation
    float caStrength	= 0.005;
    vec2 caOffset 		= screenUV - 0.5;
	vec2 caUVG			= screenUV + caOffset * caStrength;
	vec2 caUVB			= screenUV + caOffset * caStrength * 2.0;

    vec3 color;
    color.x = texture( iChannel0, screenUV ).x;
    color.y = texture( iChannel0, caUVG ).y;
    color.z = texture( iChannel0, caUVB ).z;    
    
    fragColor = vec4( color, 1.0 );
}