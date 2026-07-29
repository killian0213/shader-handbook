// Image (image) — Simplex Weave by Shane
// https://www.shadertoy.com/view/WdlSWl

/*

	Simplex Weave
	-------------

	I was going to call this a 3D simplex weave, but technically that'd be a weave on a 3D 
    simplex grid, whereas this is a 2D simplex pattern, woven depthwise along the third
    dimension, so I'll split the difference and call it a 2.5D simplex weave. :)
    
    I hadn't coded a shader for a while, which meant I'm out of practice, so wanted something 
	nice and easy to start with. Extrapolating a 2D pattern to 3D tends to be simple enough, 
	and I figured a 3D looking simplex weave would look interesting, so here it is. I thought 
	the process would be less complex than a hexagonal weave, but in reality found it 
	somewhat trickier, due to the uneven number of cell sides and restrictiveness of the 
    pattern. In fact, it took me a while just to divise a tile that'd work.

	Either way, the idea is pretty straight forward: Partition space into a 2D simplex grid 
    (space filling equilateral triangles), then construct a 3D triangular tile that will 
    produce a connected pattern when randomly rotated about the XY plane. 
	
	Each tile consists of three arcs -- each cutting the mid section of the three triangle
	sides. One arc cuts two sides on the upper level, another cuts the two sides on the
	lower level, and the final one interpolates from a side on the upper level to one on
	the lower level... So simple, yet it took me ages realize. :) Anyway, feel free to 
	uncomment the "SIMPLEX_GRID" define for a better visual representation.

	The rest is just window dressing and so forth -- A bit of diffuse, specular, fake 
	environment mapping, etc., so you can ignore most of it. There's a few defines below, for
	anyone interested. The "FLOOR_HOLES" define adds a bit more depth to the scene. For anyone,
    who doesn't wish to sift through a bunch of esoteric code, I'll put together a simpler
	2D example to accompany this. I have a 2D example on Shadertoy already, but I'll put
	together another one that utilizes the simpler random tile rotation logic.

    The comments and code were written in a hurry, which will definitely require some 
    optimization and tidy up, so I'll get onto that in due course. For instance, I'm currently
	rendering three detailed arcs. However, there is a way to find the closest arc curve, then 
    render only one, which in theory, should improve frame rates on slower machines quite a 
	bit. However, it involves a lot of rearranging to the distance field function, so I'll 
    leave it in its current form for now.

	
    Similar examples:

    // Just one of a few of Flockaroo's really cool triangle-grid-based examples. :)
    //
	Soldering Fun - Flockaroo
    https://www.shadertoy.com/view/MlffDX

    // A nice clean weave example, and the example that put me in the mood to code this. :)
    //
	Impossible Chainmail - BigWIngs
	https://www.shadertoy.com/view/td23zV

	// A 2D version of this particular example, but it uses sorting logic -- instead 
    // of rotational, so I'll produce another pretty soon. 
    //
	// Simplex Truchet Weave - Shane
	https://www.shadertoy.com/view/4ltyRn


    // Performed on a 3D simplex (tetrahedral) grid, but doesn't involve a weave.
    //
	Simplex Truchet Tubing - Shane
	https://www.shadertoy.com/view/XsffWj

*/


// Far plane. Because of the camera angle, I was able to maintain a small bound.
#define FAR 10.

// I really liked the extra depth the floor holes gave, but felt it took away from the main 
// woven pattern, so begrudgingly downgraded them to an option. :)
//#define FLOOR_HOLES

// This displays the simplex grid boundaries on the floor, which should make it a little
// easier to visualize the individual cell tiles. I could have constructed some 3D boundaries,
// but didn't wish to overcomplicate things... more than they already are. :)
//#define SIMPLEX_GRID

// A quick hack, for anyone who'd like to look at the bump mapped floor pattern 
// on its own. It looks better with the floor holes (see above).
//#define FLOOR_PATTERN_ONLY

// Global object ID - Floor: 0, Pylon: 1, Outer rails and bolts: 2, Colored center rail: 3.
// It needs to be global to feed into other functions, and so forth.
float svObjID = 0.;

// Tri-Planar blending function. Based on an old Nvidia tutorial.
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max(abs(n) - .1, .001); // n = max(n*n - .2, 0.001), etc.
    //n /= dot(n, vec3(1)); 
    n /= length(n);
    
    vec3 tx1 = texture(tex, p.yz).xyz;
    vec3 tx2 = texture(tex, p.zx).xyz;
    vec3 tx3 = texture(tex, p.xy).xyz;
    
	return tx1*tx1*n.x + tx2*tx2*n.y + tx3*tx3*n.z;
    
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3D(vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(mod(h, 6.2831))*43758.5453), fract(sin(mod(h + s.x, 6.2831))*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's standard 2x1 hash algorithm.
float hash21(vec2 p){
 
    float n = dot(p, vec2(127.183, 157.927));
    return fract(sin(n)*43758.5453);
}

#ifdef SIMPLEX_GRID
// Unsigned distance to the segment joining "a" and "b."
float distLine(vec2 a, vec2 b){
    
	b = a - b;
	float h = clamp(dot(a, b) / dot(b, b), 0., 1.);
    return length(a - b*h);
}
#endif

/*
// IQ's extrusion formula. To save calculations, cheap alternatives 
// are used, but it's here for completeness.
float opExtrusion(in float sdf, in float pz, in float h)
{
    const float rnd = .0; // Hacky rounding factor.
    vec2 w = vec2( sdf, abs(pz) - h );
  	return min(max(w.x,w.y), 0.) + length(max(w + rnd, 0.)) - rnd;
}
*/

// Floor curve shape - Circle: 0, Hexagon: 1, Dodecahedron: 2.
// This function is used for bump mapping.
#define SHAPE 0

// Distance metric.
float dist(vec2 p){
    
    #if SHAPE == 0
    return length(p); // Circle.
    #elif SHAPE == 1
    p *= rot2(3.14159/12.);
    p = abs(p);
    return max(p.y*.8660254 + p.x*.5, p.x); // Hexagon.
    #else
    p *= rot2(3.14159/12.);
    p = abs(p);
    vec2 p2 = p*.8660254 + p.yx*.5;
    return max(max(p2.x, p2.y), max(p.x, p.y)); // Dodecahedron.
    #endif
    
}

// The main toroidal shapes, which consist of a center rail and some outer ones.
vec2 tube(vec2 p){    
     
    p = abs(p);
      
    // Center rail.
    float mid = max(p.x - .05, p.y - .01); // Square center.
    //float mid = length(p.xy*vec2(.5, 1)) - .0325; // Rounder center.
    
    // Repeat offset trick to split the single rail into two. The X coordinate
    // represents the radial distance component (as opposed to the angular one),
    // so that's the one of interest. 
    p.x = abs(p.x - .08);
    p.x -= .02; // Stretching the rails radially. Dodgy, but it works. :)
    
    // Outer rails.
    float rail = max(max(p.x, p.y), (p.x + p.y)*.7071) - .02; // Octagonal.
    //float rail = length(p) - .025; // Circular.
    //float rail = max(p.x - .015, p.y - .015); // Square.
    
    // Return the center and outer rail components.
    return vec2(rail, mid);
    
}


// Toroidal curve shape. Hexagon and dodecahedron options are provided,
// which don't really suit the scene, but are interesting enough. :)
#define SHAPE3 0

// Distance metric.
float tubeOuter(vec2 p){
    
    #if SHAPE3 == 0
    return length(p); // Circle.
    #elif SHAPE3 == 1
    p *= rot2(3.14159/12.);
    p = abs(p);
    return max(p.y*.8660254 + p.x*.5, p.x); // Hexagon.
    #else
    p *= rot2(3.14159/12.);
    p = abs(p);
    vec2 p2 = p*.8660254 + p.yx*.5;
    return max(max(p2.x, p2.y), max(p.x, p.y)); // Dodecahedron.
    #endif
    
}


// The pylons that hold up the toroidal curves.

float pylon(vec2 p){
    
    //return length(p) - .03; // Circular.
    
    p = abs(p);
    
    p.y -= .02; // Stretch along the radial coordinate.
    
    // Octagonal -- You could also try
    return max(max(p.x, p.y), (p.x + p.y)*.7071) - .025;
    
}


#define SHAPE2 1 

// Distance metric.
float tube4(vec2 p){
    
    #if SHAPE2 == 0
    return length(p); // Circle.
    #elif SHAPE2 == 1
    //p *= rot2(3.14159/12.);
    p = abs(p);
    return max(p.y*.8660254 + p.x*.5, p.x); // Hexagon.
    #else
    //p *= rot2(3.14159/12.);
    p = abs(p);
    vec2 p2 = p*.8660254 + p.yx*.5;
    return max(max(p2.x, p2.y), max(p.x, p.y)); // Dodecahedron.
    #endif
    
}

// The bump mapped version of the simplex scene. It's similar to the distance field
// version. Bump mapping adds extra complexity, but can save a lot of GPU power, so
// can be worth it.

vec4 simplexWeaveBump(vec3 q){   
    
    
    
    // SIMPLEX GRID SETUP
    
    vec2 p = q.xy; // 2D coordinate on the XY plane    
    
    vec2 s = floor(p + (p.x + p.y)*.36602540378); // Skew the current point.
    
    p -= s - (s.x + s.y)*.211324865; // Use it to attain the vector to the base vertex (from p).
    
    // Determine which triangle we're in. Much easier to visualize than the 3D version.
    float i = p.x < p.y? 1. : 0.; // Apparently, faster than: i = step(p.y, p.x);
    vec2 ioffs = vec2(1. - i, i);
    
    // Vectors to the other two triangle vertices.
    vec2 p1 = p - ioffs + .2113248654, p2 = p - .577350269; 

    
    // THE WEAVE PATTERN
    
    // A random value -- based on the triangle vertices, and ranging between zero and one.
    float dh = hash21((s*3. + ioffs + 1.));
    
 
    // Based on the unique random value for the triangle cell, rotate the tile.
    // In effect, we're swapping vertex positions... I figured it'd be cheaper,
    // but I didn't think about it for long, so there could be a faster way. :)
    //
    if(dh<1./3.) { // Rotate by 60 degrees.
        vec2 ang = p;
        p = p1, p1 = p2, p2 = ang;
        
    }
    else if(dh<2./3.){ // Rotate by 120 degrees.
        vec2 ang = p;
        p = p2, p2 = p1, p1 = ang;
    }

     
    
    // Angles subtended from the current position to each of the three vertices... There's probably a 
    // symmetrical way to make just one "atan" call. Anyway, you can use these angular values to create 
    // patterns that follow the contours. In this case, I'm using them to create some cheap repetitious lines.
    vec3 a = vec3(atan(p.y, p.x), atan(p1.y, p1.x), atan(p2.y, p2.x));
 
    // The torus rings. 
    // Toroidal axis width. Basically, the weave pattern width.
    float tw = .2;
    // For symmetry, we want the middle of the torus ring to cut dirrectly down the center
    // of one of the equilateral triangle sides, which is half the distance from one of the
    // vertices to the other. Add ".1" to it to see that it's necessary.
    float mid = dist((p2 - p))*.5;
    // The three distance field functions: Stored in cir.x, cir.y and cir.z.
    vec3 cir = vec3(dist(p), dist(p1), dist(p2));
    // Equivalent to: vec3 tor =  cir - mid - tw; tor = max(tor, -(cir - mid + tw));
    vec3 tor =  abs(cir - mid) - tw;
        
 
    

    
    // RENDERING
    // Applying the layered distance field objects.
    
    // The background. I tried non-greyscale colors, but they didn't fit.
    vec3 bg = vec3(.75);
    // Floor pattern.
    //bg *= clamp(cos((q.x - q.y)*6.2831*16.) - .25, 0., 1.)*.2 + .9;
   
    // The scene color. Initialized to the background.
    vec3 col = bg;
    
    // Outer torus ring color. 
    vec3 rimCol = vec3(.5);
    
    // Use the angular component to create lines running perpendicular 
    // to the curves.
    
    // Angular floor ridges.
    vec3 ridges = smoothstep(.05, -.05, -cos(a*12.) + .93)*.5;
    
    // Ridges pattern on the toroidal rails. Set it to zero, if you're not sure
    // what it does.
    vec3 ridges2 = smoothstep(.05, -.05, sin(a*18.) + .93);
    
    // Using the angle to create the height of the toroidal curves.
    a = sin(a*3. - 6.283/9.)*.5 + .5; 
     

    
         
    // Smoothing factor and line width.
    const float sf = .015, lw = .02;
   
    // Rendering the the three ordered (random or otherwise) objects:
    //
    // This is all pretty standard stuff. If you're not familiar with using a 2D
    // distance field value to mix a layer on top of another, it's worth learning.
    // On a side note, "1. - smoothstep(a, b, c)" can be written in a more concise
    // form (smoothstep(b, a, c), I think), but I've left it that particular way
    // for readability. You could also reverse the first two "mix" values, etc.
    // By readability, I mean the word "col" is always written on the left, the
    // "0." figure is always on the left, etc. If this were a more GPU intensive
    // exercise, then I'd rewrite things.
    
    
    // Bottom toroidal segment.
    //
    // Outer dark edges.
    //col = mix(col, vec3(.1), 1. - smoothstep(0., sf, tor.z));
    // The main toroidal face.
    //col = mix(col, rimCol*(1. - ridges.z), 1. - smoothstep(0., sf, tor.z + lw));
    
    // Same layering routine for the middle toroidal segment.
    col = mix(col, vec3(.1), 1. - smoothstep(0., sf, tor.y));
    col = mix(col, rimCol*(1. - ridges.y), 1. - smoothstep(0., sf, tor.y + lw));
  
    // The final toroidal segment last.
	col = mix(col, vec3(.1), (1. - smoothstep(0., sf, tor.x))*1.);
    col = mix(col, rimCol*(1. - ridges.x), (1. - smoothstep(0., sf, tor.x + lw))*1.);
  
    //col = vec3(1);
    
    // Hexagon centers.
    //col = mix(col, vec3(.5), (1. - smoothstep(0., sf, hole0)));

    /*
    float shp = min(tor.x, tor.y);
    shp =  -shp + .035;//abs(shp - .075);
    col = mix(col, vec3(.1), (1. - smoothstep(0., sf, shp)));
    col = mix(col, vec3(rimCol), (1. - smoothstep(0., sf, shp + lw)));
    */

    
    #ifdef SIMPLEX_GRID
    // Displaying the 2D simplex grid. Basically, we're rendering lines between
    // each of the three triangular cell vertices to show the outline of the 
    // cell edges.
    vec3 c = vec3(distLine(p, p1), distLine(p1, p2), distLine(p2, p));
    c.x = min(min(c.x, c.y), c.z);
    //col = mix(col, vec3(.1), (1. - smoothstep(0., sf*2., c.x - .0)));
    col = mix(col, vec3(.1), (1. - smoothstep(0., sf*2., c.x - .02)));
    col = mix(col, vec3(1, .8, .45)*1.35, (1. - smoothstep(0., sf*1.25, c.x - .005)));
    #endif
    
    
    // Arc tile calculations: This is a shading and bump mapping routine. However, 
    // we're using it in a 3D setting, so we need to determine which 3D tube is closest, 
    // in order to know where to apply the bump pattern.
    vec2 d1 = vec2(1e5), d2 = vec2(1e5), d3 = vec2(1e5);
    
    // Moving the Z component to the right depth, in order to match the 3D
    // pattern. I forgot to do this, and it led to all kinds of confusion. :)
    q.z -= .5;
     
    // The three arc sweeps. By the way, you can change the define above the
    // "tubeOuter" function to produce a hexagonal sweep, etc.
    float depth = .125;
    vec2 v1 = vec2(tubeOuter(p.xy) - mid, q.z - depth); // Bottom level arc.
    // This arc sweeps between the bottom and top levels.
    vec2 v2 = vec2(tubeOuter(p1.xy) - mid, q.z + depth*a.y - depth); 
    vec2 v3 = vec2(tubeOuter(p2.xy) - mid, q.z); // Top level arc.
    
    // Shaping the poloidal coordinate vectors above into rails.
    d1 = tube(v1);
    d2 = tube(v2);
    d3 = tube(v3);

    
    // Based on which tube we've hit, apply the correct anular bump pattern.
    // Try mixing this up, and you'll see why it's necessary.
    float bump = d1.x<d2.x && d1.x<d3.x? ridges2.x : d2.x<d3.x? ridges2.y : ridges2.z;
    
     
    
    // Return the simplex weave value.
    return vec4(col, 1. - bump);
 

}


// The simplex weave scene. A lot of it is made up on the fly, so it needs a tidy up,
// and more than likely, some more optimization.
//
// It returns four objects -- to be sorted later:
// Floor: 0, Pylon: 1, Outer rails and bolts: 2, Colored center rail: 3.
//
// The only object of interest is the weave tile. Each tile consists of three arcs -- each 
// cutting the mid section of the three triangle sides. One arc cuts two sides on the upper 
// level, another cuts the two sides on the lower level, and the final one interpolates from 
// a side on the upper level to one on the lower level. You can uncomment the "SIMPLEX_GRID" 
// define for a better visual representation.
//
// By the way, it's possible to find the distance to the closest arc only, then render the
// the detailed version is that particular arc alone -- provided there's no overlap. I haven't
// checked to see whether it will work, in this particular case, but will try it later. The
// payoff is increased frame rate. The downside is more coding. :D Either way, I employ that 
// particular method here:
//
// Dual 3D Truchet Tiles - Shane
// https://www.shadertoy.com/view/4l2cD3 

vec4 simplexWeave(vec3 q){
    
   
    // SIMPLEX GRID SETUP
    
    vec2 p = q.xy; // 2D coordinate on the XY plane.
   
    vec2 s = floor(p + (p.x + p.y)*.36602540378); // Skew the current point.
    
    p -= s - (s.x + s.y)*.211324865; // Use it to attain the vector to the base vertex (from p).
    
    // Determine which triangle we're in. Much easier to visualize than the 3D version.
    float i = p.x < p.y? 1. : 0.; // Apparently, faster than: i = step(p.y, p.x);
    vec2 ioffs = vec2(1. - i, i);
    
    // Vectors to the other two triangle vertices.
    vec2 p1 = p - ioffs + .2113248654, p2 = p - .577350269; 
    

    
    // THE WEAVE PATTERN
    
    // A random value -- based on the triangle vertices, and ranging between zero 
    // and one.
    float dh = hash21((s*3. + ioffs + 1.));
    
 
    // Based on the unique random value for the triangle cell, rotate the tile.
    // In effect, we're swapping vertex positions... I figured it'd be cheaper,
    // but I didn't think about it for long, so there could be a faster way. :)
    //
    if(dh<1./3.) { // Rotate by 60 degrees.
        vec2 ang = p;
        p = p1, p1 = p2, p2 = ang;
        
    }
    else if(dh<2./3.){ // Rotate by 120 degrees.
        vec2 ang = p;
        p = p2, p2 = p1, p1 = ang;
    }
     
     
    
    // Angles subtended from the current position to each of the three vertices... There's probably a 
    // symmetrical way to make just one "atan" call. Anyway, you can use these angular values to create 
    // patterns that follow the contours. In this case, I'm using them to create some cheap repetitious lines.
    vec3 a = vec3(atan(p.y, p.x), atan(p1.y, p1.x), atan(p2.y, p2.x));

    // The torus rings. 

    // For symmetry, we want the middle of the torus ring to cut dirrectly down the center
    // of one of the equilateral triangle sides, which is half the distance from one of the
    // vertices to the other. Add ".1" to it to see that it's necessary.
    float mid = dist((p2 - p))*.5;
 
    // Interspercing some pylons and bolts around the arcs using
    // a standard fixed repeat partitioning of angular components.
    
    const float aNum = 6.;
    vec3 ia = (floor(a/6.283*aNum) + .5)/aNum;
    ia += .25/aNum; // A hack to move the objects to a better place.
    
    vec2 px = rot2(ia.x*6.283)*p;
    px.x -= mid;

    vec2 py = rot2(ia.y*6.283)*p1;
    py.x -= mid;

    vec2 pz = rot2(ia.z*6.283)*p2;
    pz.x -= mid;
    
    px = abs(px);
    py = abs(py);
    pz = abs(pz);
   
    // A repeat trick to move the radial component of an object to a set distance
    // on both sides of the radial origin... A bit hard to decribe, but if you comment
    // the following lines out, you'll see what I mean. :)
    px.x = abs(px.x - .08);
    py.x = abs(py.x - .08);
    pz.x = abs(pz.x - .08);

    // Bolts.
    float cdx = tube4(px) - .02;
    float cdy = tube4(py) - .02;
    float cdz = tube4(pz) - .02;
 
    // Pylons.
    float bdx = pylon(px);
    float bdy = pylon(py);
    float bdz = pylon(pz);
     
///
    

    // Relative arc heights -- Based on the angle, and arranged to vary between
    // zero and one.
    a = sin(a*3. - 6.283/9.)*.5 + .5;

    q.z -= .5;
    
    
    // Arc tile calculations. 
    vec2 d1 = vec2(1e5), d2 = vec2(1e5), d3 = vec2(1e5);
    
    // The three arc sweeps. By the way, you can change the define above the
    // "tubeOuter" function to produce a hexagonal sweep, etc.
    float depth = .125;
    vec2 v1 = vec2(tubeOuter(p.xy) - mid, q.z - depth); // Bottom level arc.
    // This arc sweeps between the bottom and top levels.
    vec2 v2 = vec2(tubeOuter(p1.xy) - mid, q.z + depth*a.y - depth); 
    vec2 v3 = vec2(tubeOuter(p2.xy) - mid, q.z); // Top level arc.
    
    // Shaping the poloidal coordinate vectors above into rails.
    d1 = tube(v1);
    d2 = tube(v2);
    d3 = tube(v3);
    
    
    // Bolts.
    cdx = max(cdx, abs(q.z) - .03);
    cdy = max(cdy, abs(q.z) - .03);
    cdz = max(cdz, abs(q.z) - .03);
   
    q.z -= .475;//.465;
   
    // Pylons.
    bdx = max(bdx, abs(q.z) - .45);
    bdy = max(bdy, abs(q.z) - .45);
    bdz = max(bdz, abs(q.z) - .45);
    bdx = min(min(bdx, bdy), bdz);

    


    
    //////
    // The three distance field functions: Stored in cir.x, cir.y and cir.z.
    vec3 cir = vec3(dist(p), dist(p1), dist(p2));
    // Equivalent to: vec3 tor =  cir - mid - tw; tor = max(tor, -(cir - mid + tw));
    vec3 tor =  abs(cir - mid) - .21;
    
    // Optional floor holes that match the bump pattern. I like the extra detail, but 
    // figured it distracted from weave pattern itself, so left it as an option.
    float hole0 = 0.;
    #ifdef FLOOR_HOLES
    hole0 = -min(tor.x, tor.y);
    #endif
    
    // Bolts.
    d1.x = min(d1.x, cdx);
    d2.x = min(d2.x, cdy);
    d3.x = min(d3.x, cdz);
    
   
    // Obtaining the minimum of the center and outside rail objects.
    d1.xy = min(min(d1.xy, d2.xy), d3.xy);
    
   
    // Return the individual simplex weave object values:
    // Holes, pylons, rails and bolts, and center strip.
    return vec4(hole0, bdx, d1.xy);
 

}

// A container to hold the distances of four individual objects. The idea is to sort
// the objects outside raymarching loop for identification.
vec4 objID;


// Raymarching a heightmap on an XY-plane. Pretty standard.
float map(vec3 p){

    // The floor plane.
    float terr = .75 - p.z;
    
    // The simplex weave objects: 
    // hm.x - Optional floor holes, hm.y - Pylons, 
    // hm.z - Rails and bolts, hm.a - Center strip.
    vec4 hm = simplexWeave(p);
    
    // Holes in the floor. Gives more depth to the scene, but it a little distracting.
    #ifdef FLOOR_HOLES
    terr = min(terr + .05, max(terr, -hm.x));
    #endif
    
    // A quick hack, for anyone who'd like to look at the bump mapped floor pattern 
    // on its own. It looks better with the floor holes (see above).
    #ifdef FLOOR_PATTERN_ONLY
    hm += 1e5;
    #endif
    
    // Adding some pylon base detatil... I wasn't feeling it. :)
    //float pat = min(min(hm.y, hm.z), hm.a);
    //terr += smoothstep(0., .05, pat - .01)*.02;
     
    // Store the individual object IDs for sorting and object identification later.
    objID.xyzw = vec4(terr, hm.y, hm.z, hm.a);
    
    // Return the minimum distance.
    return min(terr, min(min(hm.y, hm.z), hm.a));
    
}

/*
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to 
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 doBumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(0.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
    
}
*/


// The bump mapping function.
float bumpFunction(in vec3 p){
    
    // A reproduction of the simplex weave function, with some of the unnecessary
    // calculations omitted... Having said that, there's still a little redundancy
    // in there.
    vec4 sw = simplexWeaveBump(p);
    
    float bump;
    
    if(svObjID == 0.) bump = sw.x; // Floor pattern.
    else bump = sw.w/4.; // Curved line pattern on weaved rail object.
    
    return bump;
   
   
}

// Standard function-based bump mapping function. The default here is the more expensive
// 6-tap version, but you could get away with the 4-tap, if you needed to save cycles.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor){
    
    // Resolution independent sample distance... Basically, I want the lines to be about
    // the same pixel width, regardless of resolution... Coding is annoying sometimes. :)
    vec2 e = vec2(2./iResolution.y, 0); 
    
    //float f = bumpFunction(p); // Hit point function sample.
    
    float fx = bumpFunction(p - e.xyy); // Nearby sample in the X-direction.
    float fy = bumpFunction(p - e.yxy); // Nearby sample in the Y-direction.
    float fz = bumpFunction(p - e.yyx); // Nearby sample in the Y-direction.
    
    float fx2 = bumpFunction(p + e.xyy); // Sample in the opposite X-direction.
    float fy2 = bumpFunction(p + e.yxy); // Sample in the opposite Y-direction.
    float fz2 = bumpFunction(p + e.yyx); // Sample in the opposite Z-direction.
    
     
    // The gradient vector. Making use of the extra samples to obtain a more locally
    // accurate value. It has a bit of a smoothing effect, which is a bonus.
    vec3 grad = vec3(fx - fx2, fy - fy2, fz - fz2)/(e.x*2.);  
    //vec3 grad = (vec3(fx, fy, fz ) - f)/(e.x*1.);  // Without the extra samples.

    
    // Some kind of gradient correction... I'm getting so old that I've forgotten why
    // you do this. It's a simple reason, and a necessary one. I remember that much. :D
    // Actually, there's an explanation in one of my examples on Shadertoy, so I'll 
    // track it down and transcribe it later.
    grad -= n*dot(n, grad);          
                      
    return normalize(n + grad*bumpfactor); // Bump the normal with the gradient vector.
	
}


// Normal calculation, with some edging bundled in. Curvature is there too, but it's
// commented out, in this case.
vec3 getNormal(vec3 p, inout float edge, inout float crv, float ef) { 
	
    // Roughly two pixel edge spread, but increased slightly with larger resolution.
    vec2 e = vec2(ef/mix(450., iResolution.y, .5), 0);

	float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
	float d = map(p)*2.;

    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = abs(d1 + d2 + d3 + d4 + d5 + d6 - d*3.);
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));

      
    // Wider sample spread for the curvature.
    //e = vec2(12./450., 0);
	//d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	//d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	//d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    //crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .5, 0., 1.);
 	 
    
    e = vec2(.0025, 0); //iResolution.y - Depending how you want different resolutions to look.
	d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	d5 = map(p + e.yyx), d6 = map(p - e.yyx);
	
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}


// Ambient occlusion, for that self shadowed look.
// Based on the original by IQ.
float calcAO(in vec3 p, in vec3 n)
{
	float sca = 3., occ = 0.0;
    for( int i=1; i<6; i++ ){
    
        float hr = float(i)*.125/5.;        
        float dd = map(p + hr*n);
        occ += (hr - dd)*sca;
        sca *= .75;
    }
    return clamp(1. - occ, 0., 1.);   
    
}


// Basic soft shadows.
float getShad(in vec3 ro, in vec3 n, in vec3 lp){

    const float eps = .001;
    
	float t = 0., sh = 1., dt;
    
    ro += n*eps*1.1;
    
    vec3 ld = (lp - ro);
    float lDist = length(ld);
    ld /= lDist;
    
    //t += hash31(ro + ld)*.005;
    
	for(int i = min(0, iFrame); i<24; i++){
        
    	dt = map(ro + ld*t);
        
        sh = min(sh, 8.*dt/t);
         
 		t += clamp(dt, .01, .25);
        if(dt<0. || t>lDist){ break; } 
	}

    return max(sh, 0.);
}

// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){
    
    // Note that the ray is starting just above the raised plane, since nothing is
    // in the way. It's normal practice to start at zero.
    float d, t = 0.; 
    for(int j = min(0, iFrame); j<64; j++){
      
        d = map(ro + rd*t); // distance to the function.
        // The plane "is" the far plane, so no far=plane break is needed, but it's
        // included anyway.
        if(abs(d)<.001*(1. + t*.125) || t>FAR) break;

        t += d; // Total distance from the camera to the surface.
    
    }

    return min(t, FAR);
    
}


// Simple environment mapping. Pass the reflected vector in and create some
// colored noise with it. The normal is redundant here, but it can be used
// to pass into a 3D texture mapping function to produce some interesting
// environmental reflections.
vec3 envMap(vec3 rd, vec3 sn){
    
    vec3 sRd = rd; // Save rd, just for some mixing at the end.
    
    // Add a time component, scale, then pass into the noise function.
    //rd.z -= iTime*.25;
    rd *= 2.5;
    
    float c = n3D(rd)*.57 + n3D(rd*2.)*.28 + n3D(rd*4.)*.15; // Noise value.
    c = smoothstep(.4, 1., c); // Darken and add contast for more of a spotlight look.
    
    vec3 col = vec3(c, c*c, c*c*c*c); // Simple, warm coloring.
    //vec3 col = pow(min(vec3(1.5, 1, 1)*c, 1.), vec3(1, 2.5, 12)); // More color.
    
    // Mix in some more red to tone it down and return.
    return mix(col, col.zyx, sRd*.25 + .5); 
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    
    // A lazy camera setup. There's no "to" or "from" vectors.
    
    // Unit directional ray with no divide, courtesy of Coyote.
    //vec3 rd = normalize(vec3(fragCoord - iResolution.xy*.5, iResolution.y*.5));
    
    // A warped (fisheye) unit directional ray.
    vec3 rd = normalize(vec3(fragCoord - iResolution.xy*.5, iResolution.y*.525));
    rd = normalize(vec3(rd.xy, rd.z - length(rd.xy)*.05));
    
    // Controlling the speed of the camera motion.
    float tm = iTime*.75;
    
    // Tilting, and rotating the XY-plane back and forth, for a bit of variance.
    rd.xy *= rot2(sin(tm/4.)*.25);
    rd.yz *= rot2(-.35);
    
    
    // Ray origin. Moving in the X-direction to the right.
    vec3 ro = vec3(tm, cos(tm/4.), -.5);
    
    // Light position, hovering around camera.
    vec3 lp = ro + vec3(cos(tm/2.)*.5, sin(tm/2.)*.5 + .25, -.25);
    
    // Standard raymarching function.
 	float t = trace(ro, rd);
    
    
    // Sorting the individual objects to obtain the object ID.
    svObjID = objID.x<objID.y && objID.x<objID.z && objID.x<objID.w? 0. : 
    objID.y<objID.z && objID.y<objID.w? 1. : objID.z<objID.w? 2. : 3.;
    
   
    // Surface postion, surface normal and light direction.
    vec3 sp = ro + rd*t;
    
    
    // Retrieving the normal at the hit point, whilst performing some edging.
    float edge = 0., crv = 1., ef = 4.;
	vec3 sn = getNormal(sp, edge, crv, ef); // Curvature (crv) is not used here.
 
    
    
    /*
    // Texture-based bump mapping. I wasn't feeling it, so didn't use it, but it's there 
    // for anyone who wants to try it. Just be sure to uncomment the texture bump map function.

	// Texture bump factor.
    float tBump = .005;
    if(svObjID == 0.) tBump = .005;
    
    
    if(svObjID != 3.) sn = doBumpMap(iChannel1, sp, sn, tBump);
	if(svObjID == 0.) sn = doBumpMap(iChannel1, sp, sn, tBump); 
    */
      
    // Function-based bump mapping.
    if(svObjID==0. || svObjID==3.) sn = doBumpMap(sp, sn, .02/(1. + t*.5/FAR));  
    
    
    // Point light.
    vec3 ld = lp - sp; // Light direction vector.
    float lDist = max(length(ld), 0.001); // Light distance.
    float atten = 1./(1. + lDist*lDist*.1); // Light attenuation.
    ld /= lDist; // Normalizing the light direction vector.
    
    // Obtaining the surface texel from each of the channels.
    vec3 oC0 = tex3D(iChannel0, sp, sn)*1.5;
    vec3 oC1 = tex3D(iChannel1, sp/2., sn)*1.5;
 
    // Ramping up the contrast of the second texel in all objects except the colored
    // middle rail.
    if(svObjID != 3.) oC1 = smoothstep(0., .9, oC1);
 
    vec3 oC; 
     
    // Call the simplex function to obtain a color value. It's a bit
    // wasteful, but it'll do.
    vec4 sw = simplexWeaveBump(sp);
     
    // Texture, color, etc, each of the objects. A lot of this was made up on the
    // spot. I should probably tidy it up later.
    
    if(svObjID == 0.) { // Ground plane.
        
        oC1 = mix(oC1, oC0, .25);
        oC1 *= (sw.xyz*.95 + .05); // Subtle weave coloring.        
        oC = oC1;
    }
    else if(svObjID == 1.) {  // Pylons. 
        
        oC = vec3(.375)*oC1;
        
    }
    else if(svObjID == 2.){ // Rails.
        
        oC1 = mix(oC1, oC0, .15);
        
        if(sp.z<.47) oC = oC1;
        else oC = oC1/2.;

    }
    else { // Center strip.
        
        // Reddish pink coloring.
        oC = vec3(1, .05, .1)*2.5;  
    	oC = mix(oC, oC.yzx, dot(sin(sp*4. - cos(sp.yzx*4.))*.5 + .25, vec3(1./3.)*.375));
        
        // Green.
        //oC = vec3(.4, 1, .1)*2.;  
        //oC = mix(oC, oC.zyx, dot(sin(sp*4. + cos(sp.yzx*4.))*.5 + .5, vec3(1./3.)));
        
     
        oC0 *= (sw.a*.9 + .15); // Dark bump line overlay -- For the reflective texture.
        oC1 *= (sw.a*.9 + .15); // Dark bump line overlay.
        oC *= oC1; // Give the red a bit of texture.
        
        
        
    }
    
 

    // Surface lighting.
    //
    float diff = max(dot(ld, sn), 0.); // Diffuse.
    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 16.); // Specular.
    float fre = clamp(dot(sn, rd) + 1., .0, 1.); // Fake fresnel, for the glow.
    if(svObjID == 2.) diff = pow(diff, 2.)*1.25; // Metallicize the rails a bit.

    // Shading -- Shadows and ambient occlusion. 
    //
    float sh = getShad(sp, sn, lp);
    float ao = calcAO(sp, sn); // Ambient occlusion, for self shadowing.
    // Adding a partial ambient value to the shadow, for something to do. :)
    sh = min(sh + ao*.3, 1.);
    
    // Combining the terms above to light the texel.
    vec3 col = (oC*(diff + .3*ao) + vec3(.5, .7, 1)*spec*2.);// + vec3(.1, .3, 1)*pow(fre, 4.)*4.;
    
    
	// Fake environment mapping. It's a bit hacky, but reasonably effective,
    // and far cheaper than a reflective pass.  
    //
    vec3 eMap = envMap(reflect(rd, sn), sn);
    if(svObjID == 3.) col += oC0*eMap*5.;
    else if(svObjID == 0.) col += oC1*eMap*3.;
    else col += (oC1 + .5)*eMap*3.5;
   
    
    // Edging.
    col *= 1. - edge*.7;
    
    // Applying the shades.
    col *= (atten*sh*ao);
    
    // Vignette.
    //vec2 uv = fragCoord/iResolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), 0.125);

    
    // Performing rough gamma correction, the presenting to the screen.
	fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1.);
    
}
