// Sound (sound) — Waterfalls by P_Malin
// https://www.shadertoy.com/view/MdlXD4

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
    return vec2(0.25, 0.4) * FBM(fract(time * 0.25) * 400.0, 0.4)
        + vec2(0.15, 0.025) * FBM((fract(0.435+time * 0.25)) * 450.0, 0.3);
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
