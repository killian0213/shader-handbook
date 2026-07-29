// Image (image) — 3D Diffusion Automata by Shane
// https://www.shadertoy.com/view/cl3yDN

/*

    Random Diffusion Automata 
    -------------------------
    
    Fabrice put together a pixelized diffusion example that was based on a 
    moving image he saw on X.com (both links are below), which was cool and 
    concise, but omitted smooth cell transitions. The source image contained 
    some neat sliding motion based on occupied cell elements moving to empty 
    ones -- Similar to the motion in a sliding puzzle. This is standard 
    stuff, so there are plenty of demonstrations on the internet, and even a 
    few related examples on here, but they tend to be long winded -- my own 
    efforts included...
    
    Digressing, SnoopethDuckDuck rearranged Fabrice's example and added the 
    necessary sliding element that gives it that smooth animated appearance.
    However, he managed to do it using very little code and just one texture 
    channel, which was really cleverly done. After sneaking a peak at his 
    solution, then looking at my own obfuscated mess, I realized that I'd 
    really overthought it... :)
    
    Anyway, I'm very greatful for the aforementioned postings, and this is 
    just a 3D extension of that. I used a different template, so the variables 
    and functions don't quite match up to Fabrice and SnoopethDuckDuck's, but 
    it's basically the same thing. There is also an unlisted accompanying 
    2D example with some additional texture-based cell indexing, plus some 
    explanations for anyone interested in this kind of thing.
    
    I didn't put a great deal of effort into the design, as I simply wanted 
    to get one of these on the board, as they say. 3D cell swap examples are 
    not common on Shadertoy, but I'm not the first to post one of these. 
    Coposuke posted a beautiful example a couple of years ago. I've posted 
    the link below, for anyone who hasn't seen it. 
    
    
    // Largely based on the following:
    
    // Fabrice and SnoopethDuckDuck's combined logic, which is
    // pretty difficult to compete with. It's a really nicely 
    // written example. If anyone does manage to outlogic this 
    // logic, please let me know. :) 
    Cell Swap Automata - SnoopethDuckDuck
    https://www.shadertoy.com/view/DtccR8
    
    // This is inspired by Fabrice's shader
    Shuffle gradient - random walk 3 - FabriceNeyret2 
    https://www.shadertoy.com/view/dtSfRh
    //
    In turn, based on this X.com post:
    https://twitter.com/junkiyoshi/status/1697571241513910691
    
    // This is my simple 2D version, which is an old version of Fabrice's
    // that I completely rearranged to incorporate SnoopethDuckDuck's
    // smooth cell swapping code.
    Random Diffusion Automata - Shane
    https://www.shadertoy.com/view/mtdyDH
    
    Other examples:
    
    // Beautifully done. I haven't had time to look it over, but I can 
    // see that the BRDF is really nicely done. My example also features 
    // BRDF patterned cubes, but that's purely coincidental.
    High-Collar Cubes - coposuke
    https://www.shadertoy.com/view/WldBRH
    
*/

 

//////////////////////////////////


// Max ray distance.
#define FAR 20.

// Alternate gold only color.
//#define GOLD


// Scene object ID to separate the mesh object from the terrain.
float objID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

 

// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Ryan Geiss effectively multiplies the first line by 7. It took me a while to realize that 
    // it's largely redundant, due to the division process that follows. I'd never noticed on 
    // account of the fact that I'm not in the habit of questioning stuff written by Ryan Geiss. :)
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.yz).xyz;
    vec3 ty = texture(tex, p.zx).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture sample,
    // represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n; // Equivalent to: tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;

}


// Texture sample.
//
vec3 getTex(sampler2D iCh, vec2 p){
    
    // Strething things out so that the image fills up the window. You don't need to,
    // but this looks better. I think the original video is in the oldschool 4 to 3
    // format, whereas the canvas is along the order of 16 to 9, which we're used to.
    // If using repeat textures, you'd comment the first line out.
    //p *= vec2(iResolution.y/iResolution.x, 1);
    vec3 tx = texture(iCh, p).xyz;
    return tx*tx; // Rough sRGB to linear conversion.
}

// Cube mapping - Adapted from one of Fizzer's routines. 
vec4 cubeMap(vec3 p){

    // Elegant cubic space stepping trick, as seen in many voxel related examples.
    vec3 f = abs(p); f = step(f.zxy, f)*step(f.yzx, f); 

    /*
    vec3 idF = step(0., p)*2. - 1.;
    vec3 faceID = (idF + 1.)/2. + vec3(0, 2, 4);
    */    
    
    // Integer version.
    ivec3 idF = ivec3(step(0., p))*2 - 1;
    ivec3 faceID = (idF + 1)/2 + ivec3(0, 2, 4);
    
    return f.x>.5? vec4(p.yz/p.x/2. + .5, idF.x, faceID.x) : 
           f.y>.5? vec4(p.xz/p.y/2. + .5, idF.y, faceID.y) : 
                   vec4(p.xy/p.z/2. + .5, idF.z, faceID.z); 
}

// IQ's 3D signed box formula.
float sBoxS(vec3 p, vec3 b, float sf){

    p = abs(p) - b + sf;
    return min(max(p.x, max(p.y, p.z)), 0.) + length(max(p, 0.)) - sf;
}

 
////////////////////

// Globals for the cell values, moving direction vector and cell ID.
vec4 gCell;
vec3 gTmDir;
vec3 gID3;

vec3 getAutomata(vec3 p, inout vec3 sc){

    
    // Obtaining the four object (particle) values for this cell.
    // Channel values:
    // X: Original cell position ID (for colors, etc). Needs converting to vec2.
    // Y: Direction (clockwise from the left): Left, up, right, down (0, 1, 2, 3).
    // Z: Transfer time. Starting (0), ending (1), or somewhere between ([0, 1]).
    // W: Inactive or active status (0 or 1) -- Empty or not.
    //
    // Using "floor(p)" to avoid artifacts at certain resolutions.
    //vec4 cell = texelFetch(iChannel0, ivec2(floor(p/sc)), 0);
    
    //vec4 cell = tMap(iChannel0, mod(floor(p/sc), wrap));
    
    vec2 uv = convertCoord(mod(floor(p/sc), wrap));//mod(floor(p/sc), wrap)
    vec4 cell = texelFetch(iChannel0, ivec2(uv), 0);

    // Inactive to active transfer (cell.z), or active to inactive transfer.
    // Inactive moves forward (cell.z), active are losing a particle, so move in the
    // opposite direction (1. - cell.z).
    //
    // Smoothly transition from one cell to the next. It's a minor distinction, but
    // an asymmetric easing process needs to be applied prior to mixing.
    cell.z = smoothstep(.15, .85, cell.z); 
    float tm = mix(cell.z, 1. - cell.z, cell.w);
     
    
    
    // Cell coordinate ID. Converting from stored float to vec2.
    //vec3 iq = vec3(cell.x, floor(cell.x/wrap), floor(cell.x/(wrap*wrap)));
    vec3 iq = mod(vec3(cell.x, floor(cell.x/wrap), floor(cell.x/(wrap*wrap))), wrap);


    // Local cell coordinates.
    vec3 q = mod(p, sc) -.5*sc; 
    
    // Cell direction.
    vec3 dir = indexToDir(cell.y);
    
    
    gCell = cell;
    
 
    // Size.
    //float rndSz = hash21(iq + .11);
    //float obj = sBoxS(q - tm*dir, vec2(.4), .2);
    //float obj = length(q - tm*dir) - (.4 - .0*rndSz); // Etc.
    
    gTmDir = tm*dir*sc;
    
    //q -= gTmDir;
    
    gID3 = iq*sc;
    
        
    return q;//vec4(q, iq*sc);
 
}


///////////////////


// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
// Box dimension and local XY coordinates.
vec3 gSc; 
vec3 gP;

 
// An extruded subdivided rectangular block grid. Use the grid cell's 
// center pixel to obtain a height value (read in from a height map), 
// then render a pylon at that height.

vec4 blocks(vec3 q3){
    
 

  
    // Scale. This will include two blocks, each 8 cells deep, so we'll move the wall
    // forward by half a unit to obscure the second block.
    vec3 sc = vec3(1./16.);
    
    
    // Local coordinates and ID.
    vec3 p = getAutomata(q3, sc);
    vec3 id3 = gID3;
 


    // The distance from the current ray position to the cell boundary
    // wall in the direction of the unit direction ray. This is different
    // to the minimum wall distance, so you need to trace out instead
    // of merely doing a box calculation. Anyway, the following are pretty 
    // standard cell by cell traversal calculations. The resultant cell
    // distance, "gCD", is used by the "trace" and "shadow" functions to 
    // restrict the ray from overshooting, which in turn restricts artifacts.
    vec3 rC = (gDir*sc - vec3(p))/gRd;
    //vec2 rC = (gDir.xy*sc.xy - (p))/gRd.xy; // For 2D, this will work too.
    
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... I'm not entirely sure it's
    // necessary here, but it stops artifacts from appearing with other 
    // non-rectangular grids.
    gCD = max(min(min(rC.x, rC.y), rC.z), 0.) + .0015;
    //gCD = max(min(rC.x, rC.y), 0.) + .001; // Adding a touch to advance to the next cell.

   
    // Change the prism rectangle scale just a touch to create some subtle
    // visual randomness. You could comment this out if you prefer more order.
    sc -= .005;//*(hash21(id)*.9 + .1);
    
  
    // Move the box.
    p -= gTmDir;
    

    // Rendering the box. You could do some cool things here, but I've
    // kept things simple.
    float d = sBoxS(p, sc/2., .05*sc.x);
    
    //float dS = length(p) - sc.x/2.;
    //d = mix(d, dS, .125);
    

    
    
    // This is a bit of a hack to get rid of fuzzy shadows. Basically, 
    // don't render inactive cells that are technically out of cell range.
    if(gCell.z==1. && gCell.w == 0.) d = 1e5;
    
   

    // Debug: Getting rid of some boxes.
    //if(hash31(id3)<.5) d  = 1e5;
    
    
    // Only include one block level (16 z-positions deep), just in front of the wall
    if(floor(q3.z) != -1.) d = 1e5; 
    
    // Excluding XY sheets behind this Z depth.
    //if(floor(id3.z/sc.z)>3.) d = 1e5;

    // Saving the box dimensions and local coordinates.
    gSc = sc;//vec3(sc.xy, h);
    gP = p;
    
   
    // Return the distance, position-base ID and box ID.
    return vec4(d, id3);
}


// Block ID -- It's a bit lazy putting it here, but it works. :)
vec4 gID, svGID;

// The extruded image.
float map(vec3 p){
    
    // Floor, or wall, depending on your perspective. Kind of redundant,
    // since you can't see it, but it's there, just in case.
    float fl = -p.z - .5;

    // The extruded blocks.
    vec4 d4 = blocks(p);
    gID = d4; // Individual block ID.
    
    /*
    // Putting the boxes in a cage... No. Dumb idea, but I had to try. :)
    vec3 dC = vec3(1e5);
    vec3 sc = vec3(1./16.);
    vec3 q = mod(p + sc/2., sc) -.5*sc; 
    dC.x = sBoxS(q.xy, sc.xy*.05, .025*sc.x);
    dC.y = sBoxS(q.yz, sc.yz*.05, .025*sc.x);
    dC.z = sBoxS(q.xz, sc.xz*.05, .025*sc.x);
    float dR = min(min(dC.x, dC.y), dC.z);
    
    fl = min(fl, dR);
    fl = max(fl, -(p.z + 1. + .05*gSc.z));
    */
    
 
    // Overall object ID.
    objID = fl<d4.x? 1. : 0.;
    
    // Combining the floor with the extruded image
    return  min(fl, d4.x);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float d, t = 0.;// hash31(ro + rd)*.15;
    
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
        if(abs(d)<.001 || t>FAR) break; 
        
        //t += i<32? d*.75 : d; 
        t += min(d*.9, gCD); 
    }
    
    // If we've run through the entire loop and hit the far boundary, 
    // check to see that we haven't clipped an edge point along the way. 
    // Obvious... to IQ, but it never occurred to me. :)
    //if(i>=iMax - 1) t = dt.y;

    return min(t, FAR);
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    const vec2 e = vec2(.001, 0);
    
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = min(iFrame, 0); i<6; i++){
		mp[i] = map(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 64; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        
        
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), 
        // dist += clamp(h, .01, stepDist), etc.
        t += clamp(min(d*.9, gCD), .01, .25); 
        
        
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


// Surface bump function..
float bumpSurf3D(in vec3 p, in vec3 n){


    vec3 id3 = svGID.yzw;
    vec4 c4 = cubeMap(p);
    vec2 tuv = c4.xy;
    float faceID = c4.w;

    vec2 oTuv = tuv;

    vec2 scl = vec2(1);
    vec2 oScl = scl;


    // The two distance field values (they overlap) and corresponding
    // lines patterns.
    vec4 d = Truchet(tuv, id3, faceID, scl);

    // Edge width and smoothing factor.
    float ew2 = .03*oScl.x;
    float sf2 = .02*oScl.x;

    // Saving the original cube color.
    float objCol = (.25);

    // A little extra thickness for the edges.
    d.xy -= ew2*2.;

    // Distance field shading.
    vec2 sh = max(-d.xy/oScl.x*4., 0.);
    sh = smoothstep(0., .65, sh);

    // Rendering the two overlapping distance fields and line patterns.
    for(int i = 0; i<2; i++){

         // Line pattern.
         float lnCol = mix(.5, .35, 1. - smoothstep(0., sf2, d[i + 2]));

         // Subtle highlighting.
         lnCol *= .25 + sh[i]*.75;

         // Faux AO, dard edges and pattern.
         objCol = mix(objCol, 0., (1. - smoothstep(0., sf2*4., d[i]))*.5);
         objCol = mix(objCol, 0., 1. - smoothstep(0., sf2, d[i]));
         objCol = mix(objCol, lnCol, 1. - smoothstep(0., sf2, d[i] + ew2));

    }  
    
    return objCol;

}


 
// Standard function-based bump mapping routine: This is the cheaper four tap version. 
// There's a six tap version (samples taken from either side of each axis), but this 
// works well enough.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the 
    // aliasing.
    const vec2 e = vec2(.001, 0);  
    
    mat4x3 p4 = mat4x3(p, p - e.xyy, p - e.yxy, p - e.yyx);
    
    // This utter mess is to avoid longer compile times. It's kind of 
    // annoying that the compiler can't figure out that it shouldn't
    // unroll loops containing large blocks of code.
 
    vec4 b4;
    for(int i = min(iFrame, 0); i<4; i++){
        b4[i] = bumpSurf3D(p4[i], n);
        if(n.x>1e5) break; // Fake break to trick the compiler.
    }
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    vec3 grad = (b4.yzw - b4.x)/e.x; 
   
    
    // Six tap version, for comparisson. No discernible visual difference, in a lot of 
    //cases.
    //vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
    //                 bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
    //                 bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;
    
  
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some 
    // kind of orthogonal space fix using the Gram-Schmidt process, or something to that 
    // effect.
    grad -= n*dot(n, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more 
    // bumpy.
    return normalize(n + grad*bumpfactor);
	
}

///////////////////////////

/*
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. 
// I tried to make it as concise as possible. Whether that translates to speed, 
// or not, I couldn't say.
vec3 texBump( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale 
    // texture values.    
    mat3 m = mat3(tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), 
                  tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(.299, .587, .114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(.299, .587, .114)))/e.x; 
    
    // Adjusting the tangent vector so that it's perpendicular to the normal -- Thanks 
    // to EvilRyu for reminding me why we perform this step. It's been a while, but I 
    // vaguely recall that it's some kind of orthogonal space fix using the Gram-Schmidt 
    // process. However, all you need to know is that it works. :)
    g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
	
} 
*/

//////////


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.    
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 lk = vec3(iTime/32., .036, -1); // "Look At" position.
	vec3 ro = lk + vec3(-.04, .12, -.3);  // Camera position.
 
    // Light positioning.
    vec3 lp = ro + vec3(1, .38, -.5);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159/3.; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x ));
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    // Rough fish-eye lens.
    rd = normalize(vec3(rd.xy, sqrt(max(rd.z*rd.z - dot(rd.xy, rd.xy)*.125, 0.))));
    
    // Evening the camera up a bit.
    rd.xy *= rot2(-.02);
    
    /*
    // Mouse movement.
    if(iMouse.z>1.){
        rd.yz *= rot2(-(iMouse.y - iResolution.y*.5)/iResolution.y*3.1459);  
        rd.xz *= rot2(-(iMouse.x - iResolution.x*.5)/iResolution.x*3.1459);  
    } 
    */  

	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the block ID and object ID.
    svGID = gID;
    
    // Scene object ID. Either the pylons or the floor.
    float svObjID = objID;
    
    // Saving the bloxk scale and local 2D base coordinates.
    vec3 svSc = gSc;
    vec3 svP = gP;
    
    // Saving the moving direction position vector.
    vec3 svDir = gTmDir;
    
	
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
        
        
        vec3 svTx;

        // The extruded grid.
        if(svObjID<.5){
            
             vec3 txP = svP;//vec3(svP, sp.z);
            //txP.xy += svDir;
            
            vec3 id3 = svGID.yzw;
            
            // Random coloring using IQ's short versatile palette formula.
            //float rnd = hash31(id3 + .34);
            //vec3 sCol = .5 + .45*cos(6.2831853*rnd/1. + vec3(0, 1, 2) + .8);
            
            
            // Coloring the individual blocks with the saved ID.
            vec2 id2 = convertCoord(floor(id3/svSc.x));
            vec3 col1 = getTex(iChannel1, id2*svSc.x/2.);
            col1 = smoothstep(.0, .5, col1);
            
            // More coloring.
            vec3 col2 = getTex(iChannel2, id2*svSc.x/2.);
            col2 = smoothstep(-.1, .35, col2);
            
            // Grunge texturing.
            vec3 tx1 = tex3D(iChannel1, (id3 + txP)*2., sn);
            vec3 tx2 = tex3D(iChannel1, (id3 + txP)*4., sn);
            tx1 = smoothstep(.0, .5, tx1);
             
            // Random colors.
            objCol = (hash31(id3 + .22)<.333)? col2 : col1;
            
            // Interwoven checkered colors.
            //vec3 id = floor(id3/svSc);
            //if(mod(id.x + id.y + id.z, 2.)<.5) objCol = objCol.zyx;

                      
            // Texturing the colored boxes and adding some sepia.
            objCol *= vec3(1.5, 1.25, 1)*(tx2*3. + .25);
 
            
            #ifdef GOLD 
            // Alternate gold coloring.
            objCol = vec3(.3 + hash31(id3 + .51)*.4);
            if(hash31(id3 + .21)<1.5)
            objCol = .5 + .45*cos(6.2831853*hash31(id3 + .32)/8. + vec3(0, 1.2, 2) + .25);
            objCol *= vec3(1, 1.1, 1.2);
            //if(hash31(id3 + .26)<.5) objCol = mix(objCol, objCol.zyx, .75);
            objCol *= (tx2*3. + .25);
            #endif
             
            //////////////////////
            // Rendering a cliche art deco multiscale Truchet design onto the cube faces.
            vec4 c4 = cubeMap(svP);
            vec2 tuv = c4.xy;
            float faceID = c4.w;

            vec2 oTuv = tuv;

            vec2 scl = vec2(1);
            vec2 oScl = scl;

            
            // The two distance field values (they overlap) and corresponding
            // lines patterns.
            vec4 d = Truchet(tuv, id3, faceID, scl);

            // Edge width and smoothing factor.
            float ew2 = .03*oScl.x;
            float sf2 = .01*oScl.x;
            
            
            // Evening up the tone, just a little.
            objCol = mix(objCol, objCol/(1./3. + dot(objCol, vec3(.299, .587, .114))), .5);

            // Saving the original cube color.
            vec3 svCol = objCol;
            objCol /= 2.; // Darkening the background.

            // A little extra thickness for the edges.
            d.xy -= ew2*2.;
            
            // Distance field shading.
            vec2 sh = max(-d.xy/oScl.x*4., 0.);
            sh = smoothstep(0., .65, sh);

            // Rendering the two overlapping distance fields and line patterns.
            for(int i = 0; i<2; i++){

                 // Line pattern.
                 vec3 lnCol = svCol*1.;
                 lnCol = mix(lnCol, svCol*.25, 1. - smoothstep(0., sf2, d[i + 2]));
                 
                 // Subtle highlighting.
                 lnCol *= .75 + sh[i]*.5;

                 // Faux AO, dard edges and pattern.
                 objCol = mix(objCol, vec3(0), (1. - smoothstep(0., sf2*8., d[i]))*.5);
                 objCol = mix(objCol, svCol*.125, 1. - smoothstep(0., sf2, d[i]));
                 objCol = mix(objCol, lnCol, 1. - smoothstep(0., sf2, d[i] + ew2));

            }
            
            
            // Bump map the above pattern. Not as nice as displacement mapping
            // in the distance function, but way effective, and way cheaper.
            // The bump is subtle, but it's there. Too much can be overpowering.
            sn = doBumpMap(svP, sn, .003);
              

            // Save the texture postion.
            svTx = (id3 + txP)*2.;
 
        }
        else {        
            
            // The dark wall in the background. Hidden behind the boxes.
            vec3 tx = tex3D(iChannel1, sp*4., sn);
            objCol = vec3(1.5, 1.25, 1)*(tx*3. + .05)/2.;
             
            // Save the texture postion.
            svTx = sp*4.;
        }
        
        // Adding a purple tinge.
        //objCol = mix(objCol, objCol*vec3(2, 1, .5).yzx, .5);
        
        
        // Texture based bump mapping. You'd need to uncomment the
        // bump map function first.
        //sn = texBump(iChannel1, svTx, sn, .001);///(1. + t/FAR)
        
        
        

        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);
    	
    	// Diffuse lighting.
	    //float diff = max( dot(sn, ld), 0.);
        
        float roughness = min(dot(objCol, vec3(.299, .587, .114))*.75 + .15, 1.);
        float reflectance = .5;
        float matType = 1.;
            
         
        // Cheap specular reflections. Requires loading the "Forest" cube map 
        // into "iChannel3".
        float speR = pow(max(dot(normalize(ld - rd), sn), 0.), 5.);
        vec3 rf = reflect(rd, sn); // Surface reflection.
        vec3 rTx = texture(iChannel3, rf.xzy*vec3(1, -1, -1)).xyz; rTx *= rTx;
        float spF = 2.; //svObjID<.5? 4. : 2.;
        objCol = objCol + objCol*speR*rTx*spF;
         
        // I wanted to use a little more than a constant for ambient light this 
        // time around, but without having to resort to sophisticated methods, then I
        // remembered Blackle's example, here:
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        //float am = pow(length(sin(sn*2.)*.5 + .5)/sqrt(3.), 2.)*1.75; // Studio.
        float am = length(sin(sn*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., -sn.z); // Outdoor.
        //float am = clamp(.5 - .35*(rd.x - rd.y), 0., 1.);        

        // Cook-Torrance based lighting.
        vec3 ct = BRDF(objCol, sn, ld, -rd, matType, roughness, reflectance);
 
        // Combining the ambient and microfaceted terms to form the final color:
        // None of it is technically correct, but it does the job. Note the hacky 
        // ambient shadow term. Shadows on the microfaceted metal doesn't look 
        // right without it... If an expert out there knows of simple ways to 
        // improve this, feel free to let me know. :)
        col = (objCol*am*(sh*.5 + .5) + ct*(sh));        
        
        // Ambient occlusion and attenuation.
        col *= ao*atten;
          
           
	
	}
    
    
    // Applying fog: This fog begins at 90% towards the horizon.
    col = mix(col, vec3(1), smoothstep(.25, .9, t/FAR));
 
    // Very basic Reinhard tone mapping.
    col = col/(1. + col/3.);
    
    // Greyscale.
    //col = vec3(1)*dot(col, vec3(.299, .587, .114));
    
 
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}


