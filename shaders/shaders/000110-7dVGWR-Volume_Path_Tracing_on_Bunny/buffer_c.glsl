// Buffer C (buffer) — Volume Path Tracing on Bunny by SebH
// https://www.shadertoy.com/view/7dVGWR


// State of the art
//  - https://graphics.pixar.com/
//  - https://cs.dartmouth.edu/wjarosz/publications/no

// This demo relised particularly on:
// Ratio tracking,    see https://cs.dartmouth.edu/wjarosz/publications/novak14residual.html
// Spectral tracking, see https://jannovak.info/publications/SDTracking/index.html
// Both are important for tracing multiple waveleght along a path at the same time when evaluating tranmsittance and scattered radiance.

#define gAmbientLightEnable 1.0
#define gSunLightEnable 1.0

#define gScattering (vec3(1.0, 1.0, 1.0)*200.0)
#define gAbsorption vec3(0.0, 0.0, 0.0)

#define gMaxPathDepth 20


//////////////////////////////////////////////////
// Volume data
//////////////////////////////////////////////////

#define HIGHBOUND (float3(SRC_SIZE_X, SRC_SIZE_Y, SRC_SIZE_Z) / float3(SRC_SIZE_Z))
#define LOWBOUND  (-HIGHBOUND)

// A low res volume version of the Stanford bunny https://en.wikipedia.org/wiki/Stanford_bunny 
#define BUNNY_VOLUME_SIZE 32
const uint packedBunny[1024] = uint[1024](0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,917504u,917504u,917504u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,1966080u,12531712u,16742400u,16742400u,16723968u,16711680u,8323072u,4128768u,2031616u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,6144u,2063360u,16776704u,33553920u,33553920u,33553920u,33553920u,33520640u,16711680u,8323072u,8323072u,2031616u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,268435456u,402653184u,134217728u,201326592u,67108864u,0u,0u,7168u,2031104u,16776960u,33554176u,33554176u,33554304u,33554176u,33554176u,33554176u,33553920u,16744448u,8323072u,4128768u,1572864u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,805306368u,939524096u,402653184u,478150656u,260046848u,260046848u,260046848u,125832192u,130055680u,67108608u,33554304u,33554304u,33554304u,33554304u,33554304u,33554304u,33554304u,33554176u,16776704u,8355840u,4128768u,917504u,0u,0u,0u,0u,0u,0u,0u,0u,0u,805306368u,1056964608u,1056964608u,528482304u,528482304u,260046848u,260046848u,260046848u,130039296u,130154240u,67108739u,67108807u,33554375u,33554375u,33554370u,33554368u,33554368u,33554304u,33554304u,16776960u,8330240u,4128768u,393216u,0u,0u,0u,0u,0u,0u,0u,0u,939524096u,1040187392u,1040187392u,520093696u,251658240u,251658240u,260046848u,125829120u,125829120u,130088704u,63045504u,33554375u,33554375u,33554375u,33554407u,33554407u,33554370u,33554370u,33554374u,33554310u,16776966u,4144642u,917504u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,15360u,130816u,262017u,4194247u,33554383u,67108847u,33554415u,33554407u,33554407u,33554375u,33554375u,33554318u,2031502u,32262u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,31744u,130816u,262019u,2097151u,134217727u,134217727u,67108863u,33554415u,33554407u,33554415u,33554383u,2097102u,982926u,32262u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,31744u,130816u,524263u,117964799u,127926271u,134217727u,67108863u,16777215u,4194303u,4194303u,2097151u,1048574u,65422u,16134u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3u,31751u,130951u,524287u,252182527u,261095423u,261095423u,59768830u,2097150u,1048574u,1048575u,262143u,131070u,65534u,16134u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,7u,31751u,130959u,503840767u,520617982u,529530879u,261095423u,1048575u,1048574u,1048574u,524286u,524287u,131070u,65534u,16134u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3u,1799u,32527u,134348750u,1040449534u,1057488894u,520617982u,51380223u,1048575u,1048575u,524287u,524287u,524287u,131070u,65534u,15886u,6u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,1536u,3968u,8175u,65535u,1006764030u,1040449534u,1057488894u,50855934u,524286u,524286u,524287u,524287u,524286u,262142u,131070u,65534u,32270u,14u,6u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3968u,8160u,8191u,805371903u,2080505854u,2114191358u,101187582u,34078718u,524286u,524286u,524286u,524286u,524286u,524286u,262142u,131070u,32766u,8078u,3590u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8128u,8176u,16383u,2013331455u,2080505854u,235143166u,101187582u,524286u,1048574u,1048574u,1048574u,1048574u,524286u,524286u,262142u,131070u,32766u,16382u,8070u,1024u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8160u,8184u,1879064574u,2013331455u,470024190u,67371006u,524286u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,524286u,262142u,65534u,16382u,8160u,1024u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8128u,8184u,805322750u,402718719u,134479870u,524286u,524286u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,262142u,65534u,16382u,16368u,1792u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3968u,8184u,16382u,131071u,262142u,524286u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,262142u,65534u,16382u,16368u,1792u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,1792u,8184u,16380u,65535u,262143u,524286u,524286u,1048574u,1048574u,1048575u,1048574u,1048574u,1048574u,1048574u,524286u,262142u,65534u,16376u,16368u,1792u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8176u,16376u,32767u,262143u,524286u,1048574u,1048574u,1048575u,1048575u,1048575u,1048575u,1048574u,1048574u,524286u,262142u,32766u,16376u,8176u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,4032u,8184u,32766u,262142u,524286u,524286u,1048575u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,262142u,32766u,16376u,8176u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,384u,8184u,32766u,131070u,262142u,524286u,1048575u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,524286u,131070u,32766u,16368u,1920u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,4080u,32764u,65534u,262142u,524286u,524286u,524286u,1048574u,1048574u,524286u,524286u,524286u,262142u,131070u,32764u,8160u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,256u,16376u,32760u,131068u,262140u,262142u,524286u,524286u,524286u,524286u,524286u,262142u,131070u,65532u,16368u,3840u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3968u,32752u,65528u,131068u,262142u,262142u,262142u,262142u,262142u,262142u,262140u,131064u,32752u,7936u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8064u,32736u,65528u,131070u,131070u,131070u,131070u,131070u,131070u,65532u,32752u,8160u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3456u,16376u,32764u,65534u,65534u,65534u,32766u,32764u,16380u,4048u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,48u,2680u,8188u,8188u,8188u,8188u,4092u,120u,16u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,120u,248u,508u,508u,508u,248u,240u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,96u,240u,504u,504u,504u,240u,96u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,224u,224u,224u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u);

float SampleVolume(float3 P)
{
    // Normalize uvs to 0-1
    float3 uvs = (P - LOWBOUND) / (HIGHBOUND - LOWBOUND);
    
    float3 voxelUvs = max(float3(0.0),min(uvs*float3(BUNNY_VOLUME_SIZE), float3(BUNNY_VOLUME_SIZE)-1.0));
    uint3 intCoord = uint3(voxelUvs);
    uint arrayCoord = intCoord.x + intCoord.z*uint(BUNNY_VOLUME_SIZE);
	
    // Very simple clamp to edge. It would be better to do it for each texture sample
    // before the filtering but that would be more expenssive...
    // Also adding small offset to catch cube intersection floating point error
    if(uvs.x<-0.001 || uvs.y<-0.001 || uvs.z<-0.001 ||
      uvs.x>1.001 || uvs.y>1.001 || uvs.z>1.001)
    	return 0.0;
   
    uint3 intCoord2 = min(intCoord+uint3(1), uint3(BUNNY_VOLUME_SIZE-1));
    
    uint arrayCoord00 = intCoord.x  + intCoord.z *uint(BUNNY_VOLUME_SIZE);
    uint arrayCoord01 = intCoord.x  + intCoord2.z*uint(BUNNY_VOLUME_SIZE);
    uint arrayCoord10 = intCoord2.x + intCoord.z *uint(BUNNY_VOLUME_SIZE);
    uint arrayCoord11 = intCoord2.x + intCoord2.z*uint(BUNNY_VOLUME_SIZE);
    
    uint bunnyDepthData00 = packedBunny[arrayCoord00];
    uint bunnyDepthData01 = packedBunny[arrayCoord01];
    uint bunnyDepthData10 = packedBunny[arrayCoord10];
    uint bunnyDepthData11 = packedBunny[arrayCoord11];
        
    float voxel000 = (bunnyDepthData00 & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
    float voxel001 = (bunnyDepthData01 & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
    float voxel010 = (bunnyDepthData10 & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
    float voxel011 = (bunnyDepthData11 & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
    float voxel100 = (bunnyDepthData00 & (1u<<intCoord2.y)) > 0u ? 1.0 : 0.0;
    float voxel101 = (bunnyDepthData01 & (1u<<intCoord2.y)) > 0u ? 1.0 : 0.0;
    float voxel110 = (bunnyDepthData10 & (1u<<intCoord2.y)) > 0u ? 1.0 : 0.0;
    float voxel111 = (bunnyDepthData11 & (1u<<intCoord2.y)) > 0u ? 1.0 : 0.0;
    
    float3 d = voxelUvs - float3(intCoord);
    
    voxel000 = mix(voxel000,voxel100, d.y);
    voxel001 = mix(voxel001,voxel101, d.y);
    voxel010 = mix(voxel010,voxel110, d.y);
    voxel011 = mix(voxel011,voxel111, d.y);
    
    voxel000 = mix(voxel000,voxel010, d.x);
    voxel001 = mix(voxel001,voxel011, d.x);
    
    float voxel = mix(voxel000,voxel001, d.z);
    
    return voxel;
}



//////////////////////////////////////////////////
// Cube intersection
//////////////////////////////////////////////////

bool slabs(float3 p0, float3 p1, float3 rayOrigin, float3 invRaydir, out float outTMin, out float outTMax) 
{
	float3 t0 = (p0 - rayOrigin) * invRaydir;
	float3 t1 = (p1 - rayOrigin) * invRaydir;
	float3 tmin = min(t0,t1), tmax = max(t0,t1);
	float maxtmin = max(max(tmin.x, tmin.y), tmin.z);
	float mintmax = min(min(tmax.x, tmax.y), tmax.z);
	outTMin = maxtmin;
	outTMax = mintmax;
	return maxtmin <= mintmax;
}



//////////////////////////////////////////////////
// Dual lobe phase function as in https://media.contentapi.ea.com/content/dam/eacom/frostbite/files/s2016-pbs-frostbite-sky-clouds-new.pdf, page 39
//////////////////////////////////////////////////

float hgPhase(float g, float cosTheta)
{
	// Reference implementation (i.e. not schlick approximation). 
	// See http://www.pbr-book.org/3ed-2018/Volume_Scattering/Phase_Functions.html
	float numer = 1.0f - g*g;
	float denom = 1.0f + g*g + 2.0f * g * cosTheta;
	return numer / (4.0f * PI * denom * sqrt(denom) );
}
float dualLobPhase(float g0, float g1, float w, float cosTheta)
{
	return lerp(hgPhase(g0, cosTheta), hgPhase(g1, cosTheta), w);
}

float uniformPhase()
{
	return 1.0f / (4.0f * PI);
}



//////////////////////////////////////////////////
// Some noise
//////////////////////////////////////////////////

float whangHashNoise(uint u, uint v, uint s)
{
    // https://www.reedbeta.com/blog/quick-and-easy-gpu-random-numbers-in-d3d11/
    // https://www.shadertoy.com/view/ldjczd
	uint seed = (u*1664525u + v) + s;
	seed  = (seed ^ 61u) ^(seed >> 16u);
	seed *= 9u;
	seed  = seed ^(seed >> 4u);
	seed *= uint(0x27d4eb2d);
	seed  = seed ^(seed >> 15u);
	float value = float(seed) / (4294967296.0);
	return value;
}

float badNoise(float2 uv)
{
	return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}



////////////////////////////////////////////////////////////
// Ray related tools
////////////////////////////////////////////////////////////

#define RAYDPOS      0.00001f
#define VOL_SAF_DIST 0.00000001f

struct Ray
{
	float3 o;
	float3 d;
};

Ray createRay(in float3 p, in float3 d)
{
	Ray r;
	r.o = p;
	r.d = d;
	return r;
}


////////////////////////////////////////////////////////////
// Path tracing context used by the integrator
////////////////////////////////////////////////////////////

struct PathTracingContext
{
	Ray ray;
	float3 P;
	float3 V;	// not always the view: sometimes it is the opposite of ray.d when one bounce has happened.

	float scatteringMajorant;
	float absorptionMajorant;
	float extinctionMajorant;
	float albedo;			// name ScatteringAlbedo in Pixar's course note

	float3 wavelengthMask;	// This is ok while we deal with only RGB. It will become a problem when doing real wavelength rendering...

	//	This is used to say "ray did not terminated/interact in a volume and we are going out of it without any mateiral interaction". 
	// For instance if a media is used in a glass layer then the Bxdf should be evaluated on output (for reflection, refraction, etc.).
	// This is enough for the simple volume use case we have today.
	// It is only used in the multi scattering light integrator.
	//	In a real path tracer, one would set the Bxdf on the ouput to use as next event.
	bool nullMaterial;

	uint2 screenPixelPos;
	float randomState;
};

float random01(inout PathTracingContext ptc)
{
	// Trying to do the best noise here with simple function.
	// See https://www.shadertoy.com/view/ldjczd.
	// TODO: have a look at the best noise solution for this case
	float rnd = whangHashNoise(uint(ptc.randomState), uint(ptc.screenPixelPos.x), uint(ptc.screenPixelPos.y));

	//ptc.randomState++; return rnd;

#if 1
	ptc.randomState += float(iFrame) + iTime;
#else
	uint animation = uint(gTime*123456.0);
	ptc.randomState += float((animation*12345u)%256u);
#endif

	return rnd;
}





////////////////////////////////////////////////////////////
// Forward declaration of function used at different places
////////////////////////////////////////////////////////////

//float Transmittance( inout PathTracingContext ptc, in float3 P0, in float3 P1);



////////////////////////////////////////////////////////////
// Intersection & tests functions
////////////////////////////////////////////////////////////

bool insideAnyVolume(in Ray ray)
{
#if 0
	float3 p = ray.o;

	float3 halfSize = float3(0.5) / gVolumeSamplingScale;
	if (all(p<(halfSize + VOL_SAF_DIST) && p>(-halfSize - VOL_SAF_DIST)))
	{
		return true;
	}
	return false;
#else
    const float3 LowB  = LOWBOUND - VOL_SAF_DIST;
    const float3 HighB = HIGHBOUND+ VOL_SAF_DIST;
	float3 P = ray.o;
    return P.x>=LowB.x && P.y>=LowB.y && P.z>=LowB.z && P.x<=HighB.x && P.y<=HighB.y && P.z<=HighB.z;
#endif
}

bool intersectVolume(in Ray ray, inout float2 ts)
{
#if 0
	const float3 volumeP0 = -0.5 * 1.0 / gVolumeSamplingScale;
	const float3 volumeP1 = 0.5 * 1.0 / gVolumeSamplingScale;
	return slabs(volumeP0, volumeP1, ray.o, 1.0 / ray.d, ts.x, ts.y);
#else
    float3 D = normalize(ray.d);
    D += 0.0001 * (1.0 - abs(sign(D)));
    return slabs(LOWBOUND, HIGHBOUND, ray.o, 1.0/D, ts.x, ts.y);
#endif
}

// This is to intersect the entire media volume (6 planes only).
// It would be good to get rid of it as it is a special case (assuming a single volume, but ok if it aggregates all volumes otherwise)
bool getNearestIntersectionFullVolume(in Ray ray, inout float3 P)
{
	// No triangles in this scene so only intersect with the volume.
	float2 ts=vec2(0.);
	if (intersectVolume(ray, ts))
	{
		if (ts.x <= 0.0f && ts.y <= 0.0f)
			return false;

		// Now handle single point behind ray origin, otherwise take the minimum. Can be float t = ts.x<0.0 ? ts.y : (ts.y<0.0 ? ts.x : min(ts.x, ts.y));
		float t = ts.x < 0.0 ? ts.y : ts.x; // Optimised since we always have ts.x<=ts.y
		P = ray.o + t * ray.d;
		return true;
	}
	return false;
}



////////////////////////////////////////////////////////////
// Sampling functions
////////////////////////////////////////////////////////////

bool importanceSampleLightning_Warping(inout PathTracingContext ptc, inout float sx, inout float sy);
bool importanceSampleLightning_Texel(inout PathTracingContext ptc, inout float sx, inout float sy);

// Generates a uniform distribution of directions over a sphere.
// Random zetaX and zetaY values must be in [0, 1].
// Top and bottom sphere pole (+-zenith) are along the Y axis.
float3 getUniformSphereSample(float zetaX, float zetaY)
{
	float phi = 2.0f * PI * zetaX;
	float theta = 2.0f * acos(sqrt(1.0f - zetaY));
	float3 dir = float3(sin(theta)*cos(phi), cos(theta), sin(theta)*sin(phi)); 
	return dir;
}

// Generate a sample (using importance sampling) along an infinitely long path with a given constant extinction.
// Zeta is a random number in [0,1]
float infiniteTransmittanceIS(float extinction, float zeta)
{
	return - log(1.0f - zeta) / extinction;
}

struct DistantLightSample
{
	float3 transmittance;
	float3 radiance;
};



////////////////////////////////////////////////////////////
// [Jendersie and d'Eon 2023] Sampling functions
////////////////////////////////////////////////////////////

/*
 * SPDX-FileCopyrightText: Copyright (c) <2023> NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

// [Jendersie and d'Eon 2023]
//   SIGGRAPH 2023 Talks
//   https://doi.org/10.1145/3587421.3595409

// EVAL and SAMPLE for the Draine (and therefore Cornette-Shanks) phase function
//   g = HG shape parameter
//   a = "alpha" shape parameter

// Warning: these functions don't special case isotropic scattering and can numerically fail for certain inputs

// eval:
//   u = dot(prev_dir, next_dir)
float evalDraine(in float u, in float g, in float a)
{
    return ((1.0 - g*g)*(1.0 + a*u*u))/(4.0*(1.0 + (a*(1.0 + 2.0*g*g))/3.) * PI * pow(1.0 + g*g - 2.0*g*u,1.5));
}

// sample: (sample an exact deflection cosine)
//   xi = a uniform random real in [0,1]
float sampleDraineCos(in float xi, in float g, in float a)
{
    float g2 = g * g;
	float g3 = g * g2;
	float g4 = g2 * g2;
	float g6 = g2 * g4;
	float pgp1_2 = (1.0 + g2) * (1.0 + g2);
	float T1 = (-1.0 + g2) * (4.0 * g2 + a * pgp1_2);
	float T1a = -a + a * g4;
	float T1a3 = T1a * T1a * T1a;
	float T2 = -1296.0 * (-1.0 + g2) * (a - a * g2) * (T1a) * (4.0 * g2 + a * pgp1_2);
	float T3 = 3.0 * g2 * (1.0 + g * (-1.0 + 2.0 * xi)) + a * (2.0 + g2 + g3 * (1.0 + 2.0 * g2) * (-1.0 + 2.0 * xi));
	float T4a = 432.0 * T1a3 + T2 + 432.0 * (a - a * g2) * T3 * T3;
	float T4b = -144.0 * a * g2 + 288.0 * a * g4 - 144.0 * a * g6;
	float T4b3 = T4b * T4b * T4b;
	float T4 = T4a + sqrt(-4.0 * T4b3 + T4a * T4a);
	float T4p3 = pow(T4, 1.0 / 3.0);
	float T6 = (2.0 * T1a + (48.0 * pow(2.0, 1.0 / 3.0) *
		(-(a * g2) + 2.0 * a * g4 - a * g6)) / T4p3 + T4p3 / (3.0 * pow(2.0, 1.0 / 3.0))) / (a - a * g2);
	float T5 = 6.0 * (1.0 + g2) + T6;
	return (1.0 + g2 - pow(-0.5 * sqrt(T5) + sqrt(6.0 * (1.0 + g2) - (8.0 * T3) / (a * (-1.0 + g2) * sqrt(T5)) - T6) / 2.0, 2.0)) / (2.0 * g);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Spectral tracking
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////
// Path tracing context used by the integrator
////////////////////////////////////////////////////////////

struct SpectralPathTracingContext
{
	Ray ray;
	float3 P;
	float3 V;	// not always the view direction: sometimes it is the opposite of ray.d when one bounce has happened.

    float4 SunDirPow;

	
	// Extinction majorant accross all wavelength
	float extinctionMajorant;

	float3 pathWeight;

	//	This is used to say "ray did not terminated/interact in a volume and we are going out of it without any mateiral interaction". 
	// For instance if a media is used in a glass layer then the Bxdf should be evaluated on output (for reflection, refraction, etc.).
	// This is enough for the simple volume use case we have today.
	// It is only used in the multi scattering light integrator.
	//	In a real path tracer, one would set the Bxdf on the ouput to use as next event.
	bool nullMaterial;

	uint2 screenPixelPos;
	float randomState;
};



////////////////////////////////////////////////////////////
// Re implemnted function for SpectralPathTracingContext and RGB spectral content
////////////////////////////////////////////////////////////

float random01(inout SpectralPathTracingContext ptc)
{
	// Trying to do the best noise here with simple function.
    // This is ok for the first step but has dimentionality increase further down the path, something smarter should be done to better explore the space. But surprisingly fine for this demo.
	float rnd = whangHashNoise(uint(ptc.randomState), uint(ptc.screenPixelPos.x), uint(ptc.screenPixelPos.y));

	//ptc.randomState++; return rnd;

#if 1
	ptc.randomState += float(iFrame) + iTime;
#else
	uint animation = uint(iTime*123456.0);
	ptc.randomState += float((animation * 12345u) % 256u);
#endif

	return rnd;
}

float3 getAlbedo(float3 scattering, float3 extinction)
{
	return scattering / max(float3(0.001), extinction);
}

// Sample the volume material at ptc.P
struct MediumSample3
{
	float3 scattering;
	float3 absorption;
	float3 extinction;
	float3 albedo;
};
MediumSample3 sampleMedium(in SpectralPathTracingContext ptc)
{
	float3 P = ptc.P;

    float3 noiseRGB= (textureLod(iChannel1, P*30.0/32.0, 0.).rgb-0.5)*4.0f
                   + (textureLod(iChannel1, P*60.0/32.0, 0.).rgb-0.5)*2.0f
                   + (textureLod(iChannel1, P*120.0/32.0, 0.).rgb-0.5)*1.0f;

    float3 Puv = P + 1.0*noiseRGB*0.02f;

    float Density = SampleVolume(Puv);
    
	float3 scatteringCoef = gScattering;
	float3 absorptionCoef = gAbsorption;
	float3 extinctionCoef = scatteringCoef + absorptionCoef;
    
	MediumSample3 s;
	s.scattering = Density * scatteringCoef;
	s.absorption = Density * absorptionCoef;
	s.extinction = Density * extinctionCoef;
	s.albedo = getAlbedo(s.scattering, s.extinction);
	return s;
}

#if 1

// Use uniform phase function

void phaseEvaluateSample(in SpectralPathTracingContext ptc, in float3 direction, in float3 lightL, out float value, out float pdf)
{
	pdf = uniformPhase();
	value = pdf;
}
void phaseGenerateSample(inout SpectralPathTracingContext ptc, out float3 direction, out float value, out float pdf)
{
	// Evaluate a random direction
	direction = getUniformSphereSample(random01(ptc), random01(ptc));
	// From direction, evaluate the phase value and pdf
	phaseEvaluateSample(ptc, direction, direction, value, pdf);
}

#else

// Use [Jendersie and d'Eon 2023]
// TODO select HG or Draine based on weight, update pdf, then lerp evaluation.

#define A 1.0
#define G 0.0

void branchlessONB(in float3 n, out float3 b1, out float3 b2)
{
    // See https://graphics.pixar.com/library/OrthonormalB/paper.pdf
    float signZ = n.z >= 0.0f ? 1.0f : -1.0f; // float sign = copysignf(1.0f, n.z);
    float a = -1.0f / (signZ + n.z);
    float b = n.x * n.y * a;
    b1 = float3(1.0f + signZ * n.x * n.x * a, signZ * b, -signZ * n.x);
    b2 = float3(b, signZ + n.y * n.y * a, -n.y);
}


void phaseEvaluateSample(in SpectralPathTracingContext ptc, in float3 direction, in float3 lightL, out float value, out float pdf)
{
    pdf = evalDraine(dot(direction, lightL), G, A);
    value = pdf;
}
void phaseGenerateSample(inout SpectralPathTracingContext ptc, inout float3 direction, inout float value, inout float pdf)
{
#if 1
    float3 b0 = direction;
    float3 b1 = float3(0.0f, 0.0f, 0.0f);
    float3 b2 = float3(0.0f, 0.0f, 0.0f);
    branchlessONB(b0, b1, b2);
    
    float u = sampleDraineCos(random01(ptc), G, A);
    
	// Evaluate a random direction
	float phi = 2.0f * PI * random01(ptc);  
	float theta = 2.0f * acos(sqrt(1.0f - u));
	float3 dir = float3(sin(theta)*cos(phi), cos(theta), sin(theta)*sin(phi)); 

    
    // Project it out of the local basis
    direction = b0 * dir.y + b1 * dir.x + b2 * dir.z;
#else
	float3 NewDirection = getUniformSphereSample(random01(ptc), random01(ptc));
    float u = dot(direction, NewDirection);
    direction = NewDirection;
#endif
    
	// From direction, evaluate the phase value and pdf
	evalDraine(u, value, pdf);
}

#endif



////////////////////////////////////////////////////////////
// Transmittance estimation based on Residual Ratio Tracking for Estimating Attenuation in Participating Media
// http://drz.disneyresearch.com/~jnovak/publications/RRTracking/index.html
// Converted to RGB from vpt_transintegrator_ratiotracking.hlsl.
////////////////////////////////////////////////////////////

float3 Transmittance(
	inout SpectralPathTracingContext ptc,
	in float3 P0,
	in float3 P1)
{
	float distance = length(P0 - P1);
	float3 dir = float3(P1 - P0) / distance;
    
	float3 transmittance = float3(1.0f);
    
#if 1
    // Ray marching
    float StepCount = 70.0f;// This requires quite some stteps to not look too biased. But even with that, it is faster than unbiased ratio tracking.
    float Step = 1.0f / StepCount;
    float DistancePerStep = distance / StepCount;
    for(float t = Step*0.5; t<1.0; t+=Step)
    {
		float3 P = P0 + t * dir * distance;
		ptc.P = P;
		float3 extinction = sampleMedium(ptc).extinction;
		transmittance *= exp(- extinction * DistancePerStep);
    }
    
#else

	bool terminated = false;
	float t = 0.0f;


	// Implements ratio tracking (non residual).
    // See https://cs.dartmouth.edu/wjarosz/publications/novak14residual.html
	const float globalMaxDensity = 1.0f;
	float globalExtinctionMajorant = globalMaxDensity * ptc.extinctionMajorant;
	do
	{
		float zeta = random01(ptc);
		t = t + infiniteTransmittanceIS(globalExtinctionMajorant, zeta);

		// Update the shading context
		float3 P = P0 + t * dir;
		ptc.P = P;

		if (t > distance)
			break; // Did not terminate in the volume

		float3 extinction = sampleMedium(ptc).extinction;
		transmittance *= float3(1.0f) - max(float3(0.0f), extinction / globalExtinctionMajorant);

		// Russian roulette PBRT style, but not nice really...
		/*float rrThreshold = 0.1f;
		if (transmittance.x < rrThreshold && transmittance.y < rrThreshold && transmittance.z < rrThreshold)
		{
			float3 q = max(float3(0.05f), float3(1.0f) - transmittance);
			if (random01(ptc) < max(q.x, max(q.y, q.z))) return float3(0.0f);
			transmittance /= float3(1.0) - q;
		}*/
	} while (true);
    
#endif

	return transmittance;
}



float3 getSkyRadiance(float4 SunDirPow, float3 Direction)
{
	DistantLightSample result;
	result.transmittance = float3(1.0f);
	result.radiance = float3(0.0f);
	if (gAmbientLightEnable > 0.0)
	{
        float4 SunDirPow = texelFetch(iChannel3, ivec2(PIX_SUNDIRPOW), 0).xyzw;
        result.radiance = getAtmosphereInScattering(Direction, SunDirPow.xyz, SunDirPow.w, result.transmittance);
	}
	return result.radiance;
}
float3 getSkyTransmittance(float4 SunDirPow, float3 Direction)
{
	DistantLightSample result;
	result.transmittance = float3(1.0f);
	result.radiance = float3(0.0f);
	if (gAmbientLightEnable > 0.0)
	{
        float4 SunDirPow = texelFetch(iChannel3, ivec2(PIX_SUNDIRPOW), 0).xyzw;
        result.radiance = getAtmosphereInScattering(Direction, SunDirPow.xyz, SunDirPow.w, result.transmittance);
	}
	return result.transmittance;
}

float3 TransmittanceEstimation(in SpectralPathTracingContext ptc, in float3 direction)
{
	float3 beamTransmittance = float3(1.0f);
	float3 P0 = ptc.P + direction * RAYDPOS;
	float3 P1 = float3(0.);
	if (getNearestIntersectionFullVolume(createRay(P0, direction), P1))
		beamTransmittance = Transmittance(ptc, P0, P1);
	return beamTransmittance;
}



void lightGenerateSample(inout SpectralPathTracingContext ptc, out float3 direction, out float3 value, out float pdf, out float3 beamTransmittance, out bool isDeltaLight)
{
	beamTransmittance = float3(1.0f);
	float sourceCount = gSunLightEnable + gAmbientLightEnable;
	if (sourceCount == 0.0f)
	{
		isDeltaLight = true;
		pdf = 0.0f;
		value = float3(0.0f);
		direction = float3(1.0, 0.0, 0.0);
		return;
	}

	float zeta = random01(ptc);
	if (zeta <= (gAmbientLightEnable / sourceCount))
	{
		// Evaluate a random direction
		direction = getUniformSphereSample(random01(ptc), random01(ptc));

		// Evaluate the value and pdf
		pdf = (gAmbientLightEnable / sourceCount) * 1.0f / (4.0f * PI);
		value = getSkyRadiance(ptc.SunDirPow, direction);

		// Evaluate the transmittance
		beamTransmittance = TransmittanceEstimation(ptc, direction);

		isDeltaLight = false;
	}
	else // if (zeta <= ((gAmbientLightEnable + gSunLightEnable) / sourceCount))
	{
		// Transmittance throught the sky
		float3 sunSkyTransmittance = getSkyTransmittance(ptc.SunDirPow, ptc.SunDirPow.xyz);

		// From direction, evaluate the beamTransmittance, value and pdf
		direction = ptc.SunDirPow.xyz;
		value = ptc.SunDirPow.www * sunSkyTransmittance;
		pdf = gSunLightEnable / sourceCount;

		// Evaluate the transmittance
		beamTransmittance = TransmittanceEstimation(ptc, direction);

		isDeltaLight = true;
	}
}



////////////////////////////////////////////////////////////
// Misc functions
////////////////////////////////////////////////////////////

// From http://jcgt.org/published/0006/01/01/
void CreateOrthonormalBasis(in float3 n, out float3 b1, out float3 b2)
{
	float sign = n.z >= 0.0f ? 1.0f : -1.0f; // copysignf(1.0f, n.z);
	float a = -1.0f / (sign + n.z);
	float b = n.x * n.y * a;
	b1 = float3(1.0f + sign * n.x * n.x * a, sign * b, -sign * n.x);
	b2 = float3(b, sign + n.y * n.y * a, -n.y);
}

float mean(float3 v)
{
	return dot(v, float3(1.0f / 3.0f, 1.0f / 3.0f, 1.0f / 3.0f));
}

// Multiple importance sampling
float mis(int nsample1, float pdf1, int nsample2, float pdf2)
{
#if 1
	return (float(nsample1) * pdf1) / (float(nsample1) * pdf1 + float(nsample2) * pdf2);
#else
	float factor1 = nsample1 * pdf1;
	float factor2 = nsample2 * pdf2;
	return (factor1 * factor2) / (factor1 * factor1 + factor2 * factor2);
#endif
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Volume integrator relying on spectral tracking
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// http://drz.disneyresearch.com/~jnovak/publications/SDTracking/index.html
// https://twitter.com/yiningkarlli
// https://twitter.com/_jannovak


bool Integrate(
	inout SpectralPathTracingContext ptc,
	in Ray wi,
	inout float3 P, // closestHit
	out float3 transmittance,
	out float3 weight,
	inout Ray wo) 
{
    transmittance = float3(0.);
    weight = float3(0.);
	float3 P0 = ptc.P;
	if (!getNearestIntersectionFullVolume(createRay(P0, wi.d), P))
		return false;

	float tMax = length(P - P0);

	bool eventScatter = false;
	bool eventAbsorb = false;

	const float3 oneThird = float3(1.0f / 3.0f, 1.0f / 3.0f, 1.0f / 3.0f);

	float t = 0.0f;
	MediumSample3 medium;
	medium.scattering = float3(0.0f);
	medium.absorption = float3(0.0f);
	medium.extinction = float3(0.0f);
	medium.albedo = float3(0.0f);
	float3 pathVertexWeight = float3(0.0f);
	do 
	{
		if (ptc.extinctionMajorant == 0.0) break; // cannot importance sample, so stop right away


		float zeta = random01(ptc);
		t = t + infiniteTransmittanceIS(ptc.extinctionMajorant, zeta); // unbounded domain proportional with PDF to the transmittance
		if (t > tMax)
			break; // Did not terminate in the volume

		// Update the shading context
		float3 P1 = P0 + t * wi.d;
		ptc.P = P1;

		// Recompute the local extinction after updating the shading context
		medium = sampleMedium(ptc);

        // Implements spectral tracking
        // See https://jannovak.info/publications/SDTracking/index.html

		// Spectral tracking weights
		float3 Un = max(float3(0.0), ptc.extinctionMajorant - medium.absorption - medium.scattering);
		float avgUaW = dot(oneThird, medium.absorption * ptc.pathWeight);
		float avgUsW = dot(oneThird, medium.scattering * ptc.pathWeight);
		float avgUnW = dot(oneThird, Un                * ptc.pathWeight);
		float cInv = 1.0 / (avgUaW + avgUsW + avgUnW);
		float Pa = avgUaW * cInv;
		float Ps = avgUsW * cInv;
		float Pn = avgUnW * cInv;


		float xi = random01(ptc);
		if (xi <= Ps && Ps > 0.0) // Also check that probability>0.0 to avoid false positive test due to float accuracy and resulting Nan
		{
			eventScatter = true;
			pathVertexWeight = medium.scattering / (ptc.extinctionMajorant * Ps);
		}
		else if (xi < (1.0 - Pn) && Pa>0.0)
		{
			eventAbsorb = true;
			pathVertexWeight = medium.absorption / (ptc.extinctionMajorant * Pa);	// TODOSTVPT apply that total path weight on emissive.
		}
		else
		{
			pathVertexWeight = Un / (ptc.extinctionMajorant * Pn);
			ptc.pathWeight *= pathVertexWeight; // always accumulate
		}
		
	} while (!(eventScatter || eventAbsorb));

	//if (eventScatter && all(medium.extinction > 0.0))
	if (eventScatter && medium.extinction.x > 0.0 && medium.extinction.y > 0.0 && medium.extinction.z > 0.0)
	{
		P = ptc.P;

		transmittance = float3(1.0f);
		weight = float3(1.0f);

		ptc.pathWeight *= pathVertexWeight;
	}
	else if (eventAbsorb)
	{
		P = ptc.P;

		transmittance = float3(0.0f);	// will set throughput to 0 and stop processing loop
		weight = float3(0.0f);			// will remove lighting

		ptc.pathWeight *= pathVertexWeight;
	}
	else
	{
		P = P0 + tMax * wi.d; // out of the volume range

		transmittance = float3(1.0f);
		weight = float3(1.0f);

		ptc.nullMaterial = true; // notify out of the volume
		//ptc.pathWeight *= pathVertexWeight;	Not needed as this is already handled in the loop above each time a null event happen
	}

	wo = createRay( P + wi.d*RAYDPOS, wi.d );

	return true;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Lighting integrator relying on spectral tracking
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




#define V_DEBUG_PHASE	 0
#define V_DEBUG_ONLYPATH 0


void mainImage( out float4 fragColor, in float2 fragCoord )
{    
	float2 uv = fragCoord.xy / iResolution.xy;
    float time = iTime;
    
    fragColor = float4(0,0,0,0);
    if(iFrame < 5)
    {
        return;
    }
    
    
	vec2 mouseControl = iMouse.xy / iResolution.xy;
    
    // Load camera state
    float3 camPos  = texelFetch(iChannel3, ivec2(PIX_CAMPOS), 0).xyz;
    float3 up      = texelFetch(iChannel3, ivec2(PIX_CAMUP), 0).xyz;
    float3 left    = texelFetch(iChannel3, ivec2(PIX_CAMLEFT), 0).xyz;
    float3 forward = texelFetch(iChannel3, ivec2(PIX_CAMFORWARD), 0).xyz;
    
    // View diretion in camera space
    float3 viewDir = normalize(float3((fragCoord.xy - iResolution.xy*0.5) / iResolution.y, 1.0));
    viewDir.xy *= 0.7f;
    viewDir = normalize(viewDir);
    float3 worldDir = viewDir.x*left + viewDir.y*up + viewDir.z*forward;
    
	// Global uniform participating media properties
	float3 scatteringCoef = gScattering;
	float3 absorptionCoef = gAbsorption;
	float3 extinctionCoef = scatteringCoef + absorptionCoef;
	float3 albedo         = getAlbedo(scatteringCoef, extinctionCoef);



	//
	// Initialise the tracing context
	//
	SpectralPathTracingContext ptc;
	ptc.nullMaterial = false;

	ptc.P = float3(0.0);		// TODOSTVPT remove ptc.P and float3 P below? but carefullm used by sampleMedium for instance
	ptc.V = float3(0.0);
	ptc.ray = createRay(float3(0.0), float3(0.0));
    
    ptc.SunDirPow = texelFetch(iChannel3, ivec2(PIX_SUNDIRPOW), 0);

	ptc.extinctionMajorant = max(extinctionCoef.r, max(extinctionCoef.g, extinctionCoef.b));
	ptc.pathWeight = float3(1.0f);

	ptc.screenPixelPos = uint2(fragCoord.xy);
	ptc.randomState = (fragCoord.x + fragCoord.y*iResolution.x) + float(uint(uint(iFrame)*123u)%32768u);

	//
	// Trace the scene
	//
	float3 L = float3(0.0f);
	{
		float3 throughput = float3(1.0f);
		Ray ray = createRay(camPos, worldDir); // ray from camera to pixel

		float3 P = camPos;							// Default start point when the camera is inside a volume
		float3 prevDebugPos = P;


		int step = 0;
		bool hasScattered = false;
		while (step < gMaxPathDepth && throughput.x>0.0 && throughput.y>0.0 && throughput.z>0.0)
		{
			// store current context: ray, intersection point P, etc.
			ptc.ray = ray;
			ptc.P = P + ray.d * RAYDPOS;
			ptc.V = -ray.d;

			// Skipping all the solid surface BRDF code in our case...
			float3 sampleDirection = ray.d;

			// Compute next ray from last intersection.
			// From there, next ray is the reference ray for volumetric interactions.
			Ray nextRay = createRay(P + sampleDirection * RAYDPOS, sampleDirection);

			if (insideAnyVolume(nextRay))
			{
				float3 transmittance = float3(0.0);
				float3 weight = float3(0.0);
                
                Ray nextRay_tmp;
                nextRay_tmp.o = nextRay.o;
                nextRay_tmp.d = nextRay.d;
				bool hasCollision = Integrate(ptc, nextRay_tmp, P, transmittance, weight, nextRay);

				if (hasCollision && !ptc.nullMaterial)
				{
					float3 lightL;
					float bsdfL;
					float3 beamTransmittance;
					float lightPdf, bsdfPdf;
					float misWeight;
					float3 sampleDirection;
					bool isDeltaLight;

					// The shading context has already been advanced to the scatter location. 
					// Now compute direct lighting after evaluating the local scattering albedo and extinction.

					// There is not multiple importance sampling here. Either a sun or sky sample is taken during an event. The result matches PBRT perfectly.
                    // TODO implement MIS as in my other non spectral volume path tracer
					lightGenerateSample(ptc, sampleDirection, lightL, lightPdf, beamTransmittance, isDeltaLight);
					phaseEvaluateSample(ptc, sampleDirection, lightL, bsdfL, bsdfPdf);
					float3 Lv = lightL * bsdfL * beamTransmittance / (lightPdf);

					L += weight * throughput * Lv * transmittance * ptc.pathWeight;
					throughput *= transmittance;

					if (insideAnyVolume(nextRay))
					{
						float phaseValue;
						float phasePdf;
						phaseGenerateSample(ptc, nextRay.d, phaseValue, phasePdf);
						hasScattered = true;
						throughput *= phaseValue / phasePdf;
					}
				}
				else if (insideAnyVolume(nextRay))
				{
					//step--;	// to not have internal subdivision affect path depth
					ptc.nullMaterial = false;
				}
				else // out of any volume
				{
					// In this case we are getting out of a volume in case of a nullmaterial. If the ray has not scattered we want to sample distance lighting.
					// Otherwise, if the ray has been scattered or absorbed, we should not sample the distance lighting (it is already correctly sampled on the path vertex)
					// This is tested with hasScattered and is mandatory to succesfully pass the furnace test correctly with multi scattering.
					if (!hasScattered)
					{
						L += getSkyRadiance(ptc.SunDirPow, ray.d) * ptc.pathWeight;
					}
					break;
				}
			}
			else
			{
				// Exit if no more intersections are found (opaque or volume) then accumulate distant lighting. (outside of the medium bounding volume)
				if (!getNearestIntersectionFullVolume(nextRay, P))
				{
					L += getSkyRadiance(ptc.SunDirPow, ray.d) * ptc.pathWeight;
					break;
				}
                
                
			}

			ray = nextRay;
			step++;
		}
    
	}

    
    fragColor = float4(L, 1.0f);
}



