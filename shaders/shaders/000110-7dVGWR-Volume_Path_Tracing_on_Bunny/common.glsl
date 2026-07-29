// Common (common) — Volume Path Tracing on Bunny by SebH
// https://www.shadertoy.com/view/7dVGWR


// GLSL to HLSL

#define float1 float
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define int2   ivec2
#define int3   ivec3
#define int4   ivec4
#define uint2  uvec2
#define uint3  uvec3
#define uint4  uvec4

#define lerp mix
#define frac fract
#define saturate(x) clamp(x, 0.0, 1.0)

#define PI 3.1415926535897932384626433832795f

/*vec3 my_normalize(vec3 v){
    float len = length(v);
    if(len==0.0)return vec3(0.,1.,0.);
    return v/len;
}
#define normalize(a) my_normalize(a)*/

#define pow(a,b) pow(abs(a),b)
#define sqrt(a) sqrt(abs(a))


// Bunny data properties

#define SRC_SIZE_X 32
#define SRC_SIZE_Y 32
#define SRC_SIZE_Z 32




// States stored in BufferB

#define PIX_MOUSEPOS         float2(0.5, 0.5)
#define PIX_RESETACCUM       float2(1.5, 0.5)

#define PIX_CAMPOS           float2(2.5, 0.5)
#define PIX_CAMUP            float2(3.5, 0.5)
#define PIX_CAMLEFT          float2(4.5, 0.5)
#define PIX_CAMFORWARD       float2(5.5, 0.5)

#define PIX_SUNDIRPOW        float2(6.5, 0.5)

#define PIX_CAMYP            float2(7.5, 0.5)


// Keyboard keys

#define KEY_LEFT             37
#define KEY_UP               38
#define KEY_RIGHT            39
#define KEY_DOWN             40


bool FullResetImpl(int iFrame)
{
    return iFrame < 4; 
}
#define FullReset FullResetImpl(iFrame)




////////////////////////////////////////////////////////////
// Sky (single scattering)
////////////////////////////////////////////////////////////

// Translated to HLSL From https://github.com/wwwtyro/glsl-atmosphere/blob/master/index.glsl. Not perfect but does a good job.
// Also modified to return transmittance.

#define iSteps 16
#define jSteps 8

float2 rsi(float3 r0, float3 rd, float sr) 
{
	// ray-sphere intersection that assumes
	// the sphere is centered at the origin.
	// No intersection when result.x > result.y
	float a = dot(rd, rd);
	float b = 2.0 * dot(rd, r0);
	float c = dot(r0, r0) - (sr * sr);
	float d = (b*b) - 4.0*a*c;
	if (d < 0.0) return float2(1e5,-1e5);
	return float2(
		(-b - sqrt(d))/(2.0*a),
		(-b + sqrt(d))/(2.0*a)
	);
}

float3 atmosphere(
	float3 r, float3 r0, float3 pSun, float iSun, float rPlanet, float rAtmos, float3 kRlh, float kMie, float shRlh, float shMie, float g,
	out float3 transmittance
) 
{
#if 0
	transmittance = float3(1.0)
    ; return float3(0.03, 0.07, 0.23);
#endif

	// Normalize the sun and view directions.
	pSun = normalize(pSun);
	r = normalize(r);

	// Calculate the step size of the primary ray.
	float2 p = rsi(r0, r, rAtmos);
	if (p.x > p.y) return float3(0,0,0);
	p.y = min(p.y, rsi(r0, r, rPlanet).x);
	float iStepSize = (p.y - p.x) / float(iSteps);

	// Initialize the primary ray time.
	float iTime = 0.0;

	// Initialize accumulators for Rayleigh and Mie scattering.
	float3 totalRlh = float3(0,0,0);
	float3 totalMie = float3(0,0,0);

	// Initialize optical depth accumulators for the primary ray.
	float iOdRlh = 0.0;
	float iOdMie = 0.0;

	// Calculate the Rayleigh and Mie phases.
	float mu = dot(r, pSun);
	float mumu = mu * mu;
	float gg = g * g;
	float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
	float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(max(0.0, 1.0 + gg - 2.0 * mu * g), 1.5) * (2.0 + gg));

	// Sample the primary ray.
	for (int i = 0; i < iSteps; i++) {

		// Calculate the primary ray sample position.
		float3 iPos = r0 + r * (iTime + iStepSize * 0.5);

		// Calculate the height of the sample.
		float iHeight = length(iPos) - rPlanet;

		// Calculate the optical depth of the Rayleigh and Mie scattering for this step.
		float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
		float odStepMie = exp(-iHeight / shMie) * iStepSize;

		// Accumulate optical depth.
		iOdRlh += odStepRlh;
		iOdMie += odStepMie;

		// Calculate the step size of the secondary ray.
		float jStepSize = rsi(iPos, pSun, rAtmos).y / float(jSteps);

		// Initialize the secondary ray time.
		float jTime = 0.0;

		// Initialize optical depth accumulators for the secondary ray.
		float jOdRlh = 0.0;
		float jOdMie = 0.0;

		// Sample the secondary ray.
		for (int j = 0; j < jSteps; j++) {

			// Calculate the secondary ray sample position.
			float3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

			// Calculate the height of the sample.
			float jHeight = length(jPos) - rPlanet;

			// Accumulate the optical depth.
			jOdRlh += exp(-jHeight / shRlh) * jStepSize;
			jOdMie += exp(-jHeight / shMie) * jStepSize;

			// Increment the secondary ray time.
			jTime += jStepSize;
		}

		// Calculate attenuation.
		float3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

		// Accumulate scattering.
		totalRlh += odStepRlh * attn;
		totalMie += odStepMie * attn;

		// Increment the primary ray time.
		iTime += iStepSize;

	}

	// transmittance within atmosphere
	transmittance = exp(-(kMie*iOdMie + kRlh*iOdRlh));

	// Calculate and return the final color.
	return iSun * (pRlh * kRlh * totalRlh + pMie * kMie * totalMie);
}

float3 getAtmosphereInScattering(
	float3 rayDir, float3 sunDir, float sunIntensity,
	out float3 transmittance1
)
{
    float3 transmittance;
    float3 ret = atmosphere(
		rayDir,								// normalized ray direction
		float3(0,6371e3 + 5e3,0),			// ray origin (in meters)
		sunDir,								// position of the sun
		sunIntensity,						// intensity of the sun
		6371e3,								// radius of the planet in meters
		6471e3,								// radius of the atmosphere in meters
		float3(5.5e-6, 13.0e-6, 22.4e-6),	// Rayleigh scattering coefficient
		21e-6,								// Mie scattering coefficient
		8e3,								// Rayleigh scale height
		1.2e3,								// Mie scale height
		0.758,								// Mie preferred scattering direction

		transmittance
	);
    transmittance1=transmittance;
    return ret;
}



