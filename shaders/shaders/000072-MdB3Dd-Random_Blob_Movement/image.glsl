// Image (image) — Random Blob Movement by Raxvan
// https://www.shadertoy.com/view/MdB3Dd

#define BLOB_COUNT 32

//utils:
const float PI = 3.141592653589793238;

vec2 getUV(vec2 fragCoord) //(-x,0)->(1.0 + x,1.0); x < 1
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	uv.y = 1.0 - uv.y;
	float ratio = iResolution.x / iResolution.y;
	uv.x *= ratio;
	uv.x -= (ratio - 1.0) * 0.5;
	return uv;
}

//textures:
vec3 tx0(vec2 uv)
{
	return texture(iChannel0,uv).rgb;
}
vec3 tx0(float u)
{
	return texture(iChannel0,vec2(u,0.0)).rgb;
}

//geometry:
float sph(vec2 pos, vec2 xy, float radius)
{
	return 1.0 / (length(xy - pos) / radius);
}

//math:
float sum(vec3 c)
{
	return (c.x + c.y + c.z);
}
float rand(float v)// 0 .. 1
{
	return sum(tx0(v)) * 0.6666666666;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = getUV(fragCoord) - vec2(0.1,0.0);
	
	const int count = BLOB_COUNT;
	const float fcount = float(count);
    vec3 g_final_color = vec3(0.0);
    
	for( int i = 0; i < count; i++ )
	{
		float ind = float(i);
		//timing
		float t = (iTime + 100.0) * ind  * 0.42156 / fcount ;
		float ts = fract(t);
		float tz = t - ts;
		
		//angle
		float angle;
		angle = rand(tz * 0.67889 + ind + uv.y) * PI * 2.0;
		angle += rand(tz * 0.123456 - ind + uv.x) * PI * 2.0;
		angle += (rand(ind * 0.1664) * 2.0 - 1.0) * (ts + ind) * PI * 0.5;
			
		//distance and diretion vector
		vec2 dir = vec2(cos(angle),sin(angle));
		float distance = cos(ts * PI) * 0.5 + 0.5;
		
		vec3 color = vec3(rand(ind * 0.1553),rand(ind * 0.6631),rand(ind * 0.91223)) * 1.25;
		float c0 = sph(vec2(rand(ind * 0.1234),rand(ind * 0.6543)) * 0.5 + dir * distance ,uv,mix(0.0,distance * 0.5,ts));
		
		g_final_color += (c0 * color);
        
	}
	
	fragColor = vec4(4.0 * g_final_color / fcount,1.0);
}