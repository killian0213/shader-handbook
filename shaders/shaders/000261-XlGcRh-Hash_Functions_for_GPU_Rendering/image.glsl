// Image (image) — Hash Functions for GPU Rendering by markjarzynski
// https://www.shadertoy.com/view/XlGcRh

/*************************************************************************************************
 * Mark Jarzynski and Marc Olano, Hash Functions for GPU Rendering, 
 * Journal of Computer Graphics Techniques (JCGT), vol. 9, no. 3, 21-38, 2020
 * Available online http://jcgt.org/published/0009/03/02/
 * 
 * Each block visualized 1 bit of hash from bit 0 in the lower left to bit 31 in the upper right.
 * Some hashes do not generate data in all bits, the bits without data are black.
 * 
 * For each one dimensional hash there are 2 examples, linear and nested, both have 2-dimensional
 * inputs (UV coords) and only a single output. For the three and four dimensional hashes we
 * combine x and y in different ways for z and w, though in 3D space you would ideally use z as 
 * the third input. Constants are sometimes acceptable depending on the hash. For multi-byte
 * hashes only the two dimensional input varation is used an example here. The source code for
 * all of the variations can be found in the Common tab as well as in the full paper.
 * 
 * Comment out the return statements in the hash() function to change the hash.
 * Comment out the #defines for BITPLANE and GRID to visualize the hash itself.
 * Comment out the #define COLOR to see the hash in grayscale (only uses x in multi-dimentionsal hashes)
 * 
 */

#define BITPLANE	// Visualize the bitplanes
//#define ANIMATE		// Animate the bits
#define COLOR	    // Visualize 3D COLOR
#define GRID		// Display a grid to seperate the bitplanes

uvec3 hash(vec2 s)
{	
    /*	Uncomment the hash you want to visualize.

		Note that most of these examples the hash is only given 2 inputs unless the hash requires more.
		But Common includes 1 through 4 input variations of the hash if they exist.

		You should play around with different seeds/different number of inputs.
		
		Available hashes:
	
		bbs, city, esgtsa, fast, hashwithoutsine, hybridtaus, 
		ign, iqint1, iqint2, iqint3, jkiss32, lcg, md5, murmur3,
		pcg, pcg2d, pcg3d, pcg3d16, pcg4d, pseudo, ranlim32,
		superfast, tea2, tea3, tea4, tea5, trig, wang,
		xorshift128, xorshift32, xxhash32
	*/    
    
    uvec4 u = uvec4(s, uint(s.x) ^ uint(s.y), uint(s.x) + uint(s.y)); // Play with different values for 3rd and 4th params. Some hashes are okay with constants, most aren't.
    
    //return uvec3(bbs(seed(u.xy)));
	//return uvec3(bbs(bbs(u.x) + u.y));
    //return uvec3(city(u.xy));
    //return uvec3(esgtsa(seed(u.xy)));
    //return uvec3(esgtsa(esgtsa(u.x) + u.y));
    //return uvec3(fast(s) * float(0xffffffffu));
    //return uvec3(hashwithoutsine32(s) * float(0xffffffffu));
    //return uvec3(hybridtaus(u));
    //return uvec3(ign(s) * float(0xffffffffu));
    //return uvec3(iqint1(seed(u.xy)));
    //return uvec3(iqint1(iqint1(u.x) + u.y));
    //return iqint2(u.xyz);
    //return uvec3(iqint3(u.xy));
    //return uvec3(jkiss32(u.xy));
    //return uvec3(lcg(seed(u.xy)));
    //return uvec3(lcg(lcg(u.x) + u.y));
    //return md5(u).xyz;
    //return uvec3(murmur3(u.xy));
    //return uvec3(pcg(seed(u.xy)));
    //return uvec3(pcg(pcg(u.x) + u.y));
    //return uvec3(pcg2d(u.xy), 0u);
    return pcg3d(u.xyz);
    //return pcg3d16(u.xyz);
    //return pcg4d(u).xyz;
    //return uvec3(pseudo(s) * float(0xffffffffu));
    //return uvec3(ranlim32(seed(u.xy)));
    //return uvec3(ranlim32(ranlim32(u.x) + u.y));
    //return uvec3(superfast(u.xy));
    //return uvec3(tea(2, u.xy), 0u);
    //return uvec3(tea(3, u.xy), 0u);
    //return uvec3(tea(4, u.xy), 0u);
    //return uvec3(tea(5, u.xy), 0u);
    //return uvec3(trig(s) * float(0xffffffffu));
    //return uvec3(wang(seed(u.xy)));
    //return uvec3(wang(wang(u.x) + u.y));
    //return uvec3(xorshift128(u));
    //return uvec3(xorshift32(seed(u.xy)));
    //return uvec3(xorshift32(xorshift32(u.x) + u.y));
    //return uvec3(xxhash32(u.xy)); 
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Thanks to "hash: visualising bitplanes" by hornet https://www.shadertoy.com/view/lt2yDm
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    uint bit = uint(8.0 * uv.x) + 8u * uint(4.0 * uv.y);

#ifdef BITPLANE
    vec2 seed = mod(fragCoord, vec2(iResolution.x/8.0, iResolution.y/4.0));
#else
    vec2 seed = fragCoord;
#endif
    
#ifdef ANIMATE
    seed += 100.0 * iTime;
#endif
    
    uvec3 hash = hash(seed);
    
#ifdef BITPLANE
#ifdef COLOR
    fragColor = vec4((hash >> bit) & 1u, 1.0);
#else
    fragColor = vec4(vec3(float((hash >> bit) & 1u)), 1.0);
#endif
#else
#ifdef COLOR
    fragColor = vec4(vec3(hash) * (1.0/float(0xffffffffu)), 1.0);
#else
    fragColor = vec4(vec3(float(hash) * (1.0/float(0xffffffffu))), 1.0);
#endif
#endif
    
#ifdef GRID
    fragColor *= step( 10.0/iResolution.x, 1.0-abs(2.0*fract(8.0*uv.x)-1.0));
    fragColor *= step( 10.0/iResolution.y, 1.0-abs(2.0*fract(4.0*uv.y)-1.0));
#endif
}