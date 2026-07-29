// Common (common) — anime water splash FX by morimea
// https://www.shadertoy.com/view/wldcW2


vec2 ToPolar(vec2 v)
{
    return vec2(atan(v.y, v.x), length(v));
}


// using https://www.shadertoy.com/view/ldB3zc

// The MIT License
// Copyright © 2014 Inigo Quilez

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}
vec2 voronoi( in vec2 x, float w , float time)
{
    vec2 n = floor( x );
    vec2 f = fract( x );

	vec2 m = vec2(8.0, 0.0);
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = vec2( float(i),float(j) );
        vec2 o = hash22( n + g );
        o = 0.5 + 0.5*sin( time + 6.2831*o );
		float d = length(g - f + o);	
		float h = smoothstep( 0.0, 1.0, 0.5 + 0.5*(m.x-d)/w );
	    m.x = mix( m.x,     d, h ) - h*(1.0-h)*w/(1.0+3.0*w); // distance
        m.y = mix( m.y, 0.75, h ) - h*(1.0-h)*w/(1.0+3.0*w);
    }
	
	return m;
}


// using https://www.shadertoy.com/view/XdXGW8

// The MIT License
// Copyright © 2013 Inigo Quilez

float noise2( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash22( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash22( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash22( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash22( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}


// using https://www.shadertoy.com/view/4sfGzS

// The MIT License
// Copyright © 2013 Inigo Quilez

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

float noise3( in vec3 x )
{
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    return mix(mix(mix( hash13(i+vec3(0,0,0)), 
                        hash13(i+vec3(1,0,0)),f.x),
                   mix( hash13(i+vec3(0,1,0)), 
                        hash13(i+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash13(i+vec3(0,0,1)), 
                        hash13(i+vec3(1,0,1)),f.x),
                   mix( hash13(i+vec3(0,1,1)), 
                        hash13(i+vec3(1,1,1)),f.x),f.y),f.z);
}

float fbm( vec3 p)    // in [0,1]
{
    p*=0.35;
    vec3 q = 8.0*p;
    float f=0.;
    f  = 0.5000*noise3( q ); q = m*q*2.01;
    f += 0.2500*noise3( q ); q = m*q*2.02;
    f += 0.1250*noise3( q ); q = m*q*2.03;
    f += 0.0625*noise3( q ); q = m*q*2.01;
    return f;
}

