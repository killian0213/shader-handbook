// Image (image) — Warping - procedural 5 by iq
// https://www.shadertoy.com/view/3XlfWH

// Copyright Inigo Quilez, 2025 - https://iquilezles.org/
// I am the sole copyright owner of this Work. You cannot
// host, display, distribute or share this Work neither as
// is or altered, in any form including physical and
// digital. You cannot use this Work in any commercial or
// non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it. You
// cannot use this Work to train AI models. I share this
// Work for educational purposes, you can link to it as
// an URL, proper attribution and unmodified screenshot,
// as part of your educational material. If these
// conditions are too restrictive please contact me.

// Tutorial:
//
// https://iquilezles.org/articles/warp
//
// More warping examples:
//
// https://www.shadertoy.com/view/4s23zz
// https://www.shadertoy.com/view/lsl3RH
// https://www.shadertoy.com/view/XsfSD4
// https://www.shadertoy.com/view/MdSXzz
// https://www.shadertoy.com/view/3XlfWH

float hash21( in vec2 p )
{
    // replace this by something better
    p = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return fract( p.x*p.y*(p.x+p.y) );
}

vec2 hash22( in vec2 p )
{
    return vec2(hash21(p.xy+vec2(0.0,0.0)),
                hash21(p.yx+vec2(0.7,0.5)));
}

float noise( in vec2 x )
{
    vec2 i = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float a = hash21(i+vec2(0,0));
	float b = hash21(i+vec2(1,0));
	float c = hash21(i+vec2(0,1));
	float d = hash21(i+vec2(1,1));
    return -1.0+2.0*mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}

float voronoi( in vec2 p )
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d = 10.0; 
	for( int n=-1; n<=1; n++ )
    for( int m=-1; m<=1; m++ )
    {
        vec2 b = vec2(m, n);
        vec2 r = b - f + hash22(i+b);
        d = min(d,dot(r,r));
    }
	return d;
}

float fbmNoise( in vec2 p, in int oct )
{
    const mat2 m = mat2( 0.8, 0.6, -0.6, 0.8 );

    float f = 0.0;
    float s = 0.5;
    float t = 0.0;
    for( int i=0; i<oct; i++ )
    {
        f += s*noise( p );
        t += s;
        p = m*p*2.01;
        s *= 0.5;
    }
    return f/t;
}

float fbmVoronoi( in vec2 p )
{
    float f = 1.0;
    float s = 1.0;
    for( int i=0; i<8; i++ )
    {
        float v = voronoi(p);
        f = min(f,v*s);
        p *= 2.0;
        s *= 1.4;
    }
    return 3.0*f;
}

vec2 fbm2Noise( in vec2 p, in int o )
{
    return vec2(fbmNoise(p.xy+vec2(0.0,0.0),o), 
                fbmNoise(p.yx+vec2(0.7,1.3),o));
}

//====================================================================

// distortion
vec2 dis( in vec2 p, in float t )
{
    // accelerate
    t += 0.3*sin(t);
    
    // scroll
    p.x -= 0.2*t;

    // wirl
    const float a = 0.7;
    p += a*0.5000*sin(p.yx*1.4+0.0+t);
    p += a*0.2500*sin(p.yx*2.3+1.0+t);
    p += a*0.1250*sin(p.yx*4.2+2.0+t);
    p += a*0.0625*sin(p.yx*8.1+3.0+t);
    
    // turbulence
    p += 0.4*fbm2Noise( 0.5*p-t*vec2(0.9,0.18), 2 );

    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    // distortion (and its velocity)
    const float dt = 0.01;
    vec2  q   = dis(p,iTime);
    vec2  pq  = dis(p,iTime-dt);
    float vel = length(q-pq)/dt;

    // wave
    float f = q.y - 0.5*sin(1.57*q.x);    
    
    // circles
    f -= 0.5*vel*vel*(0.5-fbmVoronoi(0.5*q));

    // colorize
    f = 0.5 + 1.5*fbmNoise( vec2(2.5*f,0.0), 10 );
    vec3 col = mix(vec3(0.0,0.25,0.6),vec3(1.0),f);

    // vignetting
    col *= 1.0 - 0.1*dot(p,p);
    
    fragColor = vec4( col, 1.0 );
}
