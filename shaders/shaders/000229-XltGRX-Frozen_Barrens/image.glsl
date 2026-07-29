// Image (image) — Frozen Barrens by knarkowicz
// https://www.shadertoy.com/view/XltGRX

vec3 saturate( vec3 x )
{
    return clamp( x, 0.0, 1.0 );
}

vec3 ACESFilm( vec3 x )
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return saturate( ( x * ( a * x + b ) ) / ( x * ( c * x + d ) + e ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 screenUV 	= fragCoord.xy / iResolution.xy;
    vec2 bloomUV 	= screenUV / 4.0;
  
  	vec3 color	= texture( iChannel0, screenUV ).xyz;
	vec3 bloom	= texture( iChannel1, bloomUV ).xyz;
    color += bloom * 0.15;
    
    // vignette
    float vignette = screenUV.x * screenUV.y * ( 1.0 - screenUV.x ) * ( 1.0 - screenUV.y );
    vignette = clamp( pow( 16.0 * vignette, 0.3 ), 0.0, 1.0 );
    color *= vignette; 
    
    color = pow( color, vec3( 1.3 ) ) * 1.0;
    color = ACESFilm( color );
    
    fragColor = vec4( pow( color, vec3( 1.0 / 2.2 ) ), 1.0 );
}