// Buffer A (buffer) — Isopleth by Ultraviolet
// https://www.shadertoy.com/view/Mllfzl




// Cloud parameters

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float hash(vec3 p)
{
    p  = fract( p*0.3183099+.1 );
	p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

float noiseMulti( in vec3 pos)
{
    vec3 q = pos;
    float f  = 0.5000*noise( q ); q = m*q*2.01;
    f += 0.2500*noise( q ); q = m*q*2.02;
    f += 0.1250*noise( q ); q = m*q*2.03;
    f += 0.0625*noise( q ); q = m*q*2.01;

    float w = 0.5000+0.25+0.125+0.0625;
    return f/w;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy*4.;
    float speed = 0.5;
    fragColor = vec4(noise(vec3(uv, iTime*speed)), 
                     noise(vec3(uv + vec2(100.0), iTime*speed)), 
                     noise(vec3(uv + vec2(200.0), iTime*speed)), 
                     noise(vec3(uv + vec2(300.0), iTime*speed)));
    
    /*
    fragColor = vec4(noiseMulti(vec3(uv, iTime*speed)), 
                     noiseMulti(vec3(uv + vec2(100.0), iTime*speed)), 
                     noiseMulti(vec3(uv + vec2(200.0), iTime*speed)), 
                     noiseMulti(vec3(uv + vec2(300.0), iTime*speed)));
	//*/
}