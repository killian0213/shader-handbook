// Common (common) — Mobius Spiral Sphere Projection by Shane
// https://www.shadertoy.com/view/7fl3DX

// Cotterzz's raytraced sphere fix: The standard function most 
// of us use doesn't really cater for miniscule spheres. If speed
// was a concern and the spheres were larger (most of the time,
// they are), you could use the regular one.
float traceSphere(in vec3 ro, in vec3 rd, in vec4 sph){

    vec3 oc = ro - sph.xyz;
	float b = dot(oc, rd);
    if(b>0.) return 1e8;
    // OLD: catastrophic cancellation near silhouette edges
    // float c = dot(oc, oc) - sph.w*sph.w;
    // float h = b*b - c;

    // NEW: h = r² - |oc × rd|²  (stable, no large-minus-large)
    vec3 cx = cross(oc, rd);
    float h = sph.w*sph.w - dot(cx, cx);

    if(h < 0.) return 1e8;
    return -b - sqrt(h);    
}
 
// Plane intersection: Old formula, and could do with some tidying up.
// The tiny "9e-7" figure is something I hacked in to stop near plane 
// artifacts from appearing. I don't like it at all, but not a single 
// formula I found deals with the problem. There definitely has to be
// a better way, so if someone knows of a more robust formula, I'd 
// love to use it.
float tracePlane(vec3 ro, vec3 rd, vec3 n, vec3 o){


    float t = 1e8;
 
	float ndotdir = dot(rd, n);
     
	if (ndotdir<0.){
	
		float dist = -(dot(ro - o, n) + 9e-7*0.)/ndotdir;	// + 9e-7
   		
		if (dist>0.){ 
            t = dist; 
  		}
	}
    
    return t;

}

// This example only works with a flat top arrangement, but
// I'll arrange for it to work with both later.
#define FLAT_TOP_HEXAGON

// Helper vector. If you're doing anything that involves regular triangles or hexagons, the
// 30-60-90 triangle will be involved in some way, which has sides of 1, sqrt(3) and 2.
#ifdef FLAT_TOP_HEXAGON
const vec2 s = vec2(1.7320508, 1)/2.;
#else
const vec2 s = vec2(1, 1.7320508)/2.;
#endif


// The 2D hexagonal isosuface function: If you were to render a horizontal line and one that
// slopes at 60 degrees, mirror, then combine them, you'd arrive at the following. As an 
// aside, the function is a bound -- as opposed to a Euclidean distance representation, but 
// either way, the result is hexagonal boundary lines.
float hex(in vec2 p){
    
    p = abs(p);
    
    #ifdef FLAT_TOP_HEXAGON
    // Below is equivalent to:
    //return max(p.x*.866025 + p.y*.5, p.y); 

    return max(dot(p, vec2(1.7320508, 1)/2.), p.y); // Hexagon.
    #else
    // Below is equivalent to:
    //return max(p.x*.5 + p.y*.866025, p.x); 

    return max(dot(p, vec2(1, 1.7320508)/2.), p.x); // Hexagon.
    #endif
    
}

// The hexagon grid.
//
// This function returns the hexagonal grid coordinate for the grid cell, and the 
// corresponding hexagon cell ID -- in the form of the central hexagonal point. That's 
// basically all you need to produce a hexagonal grid.
//
// When working with 2D, I guess it's not that important to streamline this particular 
// function. However, if you need to raymarch a hexagonal grid, the number of operations 
// tend to matter. This one has minimal setup, one "floor" call, a couple of "dot" calls, 
// a ternary operator, etc. To use it to raymarch, you'd have to double up on everything -- 
// in order to deal with overlapping fields from neighboring cells, so the fewer operations 
// the better.
vec4 getHex(vec2 p){
    
    // The two mutually offset coordinate systems. One for each hexagon.
    //
    // Two sets of repeat hexagons are required to fill in the space, and the two 
    // sets are stored in a "vec4" in order to group some calculations together. 
    // The hexagon center we'll eventually use will depend upon which is closest to the 
    // current point. Since the central hexagon point is unique, it doubles as the unique
    // hexagon ID.
    vec4 h = vec4(p, p - s/2.);
    // Their respective IDs. iC*s.xyxy represent the cell centers.
    vec4 iC = floor(h/s.xyxy) + .5;
     
    // Centering the coordinates with hexagon centers above to
    // produce respective local coordinates.
    h -= iC*s.xyxy; 
 
    // Determine the nearest hexagon cell, then return the local coordinates
    // and the integer IDs. Multiplying the ID by "s" will give you the
    // position based hexagon center.
    return dot(h.xy, h.xy)<dot(h.zw, h.zw)? vec4(h.xy, iC.xy) : vec4(h.zw, iC.zw + .5);     

}
