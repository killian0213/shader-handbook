// Sound (sound) — Red Cells by P_Malin
// https://www.shadertoy.com/view/MsXXWH

float Hash(float p)
{
	vec2 p2 = fract(vec2(p * 5.3983, p * 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}

float SmoothNoise( float t )
{
	float noiset = t * 32.0;
	float tfloor = floor(noiset);
	float ffract = fract(noiset);
	
	float n0 = Hash(tfloor);
	float n1 = Hash(tfloor + 1.0);
	float blend = ffract*ffract*(3.0 - 2.0*ffract);
	return mix(n0, n1, blend) * 2.0 - 1.0;
}

float FBM( float t, float persistence )
{
    float result = 0.0;
    
    float a = 1.0;
    float tot = 0.0;
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence;
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence; 
    result += SmoothNoise(t) * a; tot += a; 
    tot += a; 
    return result / tot;
}

vec2 mainSound( in int samp,float time)
{
	float s1 = sin(time * 2.0);
	float s2 = sin(time * 2.0 + 0.3);
	float p1 = 1.0 - s1 * s1;
	float p2 = 1.0 - s2 * s2;
    float fPulse = (p1 * 0.3 + p2 * 0.7);
    
    
    return vec2(0.15) * FBM(time * 0.25 * 48.0, 0.5 + fPulse * 0.2 )
        + vec2(0.85) * FBM(time * 0.25 * 32.0, 0.2 ) * fPulse;
}


//#define IMAGE_SHADER

#ifdef IMAGE_SHADER

float Function( float x )
{
	return mainSound( in int samp, iTime + x / (44100.0 / 60.0) ).x * 0.5 + 0.5;
}

float Plot( vec2 uv )
{
	float y = Function(uv.x);
	
	return abs(y - uv.y) * iResolution.y;	
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	
	vec2 uv = fragCoord.xy / iResolution.xy;
	
	vec3 vResult = vec3(0.0);
	
	vResult += Plot(uv);
	
	fragColor = vec4((vResult),1.0);
}
#endif
