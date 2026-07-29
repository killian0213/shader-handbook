// Image (image) — Beautypi by iq
// https://www.shadertoy.com/view/lsfGRr

// Created by beautypi in 2012

// Tutorial: https://www.youtube.com/watch?v=emjuqqyq_qc

const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec2 x )
{
    vec2 i = floor(x);
    vec2 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = i.x + i.y*57.0;

    return mix(mix( hash(n+ 0.0), hash(n+ 1.0),f.x),
               mix( hash(n+57.0), hash(n+58.0),f.x),f.y);
}

float fbm( vec2 p )
{
    float f = 0.0;
    f += 0.50000*noise( p ); p = m*p*2.02;
    f += 0.25000*noise( p ); p = m*p*2.03;
    f += 0.12500*noise( p ); p = m*p*2.01;
    f += 0.06250*noise( p ); p = m*p*2.04;
    f += 0.03125*noise( p );
    return f/0.984375;
}

float length2( vec2 p )
{
    vec2 q = p*p*p*p;
    return pow( q.x + q.y, 1.0/4.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    // polar coordinates
    float r = length( p );
    float a = atan( p.y, p.x );

    // animate
    r *= 1.0 + 0.2*clamp(1.0-r,0.0,1.0)*sin(4.0*iTime);

    // iris (blue-green)
    vec3 col = vec3( 0.0, 0.3, 0.4 );
    float f = fbm( 5.0*p );
    col = mix( col, vec3(0.2,0.5,0.4), f );
    
    // yellow towards center
    col = mix( col, vec3(0.9,0.6,0.2), 1.0-smoothstep(0.2,0.6,r) );

    // darkening
    f = smoothstep( 0.4, 0.9, fbm( vec2(15.0*a,10.0*r) ) );
    col *= 1.0-0.5*f;

    // distort
    a += 0.05*fbm( 20.0*p );

    // cornea
    f = smoothstep( 0.3, 1.0, fbm( vec2(20.0*a,6.0*r) ) );
    col = mix( col, vec3(1.0,1.0,1.0), f );

    // edges
    col *= 1.0-0.25*smoothstep( 0.6,0.8,r );

    // highlight
    f = 1.0-smoothstep( 0.0, 0.6, length2( mat2(0.6,0.8,-0.8,0.6)*(p-vec2(0.3,0.5) )*vec2(1.0,2.0)) );
    col += vec3(1.0,0.9,0.9)*f*0.985;
    
    // shadow
    col *= vec3(0.8+0.2*cos(r*a));

    // pupil
    f = 1.0-smoothstep( 0.2, 0.25, r );
    col = mix( col, vec3(0.0), f );

    // crop
    f = smoothstep( 0.79, 0.82, r );
    col = mix( col, vec3(1.0), f );

    // vignetting
    vec2 q = fragCoord/iResolution.xy;
    col *= 0.5 + 0.5*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.1);
 
	fragColor = vec4( col, 1.0 );
}