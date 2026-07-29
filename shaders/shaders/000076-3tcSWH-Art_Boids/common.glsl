// Common (common) — Art : Boids by Gijs
// https://www.shadertoy.com/view/3tcSWH

//amount of particles
const int PARTICLES = 50000; 

//
const float SEPERATION = .1;

//
const float ALIGNMENT = .1;

//
const float COHESION = 0.001;

//percentage of maximum allowed speed
const float SPEED = .5;

//hashing noise by IQ
float hash( int k ) {
    uint n = uint(k);
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return uintBitsToFloat( (n>>9U) | 0x3f800000U ) - 1.0;
}


#define key(k,mode) ( texelFetch( iChannel3, ivec2(k,mode), 0 ).x > .5 )
#define keyDown(k) key(k,0)
#define keyHit(k)  key(k,1)
#define keyFlip(k) key(k,2)