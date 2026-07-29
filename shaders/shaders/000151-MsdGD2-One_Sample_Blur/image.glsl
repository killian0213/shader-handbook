// Image (image) — One Sample Blur by iq
// https://www.shadertoy.com/view/MsdGD2

// Created by inigo quilez - iq/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Trick: take one single texture sample at the corner of a given texel, right where it 
// meets three of its neighbors, so that the bilinear filtering hardware averages those
// four texels for you. This basically lets you downsample or box-blur the texture
// without fetching and averaging the four texels by hand.
//
// This shader shows the technique by blurring an image repeatedly with only ONE texture
// sample.
//
// A more advanced use of this for gaussian blurs here: https://www.shadertoy.com/view/Xd33Rf


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	fragColor = texelFetch( iChannel0, ivec2(fragCoord), 0 );
}