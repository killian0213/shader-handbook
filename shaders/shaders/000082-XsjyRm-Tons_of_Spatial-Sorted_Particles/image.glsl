// Image (image) — Tons of Spatial-Sorted Particles by cornusammonis
// https://www.shadertoy.com/view/XsjyRm

/*

This is a particle rendering method that can render large numbers (hundreds of thousands
to millions) of particles by continually sorting the particle buffer. The spatial sorting
method moves the buffer location of each particle so that, on average, particles reside 
closer to the corresponding UV position where they will be rendered on-screen. In general,
it is not possible to perfectly sort particles to their corresponding UV position, unless 
the spatial density of particles is perfectly uniform. However, it is generally possible 
to get a substantial portion of the total number of particles close enough to their 
optimal buffer position that they can be rendered by checking a small window of buffer 
positions in the neighborhood of each rendered pixel.

This implementation uses three spatial sorting passes with a 5x5 strided sorting 
window. A final buffer accumulates contributions from nearby particles in a 7x7 window
and averages those contributions over time in order to reduce the appearance of
artifacts.

Advantages of this method:

* The theoretical maximum number of particles on-screen is limited only by 
  buffer resolution.
* Particles are never "destroyed" by occupying the same on-screen location 
  (as in other buffer-based particle methods).
* The number of reads per pixel limits the probability of rendering a nearby 
  particle rather than limiting the total number of rendered particles.

Disadvantages of this method:

* Spatially sorting particles is relatively expensive.
* Each particle may or may not be rendered on any given frame.
* Faster-moving particles are less likely to be rendered. 
* The chosen sorting method may introduce visual artifacts as particles are 
  shifted towards their destination.

*/


#define UV 0
#define DISTANCE 1
#define PARTICLES 2
#define RENDER_MODE PARTICLES

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    #if(RENDER_MODE == UV)
        vec2 pos = texture(iChannel1, uv).xy;
        fragColor = vec4(pos,0.5, 1.0);
    #elif(RENDER_MODE == DISTANCE)
        vec2 pos = texture(iChannel1, uv).xy;
    	float dist = distance(uv, pos);
        fragColor = vec4(dist);
	#else
        vec4 v = texture(iChannel0, uv);
        fragColor = vec4(1.0 - sqrt(12.0*v.z));
	#endif
}