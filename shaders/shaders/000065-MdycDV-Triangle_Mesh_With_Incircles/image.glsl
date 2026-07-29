// Image (image) — Triangle Mesh With Incircles by Shane
// https://www.shadertoy.com/view/MdycDV

/*

	Triangle Mesh With Incircles
	----------------------------

	Applying some mild adaptions to Tomkh's random triangulation algorithm to create a 
	haphazard triangular mesh with some inscribed packed circles.

	I'd made a few half-hearted attempts to put together a geometric Delaunay triangulation in
	shader form, but for some reason the lack of random pixel access was throwing me off. Anyway, 
	I made a side comment regarding my desire to see one on Shadertoy, and Tomkh posted a really
	cool looking and clever example almost immediately afterward, which pleased me no end. :)
	If you haven't seen it, I've provided a link below.

	This shader is just a variation of the original. I wrote it from scratch, but based it on 
	the logic from Tomkh's example. I expanded the 2x2 grid count to 3x3, in order to enable 
	the grid vertices to move further away from their original positions. In addition, I've 
	taken a polygon hit approach. Basically, I've iterated through all possible contributing 
	quadrilaterals within the pixel area, determined the specific triangle, then effectively 
	broken from the loop and returned its three vertices and unique identifier.

	The beauty of having access to the triangle vertices and ID in screen space is that you can
	render anything you want using normal vector rendering techniques. It's also pretty easy
	to render inscribed circles, circumscribed circles, etc. With more work, and provided you
	have a Delaunay triangulation, Voronoi edge lists are possible, and you can do some really
	cool things with those.

	Note that I haven't called this a Delaunay triangulation. Tohkh's example puts a restriction
	on the grid vertex movement, whereas I've allowed them to move more, which might break the 
	algorithm -- I have a feeling that additional neighboring checks might be necessary, but I 
    can't be sure. That's a question for someone else to answer, but either way, I'm going to 
	attempt to construct a dual Voronoi edge-list version next, so I'll find out soon enough... 
	unless Tomkh wants to do that too. :D

	For anyone interested, I've provided a bunch of "define" directives below. For instance,
	there are defines that'll exclude the background mesh and incircles for anyone who wants
	to study the mesh without the visual clutter. There's also a few different palette choices.



	Based on:

	// I'd been wanting to see a geometric Delaunay triangulation example on Shadertoy for ages,
	// so Tomkh (Tomasz Dobrowolski) was kind enough to whip one up in virtually no time. In
	// addition to helping me out, I really like the way this is presented.
	Random Delaunay Triangulation - Tomkh
	https://www.shadertoy.com/view/4sKyRD

	Another example:
    
	// Really nice screensaver-like example. To my knowledge, Mattz was the first to put up a 
	// quasi-randomized 2D triangle mesh. However, his particular example uses the same diagonal
	// orientation on each quadrilateral.
	ice and fire - mattz
	https://www.shadertoy.com/view/MdfBzl


*/

// Color palette. The default red and gold trim (0), a four-colored pastel palette (1), greyscale with
// color (2), or just greyscale (3).
#define PALETTE 0 
//#define GREY_LINES

// Fixed unanimated triangles, if you don't like the triangle popping effect. :)
//#define FIXED

// Include the background mesh, or not. Excluding it gives a cleaner, but less interesting, look. 
#define BG_MESH

// Inscribed circle inclusion. Excluding will make the example less exciting, but easier to inspect 
// the mesh constuction.
#define INCIRCLES

// A visual aid to show the physical square grid.
//#define SHOW_GRID_CELLS


// 2x2 matrix rotation. Note the absence of "cos." It's there, but in disguise, and comes courtesy
// of Fabrice Neyret's "ouside the box" thinking. :)
mat2 rot2( float a ){ vec2 v = sin(vec2(1.570796, 0) + a);	return mat2(v, -v.y, v.x); }


// Greyscale.
vec3 grey(vec3 col){ return vec3(1)*dot(col, vec3(.299, .587, .114)); }


// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(113, 1)));
    #ifdef FIXED
    return (fract(vec2(262144, 32768)*n) - .5)*2.*.35;//*.8 + .2; 
    #else
    // Animated.
    p = fract(vec2(262144, 32768)*n); 
    // Note the ".35," insted of ".5" that you'd expect to see. We don't want to 
    // exceed the cell boundaries, plus we need a little room to render points, so
    // ".45" is about the maximum, but we're using less for better looking triangles.
    return sin( p*6.2831853 + iTime/2.)*.35;
    #endif
}


// vec2 to vec2 hash.
float hash21(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    return fract(sin(dot(p, vec2(113, 1)))*43758.5453);
} 

// Triangle's incenter: The center of the inscribed circle, which in essence is the largest
// circle that you can fit into a triangle.
vec2 inCent(vec2 p0, vec2 p1, vec2 p2){
    
    // Side lengths.
    float bc = length(p1 - p2), ac = length(p0 - p2), ab = length(p0 - p1);
    return (bc*p0 + ac*p1 + ab*p2)/(bc + ac + ab);    
}

// The radius of the triangle's incircle: I'm keeping this separate to the function
// above, but you could amalgamate the two. 
float inCentRad(vec2 p0, vec2 p1, vec2 p2){

    // Side lengths.
    float bc = length(p1 - p2), ac = length(p2 - p0),  ab = length(p0 - p1);
        
    // Area.
    float p = (bc + ac + ab)/2.;
    float area = sqrt(p*(p - bc)*(p - ac)*(p - ab));
    
    return area/p;
}



// Signed distance to the segment joining "a" and "b." We need this one to determine
// which side of the line a point is on.
//
// From Tomkh's original example. I trimmed it a bit, but for all I know, I might have
// made is slower. :)
float sDistLine(vec2 a, vec2 b) {
       
    b -= a; return dot(a, vec2(-b.y, b.x)/length(b)); //return dot(a, normalize(vec2(-b.y, b.x)));
}

// Unsigned distance to the segment joining "a" and "b."
float distLine(vec2 a, vec2 b){
    
	vec2 pa = a;
	vec2 ba = a - b;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
	//return smoothstep(-thickness*.5, thickness, length(pa - ba * h));
    return length(a - ba*h);
}

// From the the following example:
// Random Delaunay Triangulation - Tomkh
// https://www.shadertoy.com/view/4sKyRD
//
// Use "parabolic lifting" method to calculate if two triangles are about to flip.
// This is actually more reliable than circumscribed circle method.
// The technique is based on duality between Delaunay Triangulation
// and Convex Hull, where DT is just a boundary of convex hull
// of projected seeds onto paraboloid.
// We project (h1 h2 h3) triangle onto paraboloid
// and return the distance of the origin
// to a plane crossing projected triangle.
float flipDistance(vec2 h1, vec2 h2, vec2 h3)
{
   // Projects triangle on paraboloid.
   vec3 g1 = vec3(h1, dot(h1, h1));
   vec3 g2 = vec3(h2, dot(h2, h2));
   vec3 g3 = vec3(h3, dot(h3, h3));
   // Return signed distance of (g1, g2, g3) plane to the origin.
   //#if FLIP_ANIMATION
    // return dot(g1, normalize(cross(g3-g1, g2-g1)));
   //#else
     // If we don't do animation, we are only interested in a sign,
     // so normalization is unnecessary.
   	 return dot(g1, cross(g3-g1, g2-g1));
   //#endif
}

/*
// IQ's triangle hit routine.
bool insideTri(vec2 p, vec2 a, vec2 b, vec2 c){
    
 	// Compute vectors        
    vec2 v0 = c - a;
    vec2 v1 = b - a;
    vec2 v2 = p - a;

    // Compute dot products
    float dot00 = dot(v0, v0);
    float dot01 = dot(v0, v1);
    float dot02 = dot(v0, v2);
    float dot11 = dot(v1, v1);
    float dot12 = dot(v1, v2);

    // Compute barycentric coordinates
    float invDenom = 1./(dot00*dot11 - dot01*dot01);
    float u = (dot11*dot02 - dot01*dot12)*invDenom;
    float v = (dot00*dot12 - dot01*dot02)*invDenom;

    // Check if point is in triangle
    return (u>0. && v>0. && (u + v)<1.)? true : false;  
    
}
*/

float cross2d( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

// IQ's point in a quadrilateral routine -- IQ's original is more sophisticated, but
// I only needed to return a hit, so I hacked at it a bit. There are probably faster 
// routines, especially since the UV coordinates aren't required. However, I might use them
// later, so I'll leave it as is for now. By the way, if someone has a fast "point inside a
// quad" algorithm, I'd like to hear about it.
//
// Given a point p and a quad defined by four points {a,b,c,d}, return the bilinear
// coordinates of p in the quad. Returns (-1,-1) if the point is outside of the quad.
bool insideQuad(in vec2 a, in vec2 b, in vec2 c, in vec2 d){

    vec2 res = vec2(-1.0);

    vec2 e = b-a;
    vec2 f = d-a;
    vec2 g = a-b+c-d;
    vec2 h = -a;
        
    float k2 = cross2d( g, f );
    float k1 = cross2d( e, f ) + cross2d( h, g );
    float k0 = cross2d( h, e );

    // otherwise, it's a quadratic
    float w = k1*k1 - 4.0*k0*k2;
    if( w<0.0 ) return false; //vec2(-1.0);
    w = sqrt( w );


    float ik2 = 0.5/k2;
    float v = (-k1 - w)*ik2; if( v<0.0 || v>1.0 ) v = (-k1 + w)*ik2;
    float u = (h.x - f.x*v)/(e.x + g.x*v);
    if( u<0.0 || u>1.0 || v<0.0 || v>1.0 ) return false;//vec2(-1.0);
    //res = vec2( u, v );
    
    return true;
}



// The triangle object.
struct triObj{
    
    vec2 p0, p1, p2; // The triangle vertices.
    
    // Unique ID and one of four triangle cell IDs, which depend on the quadrilateral arrangement.
    vec2 id, cID; 
    
};
    

// The triangle mesh routine: Iterate through the cell and it's 8 neighbors until we hit a quadrilateral, 
// then determine which triangle information to return.
//
// I wrote this from scratch, but basically adapted the logic from Tomkh's Delaunay triangle mesh example.
// It was surprisingly easy to write, but if it were not for his example, I wouldn't have known where to begin. :)
triObj triangulate(in vec2 p){
    
    // I'm declaring the vertices outside the loop, because it looks neater, but I hear it's faster to declare them
    // as locally as possible.
    vec2 o, o1, o2, o3;
	
    // Cell identifier and fractional position.
    vec2 g = floor(p); p -= g + .5;
    
    triObj tri; // The triangle object.
    tri.p0 = tri.p1 = tri.p2 = vec2(0); // Not really necessary, but just in case I've overlooked something.
    tri.id = vec2(-1); // Not necessary, since we're guaranteed a hit, but it's a raytracing habit.
    tri.cID = vec2(-1); // Not necessary, since we're guaranteed a hit, but it's a raytracing habit.
    
    // Precalculating the hash values so as not to recalculate too many in the main loop. Basically, I'm setting 
    // up an extra loop, an array, plus indexing, etc, in order to cut down from a possible 36 hash calculations 
    // to 16. Not to mention, making thing less readable... Therefore, it might be a case of diminishing returns. 
    // I'd like to hear what the experts have to say about this, because I'm on the fence as to whether I should
    // be complicating things and wasting resources with this step. :)
    //
    vec2 aO[16];
    for(int j=0; j<4; j++){
		for(int i=0; i<4; i++){
            
            aO[j*4 + i] = vec2(i - 1, j - 1) + hash22(g + vec2(i - 1, j - 1)) - p;            
        }
    }
    
    
    // Iterate through the cell and its 8 neighbors until we hit a quadrilateral, then determine which
    // triangle to return. I've allowed the grid vertices to randomly move further away from their original
    // positions, which requires 9 cell checks, instead of just 4. If you restricted random vertex movement
    // to a factor of ".25" (See the "hash22" function), only 4 checks would be necessary.
    //
    // By the way, once a triangle has been found, we break from the loop to avoid further redundant 
    // calculations. This means fewer than 9 checks are performed on average -- A rough guess would be an
    // average of 5 checks per pass which I'd expect most GPUs can handle in their sleep.
    //
	for(int j=0; j<3; j++){
		for(int i=0; i<3; i++){
            
 			// The four quadrilateral vertices for this particular cell. Clockwise arrangement.
            // o -- o1
            // |    |
            // o3-- o2
			//o = vec2(i - 1, j) + hash22(g + vec2(i - 1, j)) - p; // Origin -- Top left.
            //o1 = vec2(i, j) + hash22(g + vec2(i, j)) - p; // Top right.
            //o2 = vec2(i, j - 1) + hash22(g + vec2(i, j - 1)) - p; // Bottom right.
            //o3 = vec2(i - 1, j - 1) + hash22(g + vec2(i - 1, j - 1)) - p; // Bottom left.
            o = aO[(j + 1)*4 + i]; // Origin -- Top left.
            o1 = aO[(j + 1)*4 + i + 1]; // Top right.
            o2 = aO[j*4 + i + 1]; // Bottom right.
            o3 = aO[j*4 + i]; // Bottom left.

            
    
            // If the point resides in this particular cell's quad, determine which triangle it resides in.
            if(insideQuad(o, o1, o2, o3)){
                
                // Applying the Delaunay rule to the quad: Basically, split the quad along an arbitrary diagonal to form
                // a triangle. Circumscribe a circle around them, then determine whether the excluded fourth point lies 
                // within the circle. If it does, then flip the diagonal. There's a bit of math and theory behind it, but 
                // thankfully, Tomkh took care of that bit. :)
                //
                // By the way, there's no rule that says you need to do it this way -- You could restric the vertice
                // movement more, then simply flip the diagonal on a random basis. However, the following tends to look 
                // better. Plus, if you wish to put together a Delaunay triangulation for various reasons -- like 
                // constructing the dual Voronoi representation -- this step is necessary.
                float f = flipDistance(o - o2, o1 - o2, o3 - o2)<0.? 1. : -1.;
                //
                // Random. Only works with more restricted vertice movement, and not as nice.
                //float f = hash21(g + vec2(i , j))>.5? 1. : -1.; 

                
                if(f>0.){ // Diagonal runs from the top right vertex to the bottom left vertex.
                    
                     // Determining which side of the diagonal quadrilateral line the point is on. In other words,
                     // determine which of the two triangles that make up the quad the point is in.
                     if(sDistLine(o1, o3)>=0.){
                        o2 = o1; o1 = o; o = o3; // o3, o, o1 triangle.
                        tri.cID = vec2(0);
                    }
                    else {
                        o = o1; o1 = o2; o2 = o3; // o1, o2, o3 triangle.
                        tri.cID = vec2(1);
                    }
                    
                }
                else { // Diagonal runs from the top left vertex to the bottom right vertex.
                   
                    // If we have the flipped diagonal arrangement, determine which triangle the point is in.
                    if(sDistLine(o, o2)>=0.){
                        o1 = o3; o3 = o; o = o2; o2 = o3; // o2, o3, o triangle.
                        tri.cID = vec2(2);
                    }
                    else {
                        tri.cID = vec2(3); // o, o1, o2 triangle.
                    }                  
                }

                
                tri.p0 = o; tri.p1 = o1; tri.p2 = o2;
                tri.id = tri.cID + g + vec2(i - 1, j - 1);
                
                // Once we've effectively hit a triangle, break to save further calculations.
                break;
                
            }
            
                       
		}
	}
    
    // Return the triangle object -- Vertices, IDs, etc.
    return tri;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Screen coordinates. Note that I've put restrictions on the resolution. I coded this for
    // the 800 by 450 canvas, so the image looks a little bloated in fullscreen. Therefore, I've
    // attempted to counter that by restricting is to 800 pixels... It kind of works. :)
	vec2 uv = (fragCoord.xy - iResolution.xy*.5)/clamp(iResolution.y, 350., 800.);
    
    
    #ifdef FIXED
    // Basic diagonal scrolling.
    vec2 p = uv*5. - vec2(2, 1)*iTime/8.;
    #else 
    // Moving everything down slightly to give the mild impression that the structure is
    // slowly sliding down a wall... or something. I make this up as I go along. :)
    vec2 p = uv*5. - vec2(0, -1)*iTime/8.;
    #endif
    
    

    // Perform the triangulation: This function returns the triangle object struct, which consists of the
    // three triangle vertices, the unique cell ID, and another triangle ID for coloring.
    triObj tri = triangulate(p);
    
    // Use the three triangle vertices to calculate the inner circle center.
    vec3 inC;
    inC.xy = inCent(tri.p0, tri.p1, tri.p2); // Inner circle center.
    inC.z = inCentRad(tri.p0, tri.p1, tri.p2); // Maximum radius to the three sides.
    
    // Using the three vertices to calculate the triangle distance value -- which can be used for shading
    // triangle edge outlines, etc.
    float d0, d1, d2;
    d0 = distLine(tri.p0, tri.p1);
    d1 = distLine(tri.p1, tri.p2);
    d2 = distLine(tri.p2, tri.p0);
    float triDist = min(min(d0, d1), d2);
    
    
 
    // Cell color, based on the four triangle arrangements: Top-left, top-right, bottom-left and bottom-right.
    vec3 cellCol;
    
    if(tri.cID.x == 3.) cellCol = vec3(1, 1.3, .6); // Green.
    else if(tri.cID.x == 2.) cellCol = vec3(1.4, 1, .6); // Orangey brown.
    else if(tri.cID.x == 1.) cellCol = vec3(.6, 1, 1.4); // Blue.
    else cellCol = vec3(1.4, .7, .8); // Pinkish red.
    
    //if(hash21(tri.id)>.4) cellCol = grey(cellCol);
    
    #if PALETTE==0
    // The less complicated default palette. For amateurs like myself, fewer colors are easier to work with. :)
    if(tri.cID.x != 3.) cellCol = grey(cellCol); // Greyscale.
    else cellCol = vec3(1.3, .2, .1); // Redish. //vec3(1.2, .1, .15); //vec3(.8, .28, .05)
    #elif PALETTE==2
    if(tri.cID.x == 1. || tri.cID.x == 3.) cellCol = grey(cellCol);
    #elif PALETTE==3
    cellCol = grey(cellCol);
    #endif
    
    // The triangle cell background.
    // Mixing in a bit of the edge color with the cell color to give the impression that some mild lighting 
    // is occurring.
    vec3 bg = mix(cellCol, vec3(1, .9, .7), .25);
    // Mutliplying by a factor of the triangular distance for a bit of shading.
    bg *= (triDist*.7 + .3)*1.55;
    
    // Start the layering process by initating to the triangle cell background.
    vec3 col = bg;
    
        
    // Cell background lines.
    //col *= clamp(sin((rot2((id).x)*p).x*6.283*20.)*1.5 + 1.35, 0., 1.)*.5 + .5;
    //col *= clamp(sin((line)*6.283*16.)*1.5 + 1.35, 0., 1.)*.5 + .5;
    float hatch = clamp(sin((p.y - p.x)*6.283*14.)*1.5 + 1.35, 0., 1.);
    //float hRnd = hash21(floor(p/5.*240.) + .73);
    //if(hRnd>.8) hatch = hRnd; // Slight, randomization of the diagonal lines.  
    col *= hatch*.5 + .5; // Combining the background with the lines.


    #ifdef BG_MESH
    // Finer background layer mesh.
    // Cover some of the triangle cells with a smaller triangulated mesh. Because of the layering order,
    // it gives the impression that the mesh is behind the top layer, which in turn gives the image
    // some faux depth. Comment this block out for a cleaner, but less interesting, look.
	if(tri.cID.x != 3. && hash21(tri.id)>.5){ // if(hash21(id).x>.5), etc.    
         
        const float scF = 2.5; // Second mesh scaling factor.
        triObj tri2 = triangulate(p*scF);

        float point2 = min(min(length(tri2.p0/2.5), length(tri2.p1/2.5)), length(tri2.p2/2.5)) - .04;
        vec3 inC2;
        inC2.xy = inCent(tri2.p0, tri2.p1, tri2.p2);

        d0 = (distLine(tri2.p0, tri2.p1));
        d1 = (distLine(tri2.p1, tri2.p2));
        d2 = (distLine(tri2.p2, tri2.p0));
        float triDist2 = min(min(d0, d1), d2)/scF - .015;

        // Triangle borders.
        col = mix(col, vec3(0), (1. - smoothstep(0., .1, triDist2))*.5);
        col = mix(col, vec3(0), 1. - smoothstep(0., .015, triDist2 - .02));
        vec3 lCol2 = vec3(1, .85, .4)*.8;
        #ifdef GREY_LINES
        lCol2 = grey(lCol2);
        #endif
        col = mix(col, lCol2, 1. - smoothstep(0., .015, triDist2));

		// Vertices.
        col = mix(col, vec3(0), 1. - smoothstep(0., .01, point2 - .02));        
        col = mix(col, vec3(1, .9, .7), 1. - smoothstep(0., .01, point2));
	}
    #endif
    

    #ifdef INCIRCLES
    // Inner circles.
    //if(hash21(tri.id)>.35){ // Leave some cells empty.
    vec2 a = inC.xy;
    // Polar lines around the circle edges.
    float dir = (tri.cID.x==0. || tri.cID.x==2.)? -1. : 1.;
    float ang = mod(atan(a.y, a.x) + dir*iTime/2., 3.14159*2.);
    float hLines = clamp(sin(ang*(floor((inC.z - .055)*69.) + 3.))*1.5 + 1.35, 0., 1.)*.7 + .3;
    // Innercircle.
    float inPoint = length(inC.xy) - inC.z + .055;
    col = mix(col, vec3(0), (1. - smoothstep(0., .1, inPoint - .0))*.5);
    col = mix(col, vec3(0), 1. - smoothstep(0., .01, inPoint - .02));
    vec3 iC = cellCol*max(1. - length(inC.xy)/inC.z*.7, 0.);
    //iC *= clamp(cos(length(inC.xy)*6.283*16.)*1. + .85, 0., 1.)*.15 + .85; // Subtle concentric pattern.
	col = mix(col, mix(vec3(1, .9, .7), iC, .4)*hLines, 1. - smoothstep(0., .01, inPoint));
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, inPoint - .02 + .08))*.9);
    col = mix(col, iC, 1. - smoothstep(0., .01, inPoint + .08));
    // Innercircle points.
    inPoint = length(inC.xy) - .025;
    col = mix(col, vec3(0), 1. - smoothstep(0., .01, inPoint - .02));
	col = mix(col, mix(vec3(1, .9, .7), cellCol, .25), 1. - smoothstep(0., .01, inPoint));
	//} 
    #endif
    
    
   
    
    // Triangle borders.
    vec3 lCol = vec3(1, .8, .3);//*min(.8 + triDist*16., 1.); // Line color.
    #ifdef GREY_LINES 
    lCol = grey(lCol);
    #endif
    triDist -= .0175;
    col = mix(col, vec3(0), (1. - smoothstep(0., .1, triDist))*.5);
    col = mix(col, vec3(0), 1. - smoothstep(0., .015, triDist - .02));
    col = mix(col, lCol, 1. - smoothstep(0., .015, triDist));//vec3(1, .8, .25)

    //col = mix(col, (vec3(0)), (1. - smoothstep(0., .01, triDist + .02))*.35);

    
    
    // Triangle vertices.
    float verts = min(min(length(tri.p0), length(tri.p1)), length(tri.p2)) - .06;
    col = mix(col, vec3(0), (1. - smoothstep(0., .1, verts))*.35);
    col = mix(col, vec3(0), 1. - smoothstep(0., .01, verts - .02));
	col = mix(col, vec3(1, .9, .7), 1. - smoothstep(0., .01, verts));
    verts += .05;
    col = mix(col, vec3(0), 1. - smoothstep(0., .01, verts - .02));
	col = mix(col, vec3(1, .9, .7), 1. - smoothstep(0., .01, verts)); 

 
    #ifdef SHOW_GRID_CELLS
    // Cell borders: If you take a look at the triangles overlapping any individual square cell, 
    // you'll see that several partial triangles contribute, and the vertices that make up each 
    // triangle span the 8 surrounding cells. This is the reason why you have to test for
    // contributing triangle intersections from all 9 cells.
    vec2 q = abs(fract(p) - .5);
    float bord = max(q.x, q.y) - .5;
    bord = max(bord, -(bord + .01));
    
    col = mix(col, vec3(0), (1. - smoothstep(0., .1, bord))*.35);
    col = mix(col, vec3(0), (1. - smoothstep(0., .01, bord - .02)));
    col = mix(col, vec3(1), (1. - smoothstep(0., .01, bord))*.75);
    #endif
       
    
    // Vignette.
    uv = fragCoord/iResolution.xy;
    col = mix(col, vec3(0), (1. - pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), 0.125*.5)));

    
    // Rough gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
    
}