// Image (image) — Quality hashes collection WebGL2 by nimitz
// https://www.shadertoy.com/view/Xt3cDn

//Quality hashes collection
//by nimitz 2018 (twitter: @stormoid)

//The MIT License
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/*
	This is a collection of useful "high-quality" hash functions for WebGL 2 (or anything supporting uints
	and bitwise ops) returning values in the 0..1 range as 32bit floats

	I am using either the a XXhash32 (https://github.com/Cyan4973/xxHash) modified function (for low input
	count). This is a relatively fast and very high quality hash function that can be used as a basis for
	comparison.	My modified version was tested to make sure it still has quality comparable with the
	reference implementation.

	The second option is a modified version of iq's "Integer Hash III" (https://www.shadertoy.com/view/4tXyWN)
	Which I tested using ENT (http://www.fourmilab.ch/random/) and turned out to have serious quality issues.	
	I added the same XORShift finisher as XXHash to improve the characteristics and this turned out	to work
	much better than I hoped, every test I have ran suggest that the quality of the modified version is very
	high. I also implemented 1D and 3D input versions of this hash and tested to make sure the quality
	remained high.

	I did some prelinimary testing and it seems that the bit rotation line(s) of the XXHash implementations can
	be omitted without much consequence in terms of quality (for very low input count as used here).
	This would make the xxhash based method as fast as the other and the quality would likely be higher,
	further testing would be required to confirm.


	For the generation of multiple outputs dimensions (if needed) from the base hash I am using MINSTD
	with the generator parameters from: http://random.mat.sbg.ac.at/results/karl/server/node4.html
	I also tested the hash quality after the MINSTD step and there seems to be little to no loss in quality from
	that final step. One thing I did not test for is the potential correlation between the MINSTD generators,
	but I doubt	this would be an issue, let me know if turns out to be the case.

	I included the 1D and 3D input versions in the common tab as to not clutter this tab too much.


	Please report any issues, statistical or otherwise either here in the comments section
	or on twitter.


	See the bottom of this page for an example of usage with arbitrary float input.
*/

/*
	N.B.
	If speed is the main concern (and hash quality doesn't matter much), I suggest using
 	the faster "Simplest Fastest 2D Hash" by James_Harnett (https://www.shadertoy.com/view/MdcfDj)
	Or the multi-dimensional variants of it from Dave_Hoskins: https://www.shadertoy.com/view/XdGfRR

	I also compared the hashes of this shader with the "2D Weyl hash 32-bit XOR" from MBR 
	(https://www.shadertoy.com/view/4dlcR4)	and even with an added Xorshift finisher, the quality was still
	too low to be a good candidate for low bias	rendering or applications with higher quality requirements. 
	In addition, the performance with the added	finisher would be comparable the the hashes in this collection.
*/

#if 1
//Modified from: iq's "Integer Hash - III" (https://www.shadertoy.com/view/4tXyWN)
//Faster than "full" xxHash and good quality
uint baseHash(uvec2 p)
{
    p = 1103515245U*((p >> 1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    return h32^(h32 >> 16);
}
#else
//XXHash32 based (https://github.com/Cyan4973/xxHash)
//Slower, higher quality
uint baseHash(uvec2 p)
{
    const uint PRIME32_2 = 2246822519U, PRIME32_3 = 3266489917U;
	const uint PRIME32_4 = 668265263U, PRIME32_5 = 374761393U;
    uint h32 = p.y + PRIME32_5 + p.x*PRIME32_3;
    h32 = PRIME32_4*((h32 << 17) | (h32 >> (32 - 17))); //Initial testing suggests this line could be omitted for extra perf
    h32 = PRIME32_2*(h32^(h32 >> 15));
    h32 = PRIME32_3*(h32^(h32 >> 13));
    return h32^(h32 >> 16);
}
#endif

//---------------------2D input---------------------

float hash12(uvec2 x)
{
    uint n = baseHash(x);
    return float(n)*(1.0/float(0xffffffffU));
}

vec2 hash22(uvec2 x)
{
    uint n = baseHash(x);
    uvec2 rz = uvec2(n, n*48271U);
    return vec2((rz.xy >> 1) & uvec2(0x7fffffffU))/float(0x7fffffff);
}

vec3 hash32(uvec2 x)
{
    uint n = baseHash(x);
    uvec3 rz = uvec3(n, n*16807U, n*48271U);
    return vec3((rz >> 1) & uvec3(0x7fffffffU))/float(0x7fffffff);
}

vec4 hash42(uvec2 x)
{
    uint n = baseHash(x);
    uvec4 rz = uvec4(n, n*16807U, n*48271U, n*69621U); //see: http://random.mat.sbg.ac.at/results/karl/server/node4.html
    return vec4((rz >> 1) & uvec4(0x7fffffffU))/float(0x7fffffff);
}

//--------------------------------------------------


//Example taking an arbitrary float value as input
/*
	This is only possible since the hash quality is high enough so that
	raw float input doesn't break the process when the raw bits are used
*/
vec4 hash42(vec2 x)
{
    uint n = baseHash(floatBitsToUint(x));
    uvec4 rz = uvec4(n, n*16807U, n*48271U, n*69621U);
    return vec4((rz >> 1) & uvec4(0x7fffffffU))/float(0x7fffffff);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    vec2 p = fragCoord/iResolution.xy;
    p.x *= iResolution.x/iResolution.y;
    
    //float input
    //fragColor = hash42(p);
    
    //2D input
    fragColor = hash42(uvec2(fragCoord));
    
    //1D input
    //fragColor = hash41(uint(fragCoord.x + fragCoord.y*900.));
    
    //3D input
    //fragColor = hash43(uvec3(fragCoord.xy, uint(fragCoord.y)*0xffffU));
}
