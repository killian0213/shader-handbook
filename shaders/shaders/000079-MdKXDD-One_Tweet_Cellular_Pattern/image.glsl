// Image (image) — One Tweet Cellular Pattern by Shane
// https://www.shadertoy.com/view/MdKXDD

/*

	One Tweet Cellular Pattern
	--------------------------

	Emulating a Voronoi pattern in under a tweet... or if I were to 
    oversell it a bit, the world's smallest Voronoi algorithm. :) 
    Thanks to Coyote, it's now resolution independent, plus there's 
    movement. :)

	The pattern is pretty convincing, all things considered. Note 
    that there are no hash calls, no loops, etc. Bypassing hash calls,
    loops, and so forth, minimizes instruction count considerably,
    which makes things extremely fast and efficient, especially when 
    translating to the 3D environment.

	Conceptually speaking, I think this is about as minimal as it 
    gets... Having said that, it wouldn't surprise me if some crazy 
    coder on Shadertoy dreams up a better way. :)

    
    Related Example:
    
	// 3D Practical usage. More than one tweet. :)
	Cellular Lattice - Shane
	https://www.shadertoy.com/view/XsKXRh

*/

// Coyote got it down to 124 chars, and with movement, but I'm wasting 
// some of it on resolution independency for better thumbnails. :)

// Coyote has slimmed it down even further, and managed to initiate "o" 
// in a more reliable way. If it's not quite readable, look at the two 
// versions below.

#define F o = min(o, length(fract(p *= mat2(7, -5, 5, 7)*.1) - .5)/.6)
void mainImage(out vec4 o, vec2 p){    
    
    p = p/iResolution.y*7. + (o = iDate).w;
    
    F; F; F;
}

// The original is below, if the following is too esoteric.

/*
// Wrappable, repeat distance metric.
#define f length(fract(p *= mat2(7, -5, 5, 7)*.1) - .5)

void mainImage(out vec4 o, vec2 p){
    
    // Screen coordinates and movement.
    //p = p/65. + iDate.w; // 124 character version.
    p = p/iResolution.y*7. + iDate.w;
    
    // Very cheap wrappable cellular tiles.
    o = o - o + min(min(f, f), f)/.6;
}
*/



/*
// Wrappable, repeat distance metric. It's faster to perform 
// the dot product and take the square root later, but we're 
// character saving.

#define f(p) length(fract(p/70.) - .5)

void mainImage(out vec4 o, vec2 p){
	 
    // Movement. Just take the "70" out of the "define" above.
    //p = p/70. + iDate.w; 
    
    // Used to rotate cells with slight warping.
    mat2 m = mat2(7, -5, 5, 7)*.1;
    
    // Very cheap wrappable cellular tiles.
    o += min(min(f(p), f(p*m)), f(p*m*m))/.6 - o;
    
}
*/