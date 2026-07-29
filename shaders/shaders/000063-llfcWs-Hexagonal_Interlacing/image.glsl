// Image (image) — Hexagonal Interlacing by Shane
// https://www.shadertoy.com/view/llfcWs

/*

	Hexagonal Interlacing
	---------------------

    If you're interested in graphics, then I'll assume you've seen the countless faux 
	3D interlaced-looking patterns on the internet. Recently, BigWings released a really 
	cool hexagonal weave pattern, which was pieced together with a bunch of repeat  
	hexagonal Truchet tiles constructed with combinations of overlapping arcs and 
	lines -- I've provided a link below, for anyone who's interested.

	Anyway, this is a very basic interlaced hexagonal pattern, and is representative of 
	many other variations you come across on the net. I threw it together on the fly, 
    and without a great deal of forethought, so I wouldn't take the code too seriously. 
	It works fine and runs fine, but there'd be better ways to go about it.

	To produce the pattern, set up a hexagonal grid, render a three pronged shape over
	another three pronged shape rotated at 60 degrees, then randomly flip tiles. If you
	know how to render a thick line over another, then it should be pretty simple.

	The pattern has been rendered in an oldschool Photoshop vector-graphics style -- 
	Overlays with contour lines, drop shadows, beveling, etc, and faux lighting. In case 
	it isn't obvious, the lighting is completely fake. There's no physical lighting setup 
	whatever, which means no diffuse calculations, attenuation, bumpmapping, etc.

	That's three hexagon examples in row, so I'm a bit hexagoned out, but I'll put up a 
	proper 3D example later. By the way, it'd be great to see other repeat patterns --
	interlaced or otherwise -- produced on Shadertoy.


	Other interlaced pattern examples:
	
	Hexagonal Truchet Weaving - BigWIngs
	https://www.shadertoy.com/view/llByzz

	// Fabrice has a heap of overlapping tile examples that are fun to watch. This is
	// one of them.
	canvas2 - FabriceNeyret2
	https://www.shadertoy.com/view/4dSXWR

	Starter references:

	// You can't do a hexagonal grid example without referencing this. :) Very stylish.
	Hexagons - distance - iq
	https://www.shadertoy.com/view/Xd2GR3


	// Simpler hexagonal grid example that attempts to explain the grid setup used to produce 
	// the pattern here.
	//
	Minimal Hexagonal Grid - Shane
	https://www.shadertoy.com/view/Xljczw

*/




// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Standard vec2 to float hash - Based on IQ's original.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(141.213, 289.847)))*43758.5453); }


// Helper vector. If you're doing anything that involves regular triangles or hexagons, the
// 30-60-90 triangle will be involved in some way, which has sides of 1, sqrt(3) and 2.
const vec2 s = vec2(3, 1.7320508);


// The 2D hexagonal isosuface function: If you were to render a horizontal line and one that
// slopes at 60 degrees, then combine them, you'd arrive at the following.
float hex(in vec2 p){
    
    p = abs(p);
    
    // Below is equivalent to:
    //return max(p.y*.5 + p.x*.866025, p.y); 

    return max(dot(p, s*.5), p.y); // Hexagon.
    
}

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
    vec4 hC = floor(vec4(p, p - vec2(1.7320508, .866025))/s.xyxy) + .5;
    
    // Centering the coordinates with the hexagon centers above.
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    
    // Nearest hexagon center (with respect to p) to the current point. In other words, when
    // "h.xy" is zero, we're at the center. We're also returning the corresponding hexagon ID -
    // in the form of the hexagonal central point. Note that a random constant has been added to 
    // "hC.zw" to further distinguish it from "hC.xy."
    //
    // On a side note, I sometimes compare hex distances, but I noticed that Iomateron compared
    // the Euclidian version, which seems neater, so I've adopted that.
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + vec2(1.7320508, .866025));
    
    //hp = h.xy;
    
    //return vec4(h.zw, hex(h.xy), length(h.xy));
    
    
}


// The distance function. The simple things are oftne the best, so I'm using circles, but there
// are countless variations to try, so I've left the rough working below, for anyone interested
// in experimenting.
float dist(vec2 p, float r){
    
    
    return length(p) - r;
    
    //float c = length(p);
    //return max(c, -c + 1.) - r;
    
    //p = r2(3.14159/4.)*p;
    //float c = pow(dot(pow(abs(p), vec2(3)), vec2(1)), 1./3.);
    //return c - r*.9;
    
    //p = r2(3.14159/4.)*p;
    //float c = pow(dot(pow(abs(p), vec2(3)), vec2(1)), 1./3.);//length(p);
    //return max(c, -c + .97) - r;

    
    //float c = length(p);
    //p = abs(p);
    //return mix(c, max(p.x*.866025 + p.y*.5, p.y), .35) - r*.95;
    //return min(c, max(p.x, p.y) + .125) - r;
    //p = r2(3.14159/24.)*p;
    //return min(c, max(p.x, p.y) + .16) - r;
    
    //return max(c, -c + 1.) - r;
    //p = r2(3.14159/6.)*p;
    //return max(c, max(abs(p.x)*.866 - p.y*.5, p.y) + .25) - r;
    
    
    //p = abs(p);
    //return max(p.x*.866025 + p.y*.5, p.y) - r*.9;
    //p = r2(3.14159/6.)*p;
    //return max(max(p.x, p.y), (p.x + p.y)*.75) - r;
    //return min(max(p.x, p.y), (p.x + p.y)*.7) - r*.7;
    
}

///
// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(41, 289)));
    //return fract(vec2(262144, 32768)*n); 
    
    // Animated.
    p = fract(vec2(262144, 32768)*n); 
    // Note the ".333," insted of ".5" that you'd expect to see. When edging, it can open 
    // up the cells ever so slightly for a more even spread. In fact, lower numbers work 
    // even better, but then the random movement would become too restricted. Zero would 
    // give you square cells.
    return sin( p*6.2831853 + iTime)*.333 + .333; 
    //return sin( p*6.2831853 + iTime*2.)*(cos( p*6.2831853 + iTime*.5)*.3 + .5)*.45 + .5; 
    
}

// IQ's smooth minimum function.
float smin(float a, float b, float k){

    float h = clamp(.5 + .5*(b - a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1. - h);
}

// IQ's exponential-based smooth minimum function. Unlike the polynomial-based
// smooth minimum, this one is commutative.
float sminExp(float a, float b, float k)
{
    float res = exp(-k*a) + exp(-k*b);
    return -log(res)/k;
}


// 2D 2nd-order Voronoi: Obviously, this is just a rehash of IQ's original. I've tidied
// up those if-statements. Since there's less writing, it should go faster. That's how 
// it works, right? :)
//
// This is exactly like a regular Voronoi function, with the exception of the smooth
// distance metrics.
float Voronoi(in vec2 p){
    
    // Partitioning the grid into unit squares and determining the fractional position.
	vec2 g = floor(p), o; p -= g;
	
    // "d.x" and "d.y" represent the closest and second closest distances
    // respectively, and "d.z" holds the distance comparison value.
	vec3 d = vec3(2); // 8., 2, 1.4, etc. 
    
    // A 4x4 grid sample is required for the smooth minimum version.
	for(int j = -1; j <= 2; j++){
		for(int i = -1; i <= 2; i++){
            
			o = vec2(i, j); // Grid reference.
             // Note the offset distance restriction in the hash function.
            o += hash22(g + o) - p; // Current position to offset point vector.
            
            // Distance metric. Unfortunately, the Euclidean distance needs
            // to be used for clean equidistant-looking cell border lines.
            // Having said that, there might be a way around it, but this isn't
            // a GPU intensive example, so I'm sure it'll be fine.
			d.z = length(o); 
            
            // Up until this point, it's been a regular Voronoi example. The only
            // difference here is the the mild smooth minimum's to round things
            // off a bit. Replace with regular mimimum functions and it goes back
            // to a regular second order Voronoi example.
            d.y = max(d.x, smin(d.y, d.z, .4)); // Second closest point with smoothing factor.
            d.x = smin(d.x, d.z, .2); // Closest point with smoothing factor.
            
            // Based on IQ's suggestion - A commutative exponential-based smooth minimum.
            // This algorithm is just an approximation, so it doesn't make much of a difference,
            // but it's here anyway.
            //d.y = max(d.x, sminExp(d.y, d.z, 10.)); // Second closest point with smoothing factor.
            //d.x = sminExp(d.x, d.z, 20.); // Closest point with smoothing factor.

                       
		}
	}    
	
    // Return the regular second closest minus closest (F2 - F1) distance.
    return d.y - d.x;
    
}

////

// Cheap and nasty 2D smooth noise function with inbuilt hash function - based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values. I'll swap it for something more robust later.
float n2D(vec2 p) {

	vec2 i = floor(p); p -= i; p *= p*(3. - p*2.);  
    
	return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}

// Approximating - very roughly - the metallic Shadertoy texture. I handcoded this to 
// keep algorithmic art purists - like Dr2 - happy. :)
vec3 tex(in vec2 p){
    
    float ns = n2D(p)*.57 + n2D(p*2.)*.28 + n2D(p*4.)*.15;

    // Some fBm noise based bluish red coloring.
    vec3 n = mix(vec3(.33, .11, .022), vec3(.385, .55, .715), ns);
    n *= mix(vec3(1, .9, .8), vec3(0, .1, .2), n2D(p*32.))*.6 + .4;
    
    //n =  n*.3 + min(n.zyx*vec3(1.3, .6, .2)*.75, 1.)*.7;
    
    return clamp(n, 0., 1.);

}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Scaled, moving screen coordinates.
    float res = clamp(iResolution.y, 300., 750.);
	vec2 uv = (fragCoord - iResolution.xy*.5)/res*5.;
    
    // Movement.
    uv += vec2(.5, .125)*iTime;
    
    // HEXAGONAL GRID CONVERSION.
    //
    // Obtain the hexagonal grid information.
    vec4 hp = getHex(uv);
    
    // Distance from the pixel to the hexagonal center.
    float cDist = length(hp.xy); 
    
    // Random tile ID.
    float rnd = fract(sin(dot(hp.zw, vec2(41.13, 289.97)))*43758.5453);
    //rnd = mod(floor(hp.x + hp.y), 2.);
    
    
    // Comment this out and you'll see two nontangled hexagonal grids.
    if(rnd>.5) hp.x = -hp.x; // Has the same effect as rotating by 60 degrees.
    
    // Saving the grid coordinates in "p" to save some writing.
    vec2 p = hp.xy;
    
    // TILE CONSTRUCTION.
    //
    // Creating the hexagonal tile. Partition the hexagon into three sections,
    // then subtract circles from the edges. That will creat one three pronged
    // fan looking object. Create another one rotated at 60 degrees to the 
    // other, then render one over the other. The weaving illusion is created 
    // when you randomly flip tiles.
    //
    // 
    // Three pronged object one.
    float rad1 = 1.;
    float rad2 = .66; // Hole radius.
    //float rad2 = .525*(sin(iTime/2.)*.25 + 1.2); // Animated. Shows Truchet relationship.
    
    // Contruct three circular holes - equispaced around the hexagonal boundary.
    const float aNum = 3.;
    float ia = floor(atan(p.y, p.x)/6.283*aNum) + .5;
    
    p = r2(ia*6.283/aNum)*p; // Converting to polar coordinates: p.x = radius, p.y = angle.
    p.x -= rad1; // Moving the radial coordinate out to the radius of the arc.
    
    // Mask and distance field.
    float mask = dist(p, rad2);
    float d = max(-mask, mask - .05);
      
   
    // Three pronged object two.
    p = hp.xy;
    p = r2(-3.14159/3.)*p; // Rotate by 60 degrees.
 
    ia = floor(atan(p.y, p.x)/6.283*aNum) + .5;
    
    p = r2(ia*6.283/aNum)*p; // Converting to polar coordinates: p.x = radius, p.y = angle.
    p.x -= rad1; // Moving the radial coordinate out to the radius of the arc.
    
    // Mask and distance field for the second object. Note the extra mask step.
    float mask2 = dist(p, rad2);
    float d2 = max(-mask2, mask2 - .05);
    d2 = max(d2, mask - .05);
 
    // Overlapped shadow object. There'd be a few ways to go about it, but this'll do.
    float sh  = cDist - .4;
    sh = max(sh, smoothstep(0., .01, mask)); // Taking the top layer from the mask;
    sh = max(sh, -mask);
    
    
    // Combine the three pronged objects to for the  lattice.
    d = min(d, d2);
     
    // The lattice mask. Constructed with the over and under lattices.
    mask = max(mask, mask2);
     
    
    // RENDERING.
    //
    // A concentric geometric pattern. Part science, part trial and error. 
    vec3 pat = mix(vec3(1), vec3(0), (1. - clamp(sin(cDist*3.14159*12.)*4. + 3.95, 0., 1.))*.7);
    pat = min(pat, mix(vec3(1), vec3(0), (1. - clamp(sin(cDist*3.14159*12./3.)*4. + 3., 0., 1.))*.3));
     
    
    // The background. Starting with the pattern above, then adding color and shadows.
    vec3 bg = mix(vec3(1), vec3(0), pat);
    vec3 red = mix(vec3(1, .1, .2), vec3(1, .2, .4), dot(sin(uv*3.14159 + cos(uv.yx*3.14159)*3.14159), vec2(.25)) + .5);
    float shMsk = max(mask,  -mask - .075);
    bg = mix(bg, vec3(0), (1. - smoothstep(0., .05, shMsk))*.75)*red*3.;
    
    bg += mix(vec3(1), red.yzx, .5)*bg*smoothstep(0., .3, Voronoi(uv*1.5 - vec2(1, .25)*iTime*.5) - .25)*3.;
    
    // Lamest lighting and environmental mapping ever. Applying a moving Voronoi pattern to the 
    // background. I've added a little more to the interweaved lattice object (further down) too.
    // More light is being applied to the background to give the impression that it's somehow made
    // of shinier stuff... That was the idea anyway. :)
    float vor = Voronoi(uv*1.5 - vec2(1, .25)*iTime*.5);
    bg += mix(vec3(1), red.yzx, .5)*bg*smoothstep(0., .05, vor - .25)*.5;
    
    
    
    // Lattice color with patterned decoration.
    vec3 latCol = vec3(1)*pat;
    
    // A bit of whitish edging. I made a lot of this up as I went along.
    latCol = mix(latCol, vec3(1), smoothstep(0., .05, -(d - .09))*.9);
  
    // Applying the overlayed lattice to the background, then applying some texturing. By the way,
    // the texture is a very rough handcoded representation of the metallic texture on Shadertoy. 
    // I kept the example "resource free" to keep the algorithmic art purists - like Dr2 - happy. :)
    vec3 tx = tex(uv*1.);
    tx = smoothstep(0.05, .5, tx);
    tx *= vec3(.8, 1, 1.2);
    
    vec3 col = mix(bg, latCol, smoothstep(0., .01, mask))*mix(tx, vec3(1.25), .5);
    
    
    // Haphazard sinusoidal overlay to give the impression that some extra lighting is happening. 
    // No science - It's there to make the structure look more shiny. :)
    col *= mix(vec3(1.1), vec3(.7), dot(sin(uv*3.14159 - cos(uv.yx*3.14159)*3.14159), vec2(.25)) + .5);
   
  
    // More depth... thrown in as an afterthought. 
    col = mix(col, vec3(0), (1. - smoothstep(0., .2, d))*.35);

    // Edge lines.
    col = mix(col, vec3(cDist/32.), (1. - smoothstep(0., .01, d - .03))); // Edge line depth.
    col = mix(col, vec3(.2), (1. - smoothstep(0., .01, d))*.9); // Edge lines.
    col = mix(col, vec3(0), (1. - smoothstep(0., .05, d))*.35); // Softer structure shadows.
  
    
 	// Using the distance field to add a bit of shine.
    float shine = smoothstep(0., .075, d - .15);
 	col += col*vec3(.5, .7, 1)*shine*.5;        

    
    // Shadow for the overlapped sections to give a bit of fake depth.
    col = mix(col, vec3(0), (1. - smoothstep(0., .5, sh))*.9); 
    
    
    
    // Lamest lighting and environmental mapping ever. :)
    col += mix(vec3(1), red.yzx, .5)*col*smoothstep(0., .35, vor - .25)*.5;
    
    

     
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125);
    // Colored variation.
    //col = mix(pow(min(vec3(1.5, 1, 1).zyx*col, 1.), vec3(1, 3, 16)), col, 
             //pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125)); 

    
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
}