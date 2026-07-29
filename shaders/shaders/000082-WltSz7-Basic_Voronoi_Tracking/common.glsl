// Common (common) — Basic : Voronoi Tracking by Gijs
// https://www.shadertoy.com/view/WltSz7

// The code is not optimized for speed; it turns out programming with integers can be slow on some GPU's.
// The reason I still use them is readability of the code.


//amount of particles
const int PARTICLES = 1000; 

//percentage of maximum allowed speed
const float SPEED = 1.;

//hashing noise by IQ
float hash( int k ) {
    uint n = uint(k);
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return uintBitsToFloat( (n>>9U) | 0x3f800000U ) - 1.0;
}

