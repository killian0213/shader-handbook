// Buffer B (buffer) — Elephant by iq
// https://www.shadertoy.com/view/4dKGWm

// Copyright Inigo Quilez, 2016 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work in any form,
// including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it.
// I share this Work for educational purposes, and you can link to it,
// through an URL, proper attribution and unmodified screenshot, as part
// of your educational material. If these conditions are too restrictive
// please contact me and we'll definitely work it out.

// pretty decent DOF with a gather approach

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 di = hash2( fragCoord )-0.5;
    vec2 uv = fragCoord/iResolution.xy;
    
    vec4 ref = texture( iChannel0, uv );
    
    const float focus = 7.0;

    vec4 acc = vec4(0.0);
    for( int j=0; j<11; j++ )
    for( int i=0; i<11; i++ )
    {
        vec2 of = 1.0 * (di+vec2(float(i-5),float(j-5)))/800.0;

        vec4  cold = texture( iChannel0, uv + of );
        float depth = cold.w;
        float coc = max(0.001,0.005*abs(depth-focus)/depth);   // compute scatter radious

        if( dot(of,of) < (coc*coc) )
        {
            float w = 1.0/(coc*coc); 
            acc += vec4(cold.xyz*w,w);
        }
    }
    
    vec3 col = acc.xyz / acc.w;
    
	fragColor = vec4( col, ref.w );
}    
