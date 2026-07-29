// Image (image) — Path Tracer Denoise 1SPP by cornusammonis
// https://www.shadertoy.com/view/ldKBRV

/*
	This is a slightly modified version of yuletian's "Path Tracer Denoise" shader.
	This version uses a denoising feedback loop to improve the result of the original
	at 1 sample per pixel, as configured here. This version also randomizes the wavelet 
    kernel stride and rotation to minimize artifacting, and improves on the 
    hash functions somewhat.

	Pros:
	Less noisy result with fewer samples
	Cons:
	Significantly blurrier shadows, reflections, and caustics
	Somewhat more expensive denoising (more reads)
	Introduces some ghosting
*/


// Fork of "Path Tracer Denoise" by yuletian. https://shadertoy.com/view/ldKBzG
// 2018-06-22 00:25:40

#define SHOWSPLITLINE
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0);
    float splitCoord = (iMouse.x == 0.0) ? iResolution.x/2. + iResolution.x*cos(iTime*.55) : iMouse.x;
    #ifdef SHOWSPLITLINE
	if (abs(fragCoord.x - splitCoord) < 1.0) {
		fragColor = vec4(1);
	}
	#endif
    if(fragCoord.x>splitCoord)
    {
        fragColor += texelFetch(iChannel1, ivec2(fragCoord), 0);
        return;
    }
	fragColor += texelFetch(iChannel0, ivec2(fragCoord), 0);
}