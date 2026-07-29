// Common (common) — Love and Domination by wyatt
// https://www.shadertoy.com/view/wdjGRc

/*
	This controls how far the "scent" of each cell travels
	Its distributed by a gaussian blur.
	The farther the information spreads, the more blurred it is
	High values result in sleepy simulations and 
	low values result in excited simulations
*/

#define s2 30.
#define BLUR_DEPTH 25.
#define SPEED 2.
#define MOUSE_SIZE 60.