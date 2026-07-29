// Image (image) — Spectral Colour Schemes by AlanZucconi
// https://www.shadertoy.com/view/ls2Bz1

// Spectral Colour Schemes
// By Alan Zucconi
// Website: www.alanzucconi.com
// Twitter: @AlanZucconi

// Example of different spectral colour schemes
// to convert visible wavelengths of light (400-700 nm) to RGB colours.

// The function "spectral_zucconi6" provides the best approximation
// without including any branching.
// Its faster version, "spectral_zucconi", is advised for mobile applications.


// Read "Improving the Rainbow" for more information
// http://www.alanzucconi.com/?p=6703



float saturate (float x)
{
    return min(1.0, max(0.0,x));
}
vec3 saturate (vec3 x)
{
    return min(vec3(1.,1.,1.), max(vec3(0.,0.,0.),x));
}

// --- Spectral Zucconi --------------------------------------------
// By Alan Zucconi
// Based on GPU Gems: https://developer.nvidia.com/sites/all/modules/custom/gpugems/books/GPUGems/gpugems_ch08.html
// But with values optimised to match as close as possible the visible spectrum
// Fits this: https://commons.wikimedia.org/wiki/File:Linear_visible_spectrum.svg
// With weighter MSE (RGB weights: 0.3, 0.59, 0.11)
vec3 bump3y (vec3 x, vec3 yoffset)
{
	vec3 y = vec3(1.,1.,1.) - x * x;
	y = saturate(y-yoffset);
	return y;
}
vec3 spectral_zucconi (float w)
{
    // w: [400, 700]
	// x: [0,   1]
	float x = saturate((w - 400.0)/ 300.0);

	const vec3 cs = vec3(3.54541723, 2.86670055, 2.29421995);
	const vec3 xs = vec3(0.69548916, 0.49416934, 0.28269708);
	const vec3 ys = vec3(0.02320775, 0.15936245, 0.53520021);

	return bump3y (	cs * (x - xs), ys);
}

// --- Spectral Zucconi 6 --------------------------------------------

// Based on GPU Gems
// Optimised by Alan Zucconi
vec3 spectral_zucconi6 (float w)
{
	// w: [400, 700]
	// x: [0,   1]
	float x = saturate((w - 400.0)/ 300.0);

	const vec3 c1 = vec3(3.54585104, 2.93225262, 2.41593945);
	const vec3 x1 = vec3(0.69549072, 0.49228336, 0.27699880);
	const vec3 y1 = vec3(0.02312639, 0.15225084, 0.52607955);

	const vec3 c2 = vec3(3.90307140, 3.21182957, 3.96587128);
	const vec3 x2 = vec3(0.11748627, 0.86755042, 0.66077860);
	const vec3 y2 = vec3(0.84897130, 0.88445281, 0.73949448);

	return
		bump3y(c1 * (x - x1), y1) +
		bump3y(c2 * (x - x2), y2) ;
}

// --- MATLAB Jet Colour Scheme ----------------------------------------
vec3 spectral_jet(float w)
{
    // w: [400, 700]
	// x: [0,   1]
	float x = saturate((w - 400.0)/ 300.0);
	vec3 c;

	if (x < 0.25)
		c = vec3(0.0, 4.0 * x, 1.0);
	else if (x < 0.5)
		c = vec3(0.0, 1.0, 1.0 + 4.0 * (0.25 - x));
	else if (x < 0.75)
		c = vec3(4.0 * (x - 0.5), 1.0, 0.0);
	else
		c = vec3(1.0, 1.0 + 4.0 * (0.75 - x), 0.0);

	// Clamp colour components in [0,1]
	return saturate(c);
}

// --- GPU Gems -------------------------------------------------------
// https://developer.nvidia.com/sites/all/modules/custom/gpugems/books/GPUGems/gpugems_ch08.html
vec3 bump3 (vec3 x)
{
	vec3 y = vec3(1.,1.,1.) - x * x;
	y = max(y, vec3(0.,0.,0.));
	return y;
}

vec3 spectral_gems (float w)
{
    // w: [400, 700]
	// x: [0,   1]
	float x = saturate((w - 400.0)/ 300.0);

	return bump3
	(	vec3
		(
			4. * (x - 0.75),	// Red
			4. * (x - 0.5),	// Green
			4. * (x - 0.25)	// Blue
		)
	);
}

// --- Approximate RGB values for Visible Wavelengths ------------------
// by Dan Bruton
// http://www.physics.sfasu.edu/astro/color/spectra.html
// https://stackoverflow.com/questions/3407942/rgb-values-of-visible-spectrum
vec3 spectral_bruton (float w)
{
	vec3 c;

	if (w >= 380. && w < 440.)
		c = vec3
		(
			-(w - 440.) / (440. - 380.),
			0.0,
			1.0
		);
	else if (w >= 440. && w < 490.)
		c = vec3
		(
			0.0,
			(w - 440.) / (490. - 440.),
			1.0
		);
	else if (w >= 490. && w < 510.)
		c = vec3
		(	0.0,
			1.0,
			-(w - 510.) / (510. - 490.)
		);
	else if (w >= 510. && w < 580.)
		c = vec3
		(
			(w - 510.) / (580. - 510.),
			1.0,
			0.0
		);
	else if (w >= 580. && w < 645.)
		c = vec3
		(
			1.0,
			-(w - 645.) / (645. - 580.),
			0.0
		);
	else if (w >= 645. && w <= 780.)
		c = vec3
		(	1.0,
			0.0,
			0.0
		);
	else
		c = vec3
		(	0.0,
			0.0,
			0.0
		);

	return saturate(c);
}

// --- Spektre ---------------------------------------------------------
// http://stackoverflow.com/questions/3407942/rgb-values-of-visible-spectrum
vec3 spectral_spektre (float l)
{
	float r=0.0,g=0.0,b=0.0;
			if ((l>=400.0)&&(l<410.0)) { float t=(l-400.0)/(410.0-400.0); r=    +(0.33*t)-(0.20*t*t); }
	else if ((l>=410.0)&&(l<475.0)) { float t=(l-410.0)/(475.0-410.0); r=0.14         -(0.13*t*t); }
	else if ((l>=545.0)&&(l<595.0)) { float t=(l-545.0)/(595.0-545.0); r=    +(1.98*t)-(     t*t); }
	else if ((l>=595.0)&&(l<650.0)) { float t=(l-595.0)/(650.0-595.0); r=0.98+(0.06*t)-(0.40*t*t); }
	else if ((l>=650.0)&&(l<700.0)) { float t=(l-650.0)/(700.0-650.0); r=0.65-(0.84*t)+(0.20*t*t); }
			if ((l>=415.0)&&(l<475.0)) { float t=(l-415.0)/(475.0-415.0); g=             +(0.80*t*t); }
	else if ((l>=475.0)&&(l<590.0)) { float t=(l-475.0)/(590.0-475.0); g=0.8 +(0.76*t)-(0.80*t*t); }
	else if ((l>=585.0)&&(l<639.0)) { float t=(l-585.0)/(639.0-585.0); g=0.82-(0.80*t)           ; }
			if ((l>=400.0)&&(l<475.0)) { float t=(l-400.0)/(475.0-400.0); b=    +(2.20*t)-(1.50*t*t); }
	else if ((l>=475.0)&&(l<560.0)) { float t=(l-475.0)/(560.0-475.0); b=0.7 -(     t)+(0.30*t*t); }

	return vec3(r,g,b);
}


// --- Main Image -----------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    // uv.x: [0,   1]
    // w   : [400, 700]
    float w = uv.x * 300. + 400.;
    
    vec3 c;
    if (uv.y < 1. / 6. * 1.)
        c = spectral_jet(w);
    else if (uv.y < 1. / 6. * 2.)
        c = spectral_bruton(w);
    else if (uv.y < 1. / 6. * 3.)
        c = spectral_gems(w);
    else if (uv.y < 1. / 6. * 4.)
        c = spectral_spektre(w);
    else if (uv.y < 1. / 6. * 5.)
        c = spectral_zucconi(w);
    else
        c = spectral_zucconi6(w);
    
    fragColor = vec4(c, 1.);
}