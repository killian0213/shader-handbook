// Image (image) — Stop Motion Fox by iq
// https://www.shadertoy.com/view/3dXGWB

// Created by inigo quilez - iq/2019

// Terrain raytracer by Fizzer: https://www.shadertoy.com/view/XlcBRX
// Fox model by pixelmannen: https://opengameart.org/content/fox-and-shiba


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord / iResolution.xy;
    
    // simple dof
    const float focus = 1.5;

    vec4 acc = vec4(0.0);
    const int N = 4;
	for( int j=-N; j<=N; j++ )
    for( int i=-N; i<=N; i++ )
    {
        vec2 off = vec2(float(i),float(j));
        vec4 tmp = texture( iChannel0, q + off/vec2(800.0,450.0) ); 
        float depth = tmp.w;
        vec3  color = tmp.xyz;
        float coc = 0.05 + 6.0*abs(depth-focus)/depth;
        if( dot(off,off) < (coc*coc) )
        {
            float w = 1.0/(coc*coc); 
            acc += vec4(color*w,w);
        }
    }
    
    vec3 col = acc.xyz / acc.w;

    // color greade
    col = pow( col, vec3(0.8,0.95,1.0) ) - vec3(0.05,0.02,0.0);

    // vignette
    col *= 0.7+0.3*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.2);

    // contrast
    col = clamp(col,0.0,1.0);
    col = col*col*(3.0-2.0*col);

    // noise
    float fr = floor(iTime*24.0);
    col *= 0.98+0.04*texture(iChannel1, q*0.5 + 0.6103398*vec2(fr*17.0,fr*131.0)).xyz;

    fragColor = vec4(col,1.0);
}