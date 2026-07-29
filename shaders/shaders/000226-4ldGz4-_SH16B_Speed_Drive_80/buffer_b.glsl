// Buf B (buffer) — [SH16B] Speed Drive 80 by knarkowicz
// https://www.shadertoy.com/view/4ldGz4

// Post processing

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
 	vec2 screenUV = fragCoord.xy / iResolution.xy;
    
    // radial blur
    vec4 mainSample = texture( iChannel0, screenUV );    
    vec2 blurOffset = ( screenUV - vec2( 0.5 ) ) * 0.002 * mainSample.w;
    vec3 color = mainSample.xyz;
	for ( int iSample = 1; iSample < 16; ++iSample )
	{
		color += texture( iChannel0, screenUV - blurOffset * float( iSample ) ).xyz;
	}    
    color /= 16.0;
    
    // vignette
    float vignette = screenUV.x * screenUV.y * ( 1.0 - screenUV.x ) * ( 1.0 - screenUV.y );
    vignette = clamp( pow( 16.0 * vignette, 0.3 ), 0.0, 1.0 );
    color *= vignette;
    
    float scanline   = clamp( 0.95 + 0.05 * cos( 3.14 * ( screenUV.y + 0.008 * iTime ) * 240.0 * 1.0 ), 0.0, 1.0 );
    float grille  	= 0.85 + 0.15 * clamp( 1.5 * cos( 3.14 * screenUV.x * 640.0 * 1.0 ), 0.0, 1.0 );
    color *= scanline * grille * 1.2;    
        
    fragColor = vec4( color, 1.0 );
}

