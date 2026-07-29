// Buffer A (buffer) — Mountains & Lakes by xjorma
// https://www.shadertoy.com/view/7tSSDD

// compute Terrain and update water level 1st pass


float boxNoise( in vec2 p, in float z )
{
    vec2 fl = floor(p);
    vec2 fr = fract(p);
    fr = smoothstep(0.0, 1.0, fr);    
    float res = mix(mix( hash13(vec3(fl, z)),             hash13(vec3(fl + vec2(1,0), z)),fr.x),
                    mix( hash13(vec3(fl + vec2(0,1), z)), hash13(vec3(fl + vec2(1,1), z)),fr.x),fr.y);
    return res;
}

float Terrain( in vec2 p, in float z, in int octaveNum)
{
	float a = 1.0;
	float f = .0;
	for (int i = 0; i < octaveNum; i++)
	{
		f += a * boxNoise(p, z);
		a *= 0.45;
		p = 2.0 * rot(radians(41.0)) * p;
	}
	return f;
}

vec2 readHeight(ivec2 p)
{
	p = clamp(p, ivec2(0), ivec2(textureSize - 1));
	return texelFetch(iChannel0, p, 0).xy;
} 

vec4 readOutFlow(ivec2 p)
{
	if(p.x < 0 || p.y < 0 || p.x >= textureSize || p.y >= textureSize)
		return vec4(0);
	return texelFetch(iChannel1, p, 0);
} 

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Outside ?
    if( max(fragCoord.x, fragCoord.y) > float(textureSize) )
        discard;
           
    // Terrain
    vec2 uv = fragCoord / float(textureSize);
    float t = iTime / transitionTime;
    float terrainElevation = mix(Terrain(uv * 4.0, floor(t), octaves), Terrain(uv * 4.0, floor(t) + 1.0, octaves), smoothstep(1.0 - transitionPercent, 1.0, fract(t))) * 0.5;
    
    // Water
    float waterDept = initialWaterLevel;
    if(iFrame != 0)
    {
        ivec2 p = ivec2(fragCoord);
        vec2 height = readHeight(p);
        vec4 OutFlow = texelFetch(iChannel1, p, 0);
        float totalOutFlow = OutFlow.x + OutFlow.y + OutFlow.z + OutFlow.w;
        float totalInFlow = 0.0;
        totalInFlow += readOutFlow(p  + ivec2( 1,  0)).z;
        totalInFlow += readOutFlow(p  + ivec2( 0,  1)).w;
        totalInFlow += readOutFlow(p  + ivec2(-1,  0)).x;
        totalInFlow += readOutFlow(p  + ivec2( 0, -1)).y;
        waterDept = height.y - totalOutFlow + totalInFlow;
    }
    fragColor = vec4(terrainElevation, waterDept, 0, 1);
}