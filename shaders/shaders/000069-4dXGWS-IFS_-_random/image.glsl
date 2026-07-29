// Image (image) — IFS - random by iq
// https://www.shadertoy.com/view/4dXGWS

// Created by inigo quilez - iq/2013
// I share this piece (art and code) here in Shadertoy and through its Public API, only for educational purposes. 
// You cannot use, sell, share or host this piece or modifications of it as part of your own commercial or non-commercial product, website or project.
// You can share a link to it or an unmodified screenshot of it provided you attribute "by Inigo Quilez, @iquilezles and iquilezles.org". 
// If you are a teacher, lecturer, educator or similar and these conditions are too restrictive for your needs, please contact me and we'll work it out.

// Random linear IFS fractal (4 affine transforms) inverted and
// twisted. Very noisy due to the low iteration count (rendering
// approach is brute force gathering).
//
// Some more information:
// https://iquilezles.org/articles/ifsfractals/ifsfractals.htm
//
// Because WebGL cannot scatter data to a buffer, a gather approach
// is used to colorize the pixels, which is millions of times slower
// than it should. Because of that only a very few iterations are
// performed, and the image is very noisy. So I used a temporal
// accumulation trick to smooth the image out,but that introduces
// blurring. You cannot have it all, not until we have scatter
// operations in WebGL, that is.


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float r = texelFetch( iChannel0, ivec2(fragCoord), 0 ).w;
    
    float lod = pow(1.0-r,4.0)*5.0;
    
    vec3 col = textureLod( iChannel0, fragCoord/iResolution.xy, lod ).xyz;
    
    col *= 4.0/(1.0+4.0*col);
    
    fragColor = vec4(col,1.0);
}