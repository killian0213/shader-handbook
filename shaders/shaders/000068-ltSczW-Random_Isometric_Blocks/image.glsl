// Image (image) — Random Isometric Blocks by Shane
// https://www.shadertoy.com/view/ltSczW

/*

	Random Isometric Blocks
	-----------------------

	I love looking at those geometric grid-based images that the procedural art and
	graphic design crowd like to post on the internet. Many are isometric in nature, 
	so tend to be created by applying simple hexagonal grid trickery - usually 
	flipping some cleverly designed tiles in a random - or calculated - way.

    In order to produce one, all you need to do is convert screen coordinates to a 
	hexagonal grid coordinate with corresponding cell ID, then use your imagination... 
	or if you're like me and you don't have one, just reference one of the countless 
	patterns on the internet. :D

	Anyway, here's a simple example that I'm sure most have seen around. I'll put up a 
	more interesting one that involves interlacing next. Hopefully, some people on
	Shadertoy will post others.

	By the way, if you're not quite familiar with hexagonal grids, I've produced a 
	basic example to accompany this. The link is below.

	// Simpler hexagonal grid example that attempts to explain the grid setup used
	// to produce the pattern here.
	//
	Minimal Hexagonal Grid - Shane
	https://www.shadertoy.com/view/Xljczw

	// You can't do a hexagonal grid example without referencing this. :) Very stylish.
	Hexagons - distance - iq
	https://www.shadertoy.com/view/Xd2GR3

*/

// I think it looks more interesting with the holes in the cubes, but if you're more
// of a purist, comment out the following:
#define CUBE_HOLES

// Leave some cube faces solid - Abje's suggestion. I like it because it breaks things
// up a bit.
#define SOME_SOLID 

// Helper vector. If you're doing anything that involves regular triangles or hexagons, the
// 30-60-90 triangle will be involved in some way, which has sides of 1, sqrt(3) and 2.
const vec2 s = vec2(1, 1.7320508);

// Standard vec2 to float hash - Based on IQ's original.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(141.13, 289.97)))*43758.5453); }

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// A diamond of sorts - Stretched in a way so as to match the dimensions of a
// cube face in an isometric scene.
float isoDiamond(in vec2 p){
    
    p = abs(p);
    
    // Below is equivalent to:
    //return p.x*.5 + p.y*.866025; 
    
    return dot(p, s*.5); 

}

/*
// The 2D hexagonal isosuface function: If you were to render a horizontal line and one that
// slopes at 60 degrees, mirror, then combine them, you'd arrive at the following.
float hex(in vec2 p){
    
    p = abs(p);
    
    // Below is equivalent to:
    //return max(p.x*.5 + p.y*.866025, p.x); 

    return max(dot(p, s*.5), p.x); // Hexagon.
    
}
*/

// This function returns the hexagonal grid coordinate for the grid cell, and the corresponding 
// hexagon cell ID - in the form of the central hexagonal point. That's basically all you need to 
// produce a hexagonal grid.
//
// When working with 2D, I guess it's not that important to streamline this particular function.
// However, if you need to raymarch a hexagonal grid, the number of operations tend to matter.
// This one has minimal setup, one "floor" call, a couple of "dot" calls, a ternary operator, etc.
// To use it to raymarch, you'd have to double up on everything - in order to deal with 
// overlapping fields from neighboring cells, so the fewer operations the better.
vec4 getHex(vec2 p){
    
    // The hexagon centers: Two sets of repeat hexagons are required to fill in the space, and
    // the two sets are stored in a "vec4" in order to group some calculations together. The hexagon
    // center we'll eventually use will depend upon which is closest to the current point. Since 
    // the central hexagon point is unique, it doubles as the unique hexagon ID.
    vec4 hC = floor(vec4(p, p - vec2(.5, 1))/s.xyxy) + .5;
    
    // Centering the coordinates with the hexagon centers above.
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    
    // Nearest hexagon center (with respect to p) to the current point. In other words, when
    // "h.xy" is zero, we're at the center. We're also returning the corresponding hexagon ID -
    // in the form of the hexagonal central point. Note that a random constant has been added to 
    // "hC.zw" to further distinguish it from "hC.xy."
    //
    // On a side note, I sometimes compare hex distances, but I noticed that Iomateron compared
    // the Euclidian (squared) version, which seems neater, so I've adopted that.
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + vec2(.5, 1));
    
}




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    // Screen coordinate.
    float res = clamp(iResolution.y, 300., 600.);
	vec2 u = (fragCoord - iResolution.xy*.5)/res;
    

    // Scaling, translating, then converting it to a hexagonal grid cell coordinate and
    // a unique coordinate ID. The resultant vector contains everything you need to produce a
    // pretty pattern, so what you do from here is up to you.
    vec4 h = getHex(u*6. + s.yx*iTime/4.);
   
    
    // Storing the relative hexagonal position coordinates in "p," just to save some writing. :)
    vec2 p = h.xy;
    
    // Relative squared distance from the center.
    float d = dot(p, p)*1.5;
    
    
    // Using the idetifying coordinate - stored in "h.zw," to produce a unique random number
    // for the hexagonal grid cell.    
    float rnd = hash21(h.zw);
    rnd = sin(rnd*6.283 + iTime)*.5 + .5;
    // It's possible to control the randomness to form some kind of repeat pattern.
    //rnd = mod(h.z + h.w, 4.);
    


    
    // Initiate the background to white.
    vec3 col = vec3(1);    


    // Using the random number associated with the hexagonal grid cell to provide some color
    // and some smooth blinking. The coloring was made up, but it's worth looking at the 
    // "blink" line which smoothly blinks the cell color on and off.
    //
    float blink = smoothstep(0., .125, rnd - .75); // Smooth blinking transition.
    float blend = dot(sin(u*3.14159*2. - cos(u.yx*3.14159*2.)*3.14159), vec2(.25)) + .5; // Screen blend.
    col = max(col - mix(vec3(0, .4, .6), vec3(0, .3, .7), blend)*blink, 0.); // Blended, blinking orange.
    col = mix(col, col.xzy, dot(sin(u*5. - cos(u*3. + iTime)), vec2(.3/2.)) + .3); // Orange and pink mix.
    
    // Uncomment this if you feel that greener shades are not being fairly represented. :)
    //col = mix(col, col.yxz, dot(cos(u*6. + sin(u*3. - iTime)), vec2(.35/2.)) + .35); // Add some green.


    
    // Tile flipping - If the unique random ID is above a certain threshold, flip the Y coordinate, which
    // is effectively the same as rotating by 180 degrees. Due to the isometric lines, this gives the
    // illusion that the cube has been taken away. To build upon the illusion, the shading (based on 
    // distance to the cell center) is inverted also, which gives a fake kind of ambient occlusion effect.
    //
    if(rnd>.5) {
        
        p.xy = -p.xy;
        col *= max(1.25 - d, 0.);
    }
    else col *= max(d + .55, 0.);    
 
    
    // Cube face ID - not to be confused with the hexagonal cell ID. Basically, this partitions space
    // around the horizontal and two 30 degree sloping lines. The face ID will be used for a couple of
    // things, plus some fake face shading.
    float id = (p.x>0. && -p.y*s.y<p.x*s.x)? 1. : (p.y*s.y<p.x*s.x)? 2. : 0.;
 
    
    // Decorating the cube faces:
    //
    // Distance field stuff - There'd be a heap of ways the render the details on the cube faces,
    // and I'd imagine more elegant ways to get it done. Anyway, on the spot I decided to render three 
    // rotated diamonds on the hexagonal face, and do a little shading, etc. All of this is only called 
    // once, so whatever gets the job done, I guess. For more elaborate repeat decoration, I'd probably
    // use the "atan(p.y, p.x)" method. By the way, if someone can come up with a more elegant solution, 
    // feel free to let me know.
    //
    // Three rotated diamonds to represent the face borders.
    float di = isoDiamond((p - vec2(0, -.5)/s));
    di = min(di, isoDiamond(r2(3.14159/3.)*p - vec2(0, .5)/s));
	di = min(di, isoDiamond(r2(-3.14159/3.)*p - vec2(.0, .5)/s));
    di -= .25;
    
    // Face borders - or dark edges, if you prefer.
    float bord = max(di, -(di + .01));  
    
    // The cube holes. Note that with just the solid cubes, the example becomes much simpler,
    // and the code footprint decreases considerably.
    #ifdef CUBE_HOLES
    // Smaller diamonds for the holes and hole borders.
    float hole = di + .15;  
    #ifdef SOME_SOLID
    if(abs(rnd - .55)>.4) hole += 1e5;
    #endif
    float holeBord = max(hole, -(hole + .02));
    
    // The lines through the holes for that hollow cube look... Yeah, there'd definitely be
    // a better way to achive this. :)
    holeBord = min(holeBord, max(abs(p.x) - .01, hole));
    holeBord = min(holeBord, max(abs(p.x*s.x + p.y*s.y) - .02, hole));
    holeBord = min(holeBord, max(abs(-p.x*s.x + p.y*s.y) - .02, hole));
    
    // All the borders.
    bord = min(bord, holeBord);
    
    // Shading inside the holes - based on some isometric line stepping. It works fine,
    // but I coded it without a lot of forethought, so it looks messy... Needs an overhaul.
    float shade;
    if(id == 2.) shade = .8 -  step(0., -sign(rnd - .5)*p.x)*.2;
    else if(id == 1.) shade = .7 -  step(0., -sign(rnd - .5)*dot(p*vec2(1, -1), s))*.4;
    else shade = .6 -  step(0., -sign(rnd - .5)*dot(p*vec2(-1, -1), s))*.3;
    
    // Applying the cube face edges, shading, etc. 
    //
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, hole))*shade); // Hole shading.
    #endif
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, bord))*.95); // Dark edges.
    col = mix(col, col*2., (1. - smoothstep(0., .02, bord - .02))*.3); // Edge highlighting.
    // Subtle beveled edges... just for something to do. :)
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, max(di + .045, -(di  + .045 + .01))))*.5);
   
    // Cube shading, based on ID. Three different shades for each face of the cube.
    col *= id/2. + .1;
    


   //////
    
    // Random looking diagonal hatch lines.
    float hatch = clamp(sin((u.x*s.x - u.y*s.y)*3.14159*120.)*2. + .5, 0., 1.); // Diagonal lines.
    float hRnd = hash21(floor(p/6.*240.) + .73);
    if(hRnd>.66) hatch = hRnd; // Slight, randomization of the diagonal lines.  
    col *= hatch*.25 + .75; // Combining the background with the lines.

    
    // Subtle vignette.
    u = fragCoord/iResolution.xy;
    col *= pow(16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .125)*.75 + .25;
    // Colored variation.
    //col = mix(pow(min(vec3(1.5, 1, 1)*col, 1.), vec3(1, 3, 16)).zyx, col, 
             //pow(16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .125)*.5 + .5);    
     
  
    // Rough gamma correction and screen presentation.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
}