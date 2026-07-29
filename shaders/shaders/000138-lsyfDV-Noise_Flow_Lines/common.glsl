// Common (common) — Noise Flow Lines by Shane
// https://www.shadertoy.com/view/lsyfDV

// The Shadertoy variable "iTime" isn't recognized in the common tab, so this is a 
// hacky workaround. Take a look at the fBm function.
float gTime;


// Unsigned distance to the segment joining "a" and "b."
float distLine(vec2 a, vec2 b){
    
	b = a - b;
	float h = clamp(dot(a, b) / dot(b, b), 0., 1.);
    return length(a - b*h);
}


vec2 hash22(vec2 p, float repScale) {

    // Repetition.
    p = mod(p, repScale);
    
        // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(113, 1)));
  
    return (fract(vec2(262144, 32768)*n) - .5)*2. - 1.;
}


// Standard 2x2 hash algorithm... I'll replace this with Dave Hoskins's more reliable
// one at some stage.
vec2 hash22G(vec2 p, float repScale) {

    // Repetition.
    p = mod(p, repScale);
    
        // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(113, 1)));
    
    #ifdef STATIC
    return (fract(vec2(262144, 32768)*n) - .5)*2. - 1.; 
    #else
    // Animated.
    p = fract(vec2(262144, 32768)*n); 
    // Note the ".45," insted of ".5" that you'd expect to see. When edging, it can open 
    // up the cells ever so slightly for a more even spread. In fact, lower numbers work 
    // even better, but then the random movement would become too restricted. Zero would 
    // give you square cells.
    return sin( p*6.2831853 + gTime); 
    #endif

}

// Gradient noise: Ken Perlin came up with it, or a version of it. Either way, this is
// based on IQ's implementation. It's a pretty simple process: Break space into squares, 
// attach random 2D vectors to each of the square's four vertices, then smoothly 
// interpolate the space between them.
float gradN2D(in vec2 f, float repScale){
  
   f *= repScale;
    
    // Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
   const vec2 e = vec2(0, 1);
   
    // Set up the cubic grid.
    // Integer value - unique to each cube, and used as an ID to generate random vectors for the
    // cube vertiies. Note that vertices shared among the cubes have the save random vectors attributed
    // to them.
    vec2 p = floor(f);
    f -= p; // Fractional position within the cube.
    

    // Smoothing - for smooth interpolation. Use the last line see the difference.
    //vec2 w = f*f*f*(f*(f*6.-15.)+10.); // Quintic smoothing. Slower and more squarish, but derivatives are smooth too.
    vec2 w = f*f*(3. - 2.*f); // Cubic smoothing. 
    //vec2 w = f*f*f; w = ( 7. + (w - 7. ) * f ) * w; // Super smooth, but less practical.
    //vec2 w = .5 - .5*cos(f*3.14159); // Cosinusoidal smoothing.
    //vec2 w = f; // No smoothing. Gives a blocky appearance.
    
    // Smoothly interpolating between the four verticies of the square. Due to the shared vertices between
    // grid squares, the result is blending of random values throughout the 2D space. By the way, the "dot" 
    // operation makes most sense visually, but isn't the only metric possible.
    float c = mix(mix(dot(hash22G(p + e.xx, repScale), f - e.xx), dot(hash22G(p + e.yx, repScale), f - e.yx), w.x),
                  mix(dot(hash22G(p + e.xy, repScale), f - e.xy), dot(hash22G(p + e.yy, repScale), f - e.yy), w.x), w.y);
    
    // Taking the final result, and converting it to the zero to one range.
    return c*.5 + .5; // Range: [0, 1].
}

// Gradient noise fBm.
float fBm(in vec2 p, float repScale, float time){
    
    gTime = time;
    
    return gradN2D(p, repScale)*.57 + gradN2D(p, repScale*2.)*.28 + gradN2D(p, repScale*4.)*.15;
    
}
