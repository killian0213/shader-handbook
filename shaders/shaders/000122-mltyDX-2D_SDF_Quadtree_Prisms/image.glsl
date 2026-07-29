// Image (image) — 2D SDF Quadtree Prisms by Shane
// https://www.shadertoy.com/view/mltyDX

/*

    2D SDF Quadtree Prisms
    ----------------------
    
    Raymarching 2D SDF quadtree prisms using a quasi-traversal method.
    
    I love the 2D SDF quadtree aesthetic. I'm not sure why, but I think
    I like the marriage of art, math and basic computer science algorithms...
    
    Anyway, I wanted to play around with Xor's really cool 3D XOR example
    (link below) so searched for it. Alongside it, I saw XOR's version of 
    Panna_Pudi's rotating square SDF in quadtree form, so naturally got 
    curious as to what they'd look like mixed together... I doubt I'm 
    starting the next art movement here, but it's an interesting visual.
    
    Anyway, I kept the coloring simple to honor the style of shaders it was 
    based on. I also stuck with a similar 2D SDF. The demoscene fan in me 
    wanted to use a 3D wireframe cube or 2D metaballs SDF as the subject
    matter... Maybe next time. :)
    
    
    
    Inspired by:
    
    // Awesome visuals for the amount of code used.
    Bricks [300] - Xor
    https://www.shadertoy.com/view/cdKBDy
    
    // It has a kind of tech-drawing aesthetic to it that I
    // find really appealing.
    Quadicube in 456 chars
    https://www.shadertoy.com/view/7djyWc
    // Short version of:
    Quadicube - panna_pudi 
    https://www.shadertoy.com/view/NsByWV

*/

 
// Maximum ray distance.
#define FAR  15.

// Global tile scale. Value of about "1./2." to "1./6" work, 
// but it's designed to work with the currect value.
#define GSCALE vec3(1./4.);

// Light type: Point: 0, Direct: 1
#define LIGHT_TYPE 0

// Forward camera speed for that tunnel boring effect. 
// Set to zero for a static camera.
#define CAM_Z 1./3.

// I like the look of offset rows to mix things up a bit. Comment
// it out, if you prefer a more traditional subdivided look.
#define OFFSET_ROWS

// Grey faces, or not.
#define GREY_FACES

// Colored prism sides, or not.
#define COLORED_SIDES

// Single face color override.
//#define SINGLE_FACE_COLOR

// Bore out some holes.
//#define HOLES

//////////////

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

 
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

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// IQ's "uint" based uvec3 to float hash.
float hash31(vec3 f){

    uvec3 p = floatBitsToUint(f);
    p = 1664525U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
}


// Compact, self-contained version of IQ's 2D value noise function.
float n2D(vec2 p){
   
    // Setup.
    // Any random integers will work, but this particular
    // combination works well.
    const vec2 s = vec2(1, 113);
    // Unique cell ID and local coordinates.
    vec2 ip = floor(p); p -= ip;
    // Vertex IDs.
    vec4 h = vec4(0., s.x, s.y, s.x + s.y) + dot(ip, s);
   
    // Smoothing.
    p = p*p*(3. - 2.*p);
    //p *= p*p*(p*(p*6. - 15.) + 10.); // Smoother.
   
    // Random values for the square vertices.
    h = fract(sin(mod(h, 6.2831589))*43758.5453);
   
    // Interpolation.
    h.xy = mix(h.xy, h.zw, p.y);
    return mix(h.x, h.y, p.x); // Output: Range: [0, 1].
}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }

 
/*
// IQ's 3D signed box formula: I tried saving calculations by using the unsigned one, and
// couldn't figure out why the edges and a few other things weren't working. It was because
// functions that rely on signs require signed distance fields... Who would have guessed? :D
float sBoxS(vec3 p, vec3 b, float sf){

  p = abs(p) - b + sf;
  return min(max(p.x, max(p.y, p.z)), 0.) + length(max(p, 0.)) - sf;
}
*/

// IQ's 2D signed box formula with some added rounding.
float sBoxS(vec2 p, vec2 b, float sf){

  p = abs(p) - b + sf;
  return min(max(p.x, p.y), 0.) + length(max(p, 0.)) - sf;
}

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){
 
    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;   
     
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

// Storing the 2D SDF object value. Used for coloring later.
float gBx;

// Height map value.
float hm(in vec2 p){ 
 
    // Moving the pattern forward. Not necessary, but it looks interesting.
    p.y -= iTime*CAM_Z;
 
    // Moving the object around a bit.
    p -= (vec2(cos(iTime), sin(iTime)))*vec2(.5, .25);
    
    // Rotation.
    p = rot2(cos(iTime/2.)*3.14159*.85)*p;
    
    // A 2D SDF box.
    float bx = sBoxS(p, vec2(1.25), .1);
    gBx = bx;

    // Integrating the box border with a box imprint... Kind of.
    return min(bx + .65, abs(bx));
 
 }

// Subdivided rectangle grid.
vec4 getGrid(vec2 p, inout vec2 sc){    
   
   
    #ifdef OFFSET_ROWS
    // Optional: Offset alternate rows.
    if(mod(floor(p.y/sc.y), 2.)<.5) p.x += sc.x/2.;
    #endif
    
    vec2 q = p;
    
    // Cell ID and local coordinates.
    vec2 ip = (floor(p/sc) + .5)*sc;
    p -= ip;
    
    // Partitioning into cells and providing the local cell ID
    // and local coordinates.
    const int n = 2;
    for(int i = 0; i<n; i++){
        // Random subdivision -- One big cell becomes four smaller ones.
        //if(hash21(ip + float(i + 1)*.007)<.5){//(1./float(i + 2))
        if(hm(ip)>float(n - i)/float(n)/4.) break;
            
        p = q;
        sc /= 2.; // Cut the scale in half.
        // New cell ID and local coordinates.
        ip = (floor(p/sc) + .5)*sc;
        p -= ip;
        
    }
    
    // Returning the local coordinates and local cell ID.
    return vec4(p, ip);
}


 


// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
// Box dimension and local XY coordinates.
vec3 gSc; 
vec2 gP;
vec4 gID;


// A simple glow variable.
vec3 glow;

float map(vec3 q3) {


    // Floor. Redundant here.
    float fl = q3.y + .5;
 
 
    vec3 sc = GSCALE; // Scale.
    // Local coordinates and cell ID.
    vec4 p4 = getGrid(q3.xz, sc.xz); 
    vec2 p = p4.xy;
    vec2 id = p4.zw;


    // The distance from the current ray position to the cell boundary
    // wall in the direction of the unit direction ray. This is different
    // to the minimum wall distance, so you need to trace out instead
    // of merely doing a box calculation. Anyway, the following are pretty 
    // standard cell by cell traversal calculations. The resultant cell
    // distance, "gCD", is used by the "trace" and "shadow" functions to 
    // restrict the ray from overshooting, which in turn restricts artifacts.
    //vec3 rC = (gDir*sc - vec3(p.x, q3.y, p.y))/gRd;
    vec2 rC = (gDir.xz*sc.xz - p)/gRd.xz; // For 2D, this will work too.
    
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... I'm not entirely sure it's
    // necessary here, but it stops artifacts from appearing with other 
    // non-rectangular grids.
    //gCD = max(min(min(rC.x, rC.y), rC.z), 0.) + .0015;
    gCD = max(min(rC.x, rC.y), 0.) + .001; // Adding a touch to advance to the next cell.


    // The extruded block height. See the height map function, above.
    float h = hm(id);
    // Adding some subtle randomized animation to break things up a bit.
    h = clamp(h*2., 0., 1.)*.95 + (sin(hash21(id + .05)*6.28315289 + iTime)*.5 + .5)*.05;
 
    // Change the prism rectangle scale just a touch to create some subtle
    // visual randomness.
    //sc.xz -= .02*(hash21(id)*.9 + .1);

    // Lower box prism.
    float d2 = sBoxS(p, sc.xz/2., 0.);
    //float d2 = sBoxS(p, sc.xz/2., .25*sc.x); // Rounded squares.
    //float d2 = length(p) - sc.x/2.; // Circles. Interesting, but...
    
    #ifdef HOLES
    if(sc.x>1./16.) d2 = max(d2, -(d2 + sc.x/2.5));
    #endif
    
    // Creating the extruded prisms.
    float d = opExtrusion(d2, q3.y - h/2., h/2., 0.);
    
    
    // Placing a slightly rounded surface on the faces. Not absolutely
    // necessary, but it sparkles the light a little more.
    vec3 p3 = vec3(p.x, q3.y - (h - 3.)  - .0045, p.y);
    d = min(d, max(length(p3) - 3., d2));
    
    d -= min(-d2*2., .06)*.15; // Some beveling.
    //d += d2*.1; // Raised tops.
    
    // Add some gradient glow to the sides.
    if(q3.y<h){
        float dd = max(h - q3.y, 0.)/h;
        glow += max(1. - dd, 0.);    
    }

    // Saving the box dimensions and local coordinates.
    gSc = vec3(sc.x, h, sc.z);
    gP = p;
    gID = vec4(d, d2, id);
 
 
    // Scene distance.
    return min(fl, d);
}

// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p) {
	
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.002, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}

 

float rayMarch(vec3 ro, vec3 rd) {
    
    float d, t = hash31(ro + rd)*.25; // Glow jitter.
    //const float tol = TOLERANCE;
    vec2 dt = vec2(1e8, 0); // IQ's edge desparkle trick.


    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5; // sign(rd)*.5;
    gRd = rd;
    

    // Initialize the glow to zero.
    glow = vec3(0);

    const int iter = 128;
    int i = 0;
     
    for (i = 0; i < 128; i++) {
       
        d = map(ro + rd*t);
         
        
        // IQ's clever edge desparkle trick. :)
        if (d<dt.x) { dt = vec2(d, t); } 

        if (d<.001 || t > FAR) {
          break;
        }

        t += min(d*.9, gCD);
    }
    
    if(i == iter - 1) { t = dt.y; }


    return min(t, FAR);
}

float softShadow(in vec3 p, in vec3 ld, in float lDist, in float k) {
    
    float res = 1.;
    float t = 0.;

    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., ld) - .5;
    gRd = ld; 

    for (int i=0; i<64; i++){

        float d = map(p + ld*t);
        res = min(res, k*d/t);
        if (d<0. || t>lDist) break;

        t += clamp(min(d*.9, gCD), .01, .25);
    }
    return clamp(res, 0., 1.);
}


// A slight variation on a function from Nimitz's hash collection, here: 
// Quality hashes collection WebGL2 - https://www.shadertoy.com/view/Xt3cDn
vec2 hash23(vec3 f){

    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32>>16);

    uvec2 rz = uvec2(n, n*48271U);
    // Standard uvec2 to vec2 conversion with wrapping and normalizing.
    return vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);
}

 
// A nice random hemispherical routine taken out of one of IQ's examples.
// The routine itself was written by Fizzer.
vec3 cosDir(in vec3 p, in vec3 n){

    vec2 rnd = hash23(p);
    float u = rnd.x;
    float v = rnd.y;
    
    // Method 1 and 2 first generate a frame of reference to use with an arbitrary
    // distribution, cosine in this case. Method 3 (invented by fizzer) specializes 
    // the whole math to the cosine distribution and simplfies the result to a more 
    // compact version that does not depend on a full frame of reference.

    // Method by fizzer: http://www.amietia.com/lambertnotangent.html
    float a = 6.2831853*v;
    u = 2.*u - 1.;
    return normalize(n + vec3(sqrt(1. - u*u)*vec2(cos(a), sin(a)), u));
    
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){
 
	float sca = 2., occ = 0.;
    for(int i = 0; i<12; i++){
    
        float hr = (float(i) + 1.)*.35/12.; 
        //float fi = float(i + 1);
        //vec3 rnd = vec3(hash31(p + fi), hash31(p + fi + .1), hash31(p + fi + .3)) - .5;
        //vec3 rn = normalize(n + rnd*.15);
        vec3 rn = cosDir(p + n*hr, n); // Random half hemisphere vector.
        float d = map(p + rn*hr);
        
        occ = occ + max(hr - d, 0.)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);    
    
}


vec4 render(vec3 ro, vec3 rd){


    #if LIGHT_TYPE == 0
    vec3 lp = ro + vec3(2, 1, 6);
    #else
    vec3 ld = normalize(vec3(2, 1. + 4., 6));//-vec3(-1.5, -3, -3)
    float lDist = FAR;
    #endif
    

    float t = rayMarch(ro, rd);

    // Saving the global scale, local cell coorinates and cell ID.
    vec3 svSc = gSc;
    vec2 svP = gP;
    vec4 svGID = gID;
    
    // Saving the 2D object field from the distance function. Used for coloring.
    float svBX = gBx;


    // Initializing.
    vec3 col = vec3(0);
   
    if (t < FAR){
  
        // Position and normal.
        vec3 p = ro + rd*t;
        vec3 n = normal(p);
        
        // Light.
        #if LIGHT_TYPE == 0
        vec3 ld = lp - p;
        float lDist = length(ld);
        ld /= lDist;
        #endif
        
         
        // Shadow and ambient occlusion.
        float shd = softShadow(p + n*.0015, ld, lDist, 8.);
        float ao = calcAO(p, n);

 
        // Block ID and corresponding height.
        vec2 id = svGID.zw;
  
        // The rotating box used in the height function. Used for coloring.
        float bx = abs(svBX + .35) - .25;
    
        // Background color.
        vec3 bgCol = mix(vec3(.8, .8, 1)*1.1, vec3(.65, .6, .9)/1.25, hash21(id + .13));
        
        // Shape color.
        vec3 shCol = mix(vec3(1, .05, .04)*1.5, vec3(1, .1, .1)/2., hash21(id + .14));
        shCol = mix(shCol, .5 + .45*cos(6.2831*hash21(id + .15)/6. + vec3(0, 1.3, 2)*1.5 + .5), .25);
        shCol = shCol*1.3 + .05;
          
       
        // Coloring the prism sides.
        vec3 an = abs(n);
        int face = max(an.x, an.z)<an.y? 1 : 0;
        #ifdef COLORED_SIDES
        if(face == 0){
            bgCol = mix(bgCol, bgCol*shCol*2., .95);
            shCol = mix(bgCol/2., bgCol*shCol, .5);//vec3(.7, .9, 1.2)/1.2;
            bgCol = mix(bgCol, shCol, .5);
            shCol = bgCol;
             
        }
        #else
        if(face == 0){
            shCol = bgCol;
        }
        #endif
        
        // Further background color refining.    
        bgCol *= vec3(.7, .9, 1.2)*.85;
        
        // Coloring the faces dark grey.
        #ifdef GREY_FACES
        if(face==1){ 
            shCol = vec3(1./3.)*dot(shCol, vec3(.299, .587, .114)); 
            bgCol = shCol;              
        }
        #endif
        
        // Making the shape face color the same as the background.
        #ifdef SINGLE_FACE_COLOR
        #ifdef COLORED_SIDES
        if(face == 1)
        #endif
        { shCol = bgCol; }
        #endif
    
        // Applying the shape color to the background. 
        vec3 oCol = mix(bgCol, shCol, (1. - smoothstep(0., .25, bx))*min(svSc.x*10., 1.));
 
        
        // Leftover effect from another shader. Interesting... but no. :)
        //vec2 id2 = floor(id/2.);
        //if(mod(id2.x + id2.y, 2.)<.5) oCol = mix(oCol, oCol.zyx, .5);
      
        // Texture coordinates that match the animation.
        vec3 txP = vec3(p.x, p.y - svSc.y, p.z);
        vec3 tx = tex3D(iChannel0, txP/2. + .5, n);
        
       
        // Subtle texture color.
        oCol *= tx*2. + .45;
         
        // Very subtle diffuse texturing. Almost not worth the trouble, 
        // but it's done now. :)
        vec3 rTxP = txP;
        rTxP.xz *= rot2(3.14159/9.);
        vec3 dTx = tex3D(iChannel2, rTxP/vec3(4, 1, 1.), n);
        float difSt = dot(dTx, vec3(.299, .587, .114));

        // Diffuse value.
        float dif = max(dot(ld, n), 0.);
        dif = pow(dif, 2. + difSt*16.); // Diffusivity based on texture.
        
        // Specular value.
        float spe = pow(max(dot(reflect(ld, n), rd), 0.), 8. + 8.*difSt);

  

        // Last minute edge routine. I've returned the nearest 2D object ID and 
        // dimensions from the raymarching routine, and the rest sorts itself out.
        float ew = .0075*(1. + t*.1); // Edge width.
        float h = svSc.y; // Height.
        vec2 sc = svSc.xz; // Top face dimensions.
        float rct = svGID.y;//sBoxS(svP, sc/2., .0);
        #ifdef HOLES
        if(sc.x>1./16.) rct = max(rct, -(rct + sc.x/2.5));
        #endif
        float top = max(abs(p.y - h), abs(rct)); // Top.
        float side = abs(abs(svP.x) - sc.x/2.); // Sides.
        side = max(side, abs(abs(svP.y) - sc.y/2.));
        float objEdge = min(top, side - ew*.4) - ew; // Combining.
        
        // Using the diffuse value to mix the color up a bit.
        oCol = mix(oCol, oCol.yxz, dif*dif/5.);
      
        
        // Cheap specular reflections.
        float speR = pow(max(dot(normalize(ld - rd), n), 0.), 5.);
        vec3 rf = reflect(rd, n); // Surface reflection.
        vec3 rTx = texture(iChannel1, -rf).xyz; rTx *= rTx;
        oCol += oCol*speR*rTx*4.;

        
        // I wanted to use a little more than a constant for ambient light this 
        // time around, but without having to resort to sophisticated methods, then I
        // remembered Blackle's example, here:
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        //
        // Studio.
        float am = pow(length(sin(n*2.)*.5 + .5)/sqrt(3.), 2.)*1.5; 
        // Outdoor.
        //float am = length(sin(sn*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., -sn.z); 
        
        
        // Specular color.
        vec3 speCol = vec3(1, .7, .4);
        // Mixing the specular color.
        //speCol = mix(speCol.zyx, speCol, (1. - smoothstep(0., .25, bx))*min(svSc.x*10., 1.));


        // Lit color.
        col = oCol*(am + dif*shd + speCol*spe*shd*4.)*ao;
        

        
        // Adding a touch of glow to the column walls.
        col += col*col*glow/4.;

 
        // Applying the edges to the prism.
        col = mix(col, col*.1, 1. - smoothstep(0., .005, objEdge));


        // Light attenuation. Barely visible, but it's there
        float rt = t/FAR;
        col *= 1.5/(1. + rt*.2); 

    }
  
    // Fog. Not visible, but it's there anyway.
    col = mix(col, vec3(0), smoothstep(.3, .99, t/FAR));
    
    // Returning the final color for this pass... There's only one
    // pass here, but a render function is useful when you want to
    // bounce light around.
    return vec4(col, t);
  
}




void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
 
    // Coordinates.
    vec2 u = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Look vector and camera origin.
    vec3 lk = vec3(0, 0, iTime*CAM_Z);
    vec3 ro = lk + vec3(cos(iTime/4.)*.02, 4, -1. + sin(iTime/2.)*.05);
  
    // Setting up a camera using the usual process. The variable names
    // here suggest that this lot came from one of IQ's examples.
    vec3 ww = normalize(lk - ro);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww ));
    vec3 vv = cross(ww, uu);
    const float FOV = 3.14159/3.; // Field of view.
    vec3 rd = normalize(u.x*uu + u.y*vv + ww/FOV); // Unit direction vector.
    
    // A bit of ray warping just to mix things up.
    vec2 offs = vec2(fbm(rd.xz*12.), fbm(rd.xz*12. + .35));
    const float oFct = .01;
    rd.xz -= (offs - .5)*oFct; 
    rd = normalize(rd);
    
    /*
    // Mouse movement.
    if(iMouse.z>1.){
        rd.yz *= rot2((iMouse.y - iResolution.y*.5)/iResolution.y*3.1459);  
        rd.xz *= rot2((iMouse.x - iResolution.x*.5)/iResolution.x*3.1459);  
    } 
    */

    // Render... I was going to perform a couple of passes, but decided against 
    // it. However, it's usually a good idea to have a separate render function.
    vec4 c4 = render(ro, rd);
    vec3 col = c4.xyz;
    // Vignette and very rough Reinhard tone mapping.
    col *= smoothstep(1.5, .5, length(2.*fragCoord/iResolution.xy - 1.)*.7);
    col /= 1. + col/2.5;

    
    // Rough gamma correction.
    fragColor = vec4(pow(max(col, 0.), vec3(.4545)), 1);
    
    
}
