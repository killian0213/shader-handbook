// Image (image) — Moon voxels by nimitz
// https://www.shadertoy.com/view/tdlSR8

// Moon voxels
// by nimitz 2019 (twitter: @stormoid)
// https://www.shadertoy.com/view/tdlSR8
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

/*
	Showing off a hybrid sphere-tracing(raymarching)/
	voxel intersection hybrid algorithm with this little diorama.
	
	A few other technically interesting things about this shader:
	
        -A new method for rendering 3D terrain, using summed triangle
        wave octaves with rotation and displacement, will post more on this
        technique soon.
	
        -2D triangle folding for the modelling of the rocket to speed up
        evaluation, this type of space folding (be it 2D or 3D) can be used 
        with any geometry that has any type of symmetry to accelerate evals.

		-A very simple form of AA, displacing the screen each frame by
		a fraction of a pixel to get only the pixels on the edge of the coverage
		limit and blending over a few frames to smooth the result.

	As for the rendering of this scene:

	Materials are defined per-voxel and the colors are quantitized to 16 
	colors per channel to replicate the "pixel art" look but the lighting 
	calculations are done in full color. Also using voxel AO based on fb39ca4's
	technique, which is barely visible in non-fullscreen mode.
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord / iResolution.xy;
    vec3 col = texelFetch( iChannel0, ivec2(fragCoord), 0 ).xyz;
    
    col = 1.12*pow( col, vec3(0.96,0.95,1.0) ) + vec3(-0.04,-0.04, -0.01); //Correction
    
    fragColor = vec4( col, 1.0 );
}