// Image (image) — Eye of Ezbhan by ozeg
// https://www.shadertoy.com/view/td3Xzr

#define THETA 2.399963229728653 //THETA is the golden angle in radians: 2 * PI * ( 1 - 1 / PHI )
vec2 spiralPosition(float t)
{
    float angle = t * THETA - iTime * .001; 
    float radius = ( t + .5 ) * .5;
    return vec2( radius * cos( angle ) + .5, radius * sin( angle ) + .5 );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = ( fragCoord - .5 * iResolution.xy ) / iResolution.y * 1024.;
    float a = 0.;
    float d = 50.;
    for(int i = 0; i < 256; i++)
    {
        vec2 pointDist = uv - spiralPosition( float(i) ) * 6.66;
        a += atan( pointDist.x, pointDist.y );
        d = min( dot( pointDist, pointDist ), d );
    }
    d = sqrt( d ) * .02;
    d = 1. - pow( 1. - d, 32. );
    a += sin( length( uv ) * .01 + iTime * .5 ) * 2.75;
    vec3 col  = d * (.5 + .5 * sin( a + iTime + vec3( 2.9, 1.7, 0 ) ) );
    //col   = d * smoothstep( .75, 1.0, vec3( .5 + .5 * sin( a + iTime * -1. ) ) );
    fragColor = vec4( col, 1. );
}