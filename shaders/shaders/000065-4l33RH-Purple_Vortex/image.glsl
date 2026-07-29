// Image (image) — Purple Vortex by FTL
// https://www.shadertoy.com/view/4l33RH


// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Shader inspired by iq's Hell https://www.shadertoy.com/view/MdfGRX
// Noise functions by iq: https://www.shadertoy.com/view/4sfGzS
#define USE_PROCEDURAL 
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
float cloudNoise(in vec3 p, in vec3 dir)
{
	vec3 q = p + dir; 
    float f;
	f  = 0.50000*noise( q ); q = q*2.02 + dir;
    f += 0.25000*noise( q ); q = q*2.03 + dir;
    f += 0.12500*noise( q ); q = q*2.01 + dir;
    f += 0.06250*noise( q ); q = q*2.02 + dir;
    f += 0.03125*noise( q );
    return f;
}


vec3 invertSpace(in vec3 p,float s)
{
   	return s*p/dot(p,p); 
}

//Twist function from  https://iquilezles.org/articles/distfunctions
vec3 twist(in vec3 p,float twistAmount)
{
   	float t = p.y*twistAmount;
    float c = cos(t);
    float s = sin(t);
    mat2  m = mat2(c,-s,s,c);
    p = vec3(m*p.xz,p.y);
    return p.xzy; 
}
    


vec3 raymarch( in vec3 ro, in vec3 rd, in vec2 pixel )
{
	vec4 sum = vec4( 0.0 );
	float t=dither(pixel);

	for( int i=0; i<200; i++ )
	{
		if( sum.a > 0.99 ) break;
		
		vec3 p = ro + t*rd;
		float height = p.y;
		float den = -0.2 - p.y; 

		p = invertSpace(p,6.0);
		p = twist(p,3.0);
  
		float f = cloudNoise(p,-vec3(0.0,0.5,.25)*iTime);
		float d = clamp( den + 4.0*f, 0.0, 1.0 );
        vec4 col=vec4(d);
		col.xyz *= mix( 4.1*vec3(.750,0.15,0.75), vec3(0.32,.2,.52), clamp( height-.5, 0.0, 1.0 ) ); // pink to purple coloring on Y axis
		
		col.a *= 0.6;
		col.rgb *= d;

		sum = sum + col*(1.0 - sum.a);	

		t += 0.025;
	}

	return clamp( sum.xyz, 0.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= iResolution.x/ iResolution.y;
	
    vec2 mo = iMouse.xy / iResolution.xy;
  
	
    // camera
	vec3 ro = 4.0*normalize(vec3(cos(3.0*mo.x), 1.4 - 1.0*(mo.y-.1), sin(3.0*mo.x)));
	vec3 ta = vec3(0.0, 1.0, 0.0);
	
	
	// build ray
    vec3 ww = normalize( ta - ro);
    vec3 uu = normalize(cross( vec3(0.,1.,0.), ww ));
    vec3 vv = normalize(cross(ww,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );
	
    // raymarch	
	vec3 col = raymarch( ro, rd, fragCoord );
	
	// contrast and vignetting	
	col = col*0.5 + 0.5*col*col*(3.0-2.0*col);
	col *= 0.25 + 0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
	
    fragColor = vec4( col, 1.0 );
}
