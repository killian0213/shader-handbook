// Buffer B (buffer) — Surfer Boy by iq
// https://www.shadertoy.com/view/ldd3DX

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    vec2 q = fragCoord/iResolution.xy;

    vec4 acc = vec4(0.0);
    const int N = 5;
	for( int j=-N; j<=N; j++ )
    for( int i=-N; i<=N; i++ )
    {
        vec2 off = vec2(float(i),float(j));
        
        vec4 tmp = texture( iChannel0, q + off/vec2(1280.0,720.0) ); 
        if( dot(off,off) < float(N*N) )
        {
            acc += vec4(tmp.xyz,1.0);
        }
    }
    vec3 col = acc.xyz / acc.w;

    fragColor = vec4(col,1.0);
}
