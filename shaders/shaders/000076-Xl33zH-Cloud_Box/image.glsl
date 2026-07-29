// Image (image) — Cloud Box by FTL
// https://www.shadertoy.com/view/Xl33zH


// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Noise functions by iq: https://www.shadertoy.com/view/4sfGzS
//#define USE_PROCEDURAL 
// Comment out the above line to use a faster LUT for noise and dithering
//===============================================================================================
//===============================================================================================
//===============================================================================================

#ifdef USE_PROCEDURAL
float hash( float n ) { return fract(sin(n)*753.5453123); }
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}

float dither(in vec2 pixel)
{
   return .05*noise( vec3(1000.*pixel.xy/iChannelResolution[0].x,0.) ); 
}
#else
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = texture( iChannel0, (uv+0.5)/256.0, -100.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}
float dither(in vec2 pixel)
{
    return 0.05*texture( iChannel0, pixel.xy/iChannelResolution[0].x ).x;
}
#endif

// Cloud noise by iq: https://www.shadertoy.com/view/XslGRr
// takes a input position + and offset vector and returns a density amount
// derived by summing multiple layers of noise at varying strengths and scales
float cloudNoise(float scale,in vec3 p, in vec3 dir)
{
	vec3 q = p + dir; 
    float f;
	f  = 0.50000*noise( q ); q = q*scale*2.02 + dir;
    f += 0.25000*noise( q ); q = q*2.03 + dir;
    f += 0.12500*noise( q ); q = q*2.01 + dir;
    f += 0.06250*noise( q ); q = q*2.02 + dir;
    f += 0.03125*noise( q );
    return f;
}

// distance functions from  https://iquilezles.org/articles/distfunctions
float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}



float map( vec3 p )
{
	float f = cloudNoise(2.,p,-vec3(0.0,0.25,.125)*iTime);
	float den = sdBox(p,vec3(1.));
//    float den = sdTorus(p,vec2(1.2,.35)); //uncomment to use a torus instead
    den = smoothstep(-0.1,.25,den);
	den = -den-(sin(iTime*.3)+1.)*.3;
	return clamp( den +1.5* f, 0.0, 1.0 );
}

vec3 raymarch( in vec3 ro, in vec3 rd, in vec2 pixel )
{
	vec4 sum = vec4( 0.0 );

	float t=dither(pixel);
	
	for( int i=0; i<100; i++ )
	{
		if( sum.a > 0.99 ) break;
		
		vec3 pos = ro + t*rd;
        float d= map( pos );
		vec4 col = vec4(mix( vec3(1.0,1.0,1.23), vec3(0.1,0.0,0.10), d ),1.);

		col *= d*3.;

		sum +=  col*(1.0 - sum.a);	

		t += 0.05;
	}

	return clamp( sum.xyz, 0.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= iResolution.x/ iResolution.y;
	
    vec2 mo = iMouse.xy / iResolution.xy;
  float rot =3.0*mo.x+iTime*.2;
	
    // camera
	vec3 ro = 4.0*normalize(vec3(cos(rot), .5+(mo.y), sin(rot)));
	vec3 ta = vec3(0.0);
	
	
	// build ray
    vec3 ww = normalize( ta - ro);
    vec3 uu = normalize(cross( vec3(0.,1.,0.), ww ));
    vec3 vv = normalize(cross(ww,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );
	
    // raymarch	
	vec3 col = raymarch( ro, rd, fragCoord );


    fragColor = vec4( col, 1.0 );
}
