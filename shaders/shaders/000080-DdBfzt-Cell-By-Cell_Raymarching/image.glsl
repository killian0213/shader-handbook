// Image (image) — Cell-By-Cell Raymarching by Shane
// https://www.shadertoy.com/view/DdBfzt

/*

    Cell-By-Cell Raymarching
    ------------------------

	Amalgamating cell-by-cell traversal and raymarching to render a 
    subdivided rectangular grid. There are a few examples involving 
    similar methods on Shadertoy, so this is not new. However, it's 
    a really useful method that isn't used very often, so I figured 
    I'd attempt to post a simple example in the hopes that those not 
    familiar with the process might benefit from it.
    
    If you've ever tried raymarching a repeat space grid containing 
    objects comparable to the size of the grid cell boundaries, you'll 
    notice a lot of artifacts. The two main solutions involve
    raymarching the grid neighbors, which is usually expensive and
    doesn't always work, or to perform a cell-by-cell traversal, which
    is great, but you lose a lot of raymarching benefits, like simple
    CSG, soft shadows, uncomplicated ambient occlusion formulas, etc.
    
    The solution is to combine the two aforementioned methods in a
    surprisingly easy to implement fashion. In addition to raymarching 
    the grid as usual, you determine the distance from the ray 
    position to the cell boundary and use that to restrict the ray 
    from advancing too far. The entire process requires the addition
    of just a few extra lines.
    
    I'm not sure who first demonstrated the technique on Shadertoy, 
    but Nimitz's "Sparse grid marching" is a really nice early example. 
    IQ's "Cubescape" shader was posted over ten years ago, and that 
    utilizes similar principles, but it involves advancing the ray 
    from cell to cell, then raymarching at each step. I'm not sure 
    which method is more efficient, but I'm employing a 2D version of 
    the former. The difference between this and a regular raymarched
    grid example is a small amount of setup and extra lines in the 
    distance, trace and shadow functions.
    
    This particular method can be applied to all kinds of rectangular
    grids, and with some adjustments, other grid types are possible. I 
    have a simple 3D version that I'll post at some stage, and I 
    intend to attempt some others later.	
    
    

	Similar examples:
    
    // Really stylish.
    Sparse grid marching - nimitz
    https://www.shadertoy.com/view/XlfGDs
    
	// A cell be cell traversal with raymarching inside each cell.
    // Amazing to think that this is over ten years old.
    Cubescape  - iq
	https://www.shadertoy.com/view/Msl3Rr  
    
    // A really clever 3D subdivided example. Traversing a
    // variable sized 3D box grid is on my list.
    Box Singularity - Tater
    https://www.shadertoy.com/view/7dVGDd

*/


// Max ray distance.
#define FAR 20.

// Scene color - Bluish purlple: 0, Tequila sunrise: 1.
#define COLOR 1


// Scene object ID to separate the mesh object from the terrain.
float objID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...
float hash21(vec2 p) {
    p = fract(p*vec2(323.57, 356.63));
    p += dot(p, p + 145.123);
    return fract(p.x*p.y);
}

/*
// IQ's vec2 to float hash.
float hash21(vec2 p){  
    return fract(sin(mod(dot(p, vec2(27.609, 57.583)), 6.2831853))*43758.5453); 
}
*/





// Cube face texturing -- Hacked together quickly, but it'll work.
vec3 texCube(sampler2D iCh, in vec3 p, in vec3 n){

    
    // Use the normal to determine the face. Z facing normals 
    // imply the XY plane, etc.
    n = abs(n);
    p.xy = n.x>.5? p.yz : n.y>.5? p.xz : p.xy; 
    
    // Reusing "p" for the color read.
    p = texture(iCh, p.xy).xyz;
 
    // Rough conversion from sRGB to linear.
    return p*p;

}

// Texture sample.
//
vec3 getTex(sampler2D iCh, vec2 p){
    
    // Strething things out so that the image fills up the window. You don't need to,
    // but this looks better. I think the original video is in the oldschool 4 to 3
    // format, whereas the canvas is along the order of 16 to 9, which we're used to.
    // If using repeat textures, you'd comment the first line out.
    //p *= vec2(iResolution.y/iResolution.x, 1);
    vec3 tx = texture(iCh, p/8.).xyz;
    return tx*tx; // Rough sRGB to linear conversion.
}

// Height map value, which is just the pixel's greyscale value.
float hm(in vec2 p){ return dot(getTex(iChannel0, p), vec3(.299, .587, .114)); }



// IQ's 3D signed box formula: I tried saving calculations by using the unsigned one, and
// couldn't figure out why the edges and a few other things weren't working. It was because
// functions that rely on signs require signed distance fields... Who would have guessed? :D
float sBoxS(vec3 p, vec3 b, float sf){

  p = abs(p) - b + sf;
  return min(max(p.x, max(p.y, p.z)), 0.) + length(max(p, 0.)) - sf;
}

// IQ's 2D signed box formula with some added rounding.
float sBoxS(vec2 p, vec2 b, float sf){

  p = abs(p) - b + sf;
  return min(max(p.x, p.y), 0.) + length(max(p, 0.)) - sf;
}


// Subdivided rectangle grid.
vec4 getGrid(vec2 p, inout vec2 sc){
    
    // Block offsets.
    vec2 ipOffs = vec2(0);
    // Row or column offset. Values like "1/3" would offset more
    // haphazardly, but I wanted to maintain a little symmetry.
    const float offDst = .5; 
    if(mod(floor(p.y/sc.y), 2.)<.5){
        p.x -= sc.x*offDst; // Row offset.
        ipOffs.x += offDst;
    }
    //if(mod(floor(p.x/sc.x), 2.)<.5){
        //p.y -= sc.y*offDst; // Column offset.
        //ipOffs.y += offDst;
    //}
    
    vec2 oP = p;
    
    // Block ID.
    vec2 ip;
    
    //#define EQUAL_SIDES
    
    // Subdivide.
    for(int i = 0; i<4; i++){
        
        // Current block ID.
        ip = floor(p/sc) + .5;
        float fi = float(i)*.0617; // Unique loop number.
        #ifdef EQUAL_SIDES        
        // Squares.
        
        // Random split.
        if(hash21(ip + .253 + fi)<.333){
           sc /= 2.;
           p = oP;
           ip = floor(p/sc) + .5; 
        }
        
        #else
        
        // Powers of two rectangles.
        
        // Random X-split.
        if(hash21(ip + .253 + fi)<.333){//3 && sc.x>1./8.
           sc.x /= 2.;
           p.x = oP.x;
           ip.x = floor(p.x/sc.x) + .5;
        }
        // Random Y-split.
        if(hash21(ip + .453 + fi)<.333){ // && sc.y>1./8.
           sc.y /= 2.;
           p.y = oP.y;
           ip.y = floor(p.y/sc.y) + .5;
        }
        
        #endif
         
    }
    
    // Local coordinates and cell ID.
    return vec4(p - ip*sc, (ip + ipOffs)*sc);

}

/////////

// The isosurface distance used when raymarching refers to the nearest distance to 
// a surface in "any" direction from the current point along the ray. The nearest 
// surface might be to the left, in front, above, etc. It doesn't matter, but it 
// guarantees that you can move the ray position that far without hitting anything.

// The caveat is that it only works with Lipschitz continuous surfaces, which roughly 
// means that the absolute value between two surface gradients needs to be less than 
// some constant value... The details are not important, but it means that 
// raymarching doesn't work with all surfaces.

// You'll notice this when trying to raymarch voxelized surfaces, like a repeat grid 
// of packed rectangular prisms. Thankfully, in the case of voxel grids, there is a 
// way to fix it. The trick is to determine the distance from the current ray 
// position to the nearest cell wall in the direction of the ray, then use that 
// distance to ensure that the ray never goes beyond that. Determining ray to cell
// wall distances involves simple raytracing techniques, which are demonstrated below.

/////////

// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
// Box dimension and local XY coordinates.
vec3 gSc; 
vec2 gP;

 
// An extruded subdivided rectangular block grid. Use the grid cell's 
// center pixel to obtain a height value (read in from a height map), 
// then render a pylon at that height.

vec4 blocks(vec3 q3){
    
 
    // Local coordinates.
    vec2 p = q3.xy;


    vec3 sc = vec3(1); // Scale.
    // Local coordinates and cell ID.
    vec4 p4 = getGrid(p, sc.xy); 
    p = p4.xy;
    vec2 id = p4.zw;


    // The distance from the current ray position to the cell boundary
    // wall in the direction of the unit direction ray. This is different
    // to the minimum wall distance, so you need to trace out instead
    // of merely doing a box calculation. Anyway, the following are pretty 
    // standard cell by cell traversal calculations. The resultant cell
    // distance, "gCD", is used by the "trace" and "shadow" functions to 
    // restrict the ray from overshooting, which in turn restricts artifacts.
    vec3 rC = (gDir*sc - vec3(p, q3.z))/gRd;
    //vec2 rC = (gDir.xy*sc.xy - p)/gRd.xy; // For 2D, this will work too.
    
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... I'm not entirely sure it's
    // necessary here, but it stops artifacts from appearing with other 
    // non-rectangular grids.
    //gCD = max(min(min(rC.x, rC.y), rC.z), 0.) + .0015;
    gCD = max(min(rC.x, rC.y), 0.) + .001; // Adding a touch to advance to the next cell.


    // The extruded block height. See the height map function, above.
    float h = hm(id);
    h = (h*.975 + .025)*2.5;


    // Change the prism rectangle scale just a touch to create some subtle
    // visual randomness. You could comment this out if you prefer more order.
    sc.xy -= .05*(hash21(id)*.9 + .1);

    // Lower box prism.
    float d = sBoxS(vec3(p, q3.z + h/2.), vec3(sc.xy, h)/2., .0);

    // Putting some random boxes on top.
    if(min(sc.x, sc.y)>.125 && hash21(id + .03)<.5){ 
       float d2 = sBoxS(vec3(p, q3.z + (h*1.3)/2.), vec3(sc.xy - .16, h*1.3)/2., .0);
       d = min(d, d2);
    }

    // Saving the box dimensions and local coordinates.
    gSc = vec3(sc.xy, h);
    gP = p;

        
   
    // Return the distance, position-base ID and box ID.
    return vec4(d, id, 0);
}


// Block ID -- It's a bit lazy putting it here, but it works. :)
vec4 gID;

// The extruded image.
float map(vec3 p){
    
    // Floor.
    float fl = -p.z;

    // The extruded blocks.
    vec4 d4 = blocks(p);
    gID = d4; // Individual block ID.
    
 
    // Overall object ID.
    objID = fl<d4.x? 1. : 0.;
    
    // Combining the floor with the extruded image
    return  min(fl, d4.x);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float d, t = 0.; //hash31(ro + rd)*.15
    
    //vec2 dt = vec2(1e5, 0); // IQ's clever desparkling trick.
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd; 
    
    int i;
    const int iMax = 128;
    for (i = min(iFrame, 0); i<iMax; i++){ 
    
        d = map(ro + rd*t);       
        //dt = d<dt.x? vec2(d, dt.x) : dt; // Shuffle things along.
        
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, 
        // as "t" increases. It's a cheap trick that works in most situations.
        if(abs(d)<.001*(1. + t*.05)|| t>FAR) break; 
        
        //t += i<32? d*.75 : d; 
        t += min(d, gCD); 
    }
    
    // If we've run through the entire loop and hit the far boundary, 
    // check to see that we haven't clipped an edge point along the way. 
    // Obvious... to IQ, but it never occurred to me. :)
    //if(i>=iMax - 1) t = dt.y;

    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more 
// symmetrical.
vec3 getNormal(in vec3 p, float t) {
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	
                     map(p + e.yyx) - map(p - e.yyx)));
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 48; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = sign(rd)*.5;
    gRd = rd;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        
        
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), 
        // dist += clamp(h, .01, stepDist), etc.
        t += clamp(min(d, gCD), .02, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Shadow.
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for(int i = 0; i<5; i++){
    
        float hr = float(i + 1)*.125/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);    
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.    
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 ro = vec3(iTime/2., 0, -4); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(.02, .18, .25);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning.
    vec3 lp = ro + vec3(2, 2, 0);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.333; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x ));
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    //vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    // Rotation.
	rd.xy *= rot2(-.25);    

	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the block ID and object ID.
    vec4 svGID = gID;
    
    // Scene object ID. Either the pylons or the floor.
    float svObjID = objID;
    
    // Saving the bloxk scale and local 2D base coordinates.
    vec3 svSc = gSc;
    vec2 svP = gP;
    
	
    // Initiate the scene color to black.
    vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
        vec3 sn = getNormal(sp, t);
        
        // Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;
        
          
        // Obtaining the texel color. 
	    vec3 objCol; 
        
        float svObjEdge = 1.;

        // The extruded grid.
        if(svObjID<.5){
            
            /*
            // Random coloring using IQ's short versatile palette formula.
            float rnd = hash21(svGID.yz + .34);
            vec3 tx = .5 + .48*cos(6.2831853*rnd/10. + vec3(0, 1, 2) + .8);
            tx *= .5;
            */
       
            // Coloring the individual blocks with the saved ID.
            vec3 tx = getTex(iChannel1, svGID.yz);
            // Grunge texturing.
            vec3 tx2 = texCube(iChannel2, sp/4., sn);
            // Combining.
            objCol = tx.yzx*(tx2*2. + .2);
            //objCol = tx.yzx*.65;//
                      
                
            
            // Last minute edge routine. I've returned the nearest rectangle ID
            // and dimensions from the "raycasting" routine, and the rest 
            // figures itself out.
            float ew = .0125*(1. + t*.1); // Edge width.
            float h = svSc.z;
            float rct = sBoxS(svP, svSc.xy/2., .0);
            float top = max(abs(sp.z + h), abs(rct));
            float side = abs(abs(svP.x) - svSc.x/2.);
            side = max(side, abs(abs(svP.y) - svSc.y/2.));
            float objEdge = min(top, side) - ew;
            
            // Same for the boxes on top.
            if(min(svSc.x, svSc.y)>.125 && hash21(svGID.yz + .03)<.5){
                rct = sBoxS(svP, (svSc.xy - .16)/2., .0);
                top = max(abs(sp.z + h), abs(rct));
                top = min(top, max(abs(sp.z + h*1.3), abs(rct)));
                side = abs(abs(svP.x) - (svSc.x - .16)/2.);
                side = max(side, abs(abs(svP.y) - (svSc.y - .16)/2.));
                objEdge = min(objEdge, min(top, side) - ew);
            }
            
            svObjEdge = objEdge;
           
 
        }
        else {
            
            // The dark floor in the background. Hidden behind the pylons, but
            // you still need it.
            vec3 tx = getTex(iChannel2, sp.xy);
            objCol = vec3(.3, .15, 1)/8.*(tx*2. + 1.);
            //objCol = vec3(0);
        }
      
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
	    
	    // Light attenuation, based on the distances above.
	    float atten = 2./(1. + lDist*.125);
    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        diff = pow(diff, 2. + 16.*objCol.x*objCol.x)*2.; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd), 0.), 16.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
		// Schlick approximation. I use it to tone down the specular term.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough.  
        
        /*
        // Cheap specular reflections. Requires loading the "Forest" cube map 
        // into "iChannel3".
        float speR = pow(max(dot(normalize(ld - rd), sn), 0.), 5.);
        vec3 rf = reflect(rd, sn); // Surface reflection.
        vec3 rTx = texture(iChannel3, rf.xzy*vec3(1, -1, -1)).xyz; rTx *= rTx;
        objCol = objCol*.5 + objCol*speR*rTx*4.;
        */
        
        float svEw = .0125*(1. + t*.1);
        float sf = 4./iResolution.y;
        objCol = mix(objCol, objCol*1.5, 1. - smoothstep(0.,sf, svObjEdge - svEw));
        objCol = mix(objCol, objCol/4., 1. - smoothstep(0., sf, svObjEdge));
        
        
        // Combining the above terms to procude the final color.
        col = objCol*(diff*sh + vec3(.2, .4, 1) + vec3(1, .97, .92)*spec*freS*sh*8.);
        
        
        // Shading.
        col *= ao*atten;
          
	
	}
    
    
    // Applying fog: This fog begins at 90% towards the horizon.
    col = mix(col, vec3(1, .5, 2), smoothstep(.25, .9, t/FAR));
 
    #if COLOR == 1
    // Some gradient coloring.
    col = mix(col.zyx, col.zxy, uv.y + .5);
    #endif
    
    // Greyscale.
    //col = vec3(1)*dot(col, vec3(.299, .587, .114));
    
 
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
    
	
}