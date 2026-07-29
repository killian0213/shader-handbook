// Buf C (buffer) — Frozen Barrens by knarkowicz
// https://www.shadertoy.com/view/XltGRX

// Bloom blur x

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 srcUV = fragCoord.xy / iResolution.xy;
    if ( srcUV.x > 0.25 || srcUV.y > 0.25 )
    {
        discard;
    }

    float sigma 	= 14.0;
    float sigma2Sq  = 2.0 * sigma * sigma;
    float weightScale = 1.0 / sqrt( 3.14 * sigma2Sq );
    vec3 color = vec3( 0.0 );
    float weightSum = 0.0;
    const int kernelSize = 32;
    vec2 off = vec2( 1.0 / iResolution.x, 0.0 );
    for ( int i = -kernelSize; i <= kernelSize; ++i )
    {
        vec2 tapUV = srcUV + off * float( i );
     	float weight = weightScale * exp( -( float( i ) * float( i ) ) / sigma2Sq );
        weight = tapUV.x >= 0.25 ? 0.0 : weight;
        weightSum += weight;
        color += texture( iChannel0, tapUV ).xyz * weight;
    }
    color /= weightSum;
       
    fragColor = vec4( color, 1.0 );
}