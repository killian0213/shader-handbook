// Image (image) — Radial Blur by iq
// https://www.shadertoy.com/view/4sfGRn

// Created by inigo quilez - iq/2013
//   https://www.youtube.com/c/InigoQuilez
//   https://iquilezles.org/
// I share this piece (art and code) here in Shadertoy and through its Public API, only for educational purposes. 
// You cannot use, sell, share or host this piece or modifications of it as part of your own commercial or non-commercial product, website or project.
// You can share a link to it or an unmodified screenshot of it provided you attribute "by Inigo Quilez, @iquilezles and iquilezles.org". 
// If you are a teacher, lecturer, educator or similar and these conditions are too restrictive for your needs, please contact me and we'll work it out.

vec3 deform( in vec2 p )
{
    float time = 0.5*iTime;
    
    vec2 q = sin( vec2(1.1,1.2)*time + p );

    float a = atan( q.y, q.x );
    float r = sqrt( dot(q,q) );

    vec2 uv = p*sqrt(1.0+r*r);
    uv += sin( vec2(0.0,0.6) + vec2(1.0,1.1)*time);
         
    return texture( iChannel0, uv*0.3).yxx;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = -1.0 + 2.0*fragCoord/iResolution.xy;

    vec3  col = vec3(0.0);
    vec2  d = (vec2(0.0,0.0)-p)/64.0;
    float w = 1.0;
    vec2  s = p;
    for( int i=0; i<64; i++ )
    {
        vec3 res = deform( s );
        col += w*smoothstep( 0.0, 1.0, res );
        w *= .99;
        s += d;
    }
    col = col * 3.5 / 64.0;

	fragColor = vec4( col, 1.0 );
}