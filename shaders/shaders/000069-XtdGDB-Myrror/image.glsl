// Image (image) — Myrror by nimitz
// https://www.shadertoy.com/view/XtdGDB

// Myrror by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/XtdGDB
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

/*
	Fractal geometry with cheap to render terrain and a sky
	based on a failed experiment.
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	fragColor = vec4(texture(iChannel0, fragCoord.xy/iResolution.xy).rgb, 1.0);
}