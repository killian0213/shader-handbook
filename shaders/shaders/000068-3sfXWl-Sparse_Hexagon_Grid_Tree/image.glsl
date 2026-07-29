// Image (image) — Sparse Hexagon Grid Tree by Shane
// https://www.shadertoy.com/view/3sfXWl

/*

    Sparse Hexagon Grid Tree
    ------------------------
    
    Producing and storing a sparse hexagon grid tree, then creating and rendering 
    an extruded curve around it in realtime. As an aside, I'm not entirely sure
    this is a sparse tree, which implies that the number of edges tend toward the 
    minimum end of the spectrum, but I vaguely recall being told it was... If 
    you're an expert on graphy theory nomenclature, feel free to clue me in, and
    I'll update the title. :)
    
    Square grid trees are not what I'd call commonplace in pixelshader form, but 
    you will see them in disguised form, since they come up a lot when producing 
    mazes, and so forth. Hexagon grid trees, for whatever reason, don't appear to
    be common at all. I'd imagine they're out there, but I couldn't find a single 
    image, so I basically had to feel this out as I went along.
    
    In theory, grid tree structures are pretty easy to make: Produce a grid of 
    empty inactive cells, then initiate one or more cells with an active value. 
    From each cell, check the random direction of a random neighboring cell, and 
    if activity statuses and directions meet, make a connection. The connection
    directions and so forth are stored in the buffer channels, and you can use
    those to render the tree structure.
    
    In practive, a lot of it was easy, but I did take a while to come up with an
    effective way to encode a hexagon grid into a square texture. I won't bore you 
    with the details, but I got there in the end. 

    Path animation, self avoiding space filling curves and all kind of things are 
    possible with sparse grid tree structures. However, I'm pretty tacky at heart, 
    so I intend to use it to make some of those cool looking circuit diagram 
    pictures. :)
    
    
    
    Related examples:
    
	// A really nice example on so many different levels. I can thank 
    // Zach for helping me understand how to render space filling curves 
    // in pixelshader form. It was not obvious to me before looking at
    // this example.
	Self-Avoiding Random Road - mathmasterzach
	https://www.shadertoy.com/view/wdySWm
    
    
    // Fabrice and SnoopethDuckDuck's combined logic, which is pretty 
    // difficult to compete with. It's a really nicely written example. 
    Cell Swap Automata - SnoopethDuckDuck
    https://www.shadertoy.com/view/DtccR8
    
*/

// Only two types of curves. Straight edges and rounded.
// Option "0" was virtually trivial to code, and option "1"
// was... less trivial. :)
//
// Straight edge: 0, Curved: 1.
#define CURVE 1

// I put this in at the last minute to better display the outer
// curves... It looks a bit busy, so needs more work. :)
//#define DOUBLE_CURVE

// Color: Purple: 0, Orange: 1, Green: 2, Monotone: 3.
#define COLOR 0

// Max ray distance.
#define FAR 20.


// Scene object ID.
float objID;


 
// Grid zooming variable from Mathmasterzach's 
// "Self-Avoiding Random Road" example.
#define GRID_ZOOM 16./GRID_SIZE


// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Abosolute normal with a bit of tightning.
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.zy).xyz;
    vec3 ty = texture(tex, p.xz).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture 
    // sample, represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like
    // that. :) Once the final color value is gamma corrected, you should see correct 
    // looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n;
}



// Unsigned distance to the segment joining "a" and "b".
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}


// Adx's considerably more concise version of Fizzer's circle solver.
// On a side note, if you haven't seen it before, his "Quake / Introduction" 
// shader is well worth the look: https://www.shadertoy.com/view/lsKfWd
void solveCircle(vec2 a, vec2 b, out vec2 o, out float r){
    
    vec2 m = a + b;
    o = dot(a, a)/dot(m, a)*m;
    r = length(o - a);
    
}


// Ray origin, ray direction, point on the line, normal. 
float rayLine(vec2 ro, vec2 rd, vec2 p, vec2 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop. However,
   // this isn't a GPU intensive example, so it doesn't matter here.
   //return max(dot(p - ro, n), 0.)/max(dot(rd, n), 1e-8);
   float dn = dot(rd, n);
   return dn>0.? dot(p - ro, n)/dn : 1e8;   
   //return dn>0.? max(dot(p - ro, n), 0.)/dn : 1e8;   

}  

vec3 gRd; // Global ray variable.
float gCD; // Global cell boundary distance.


float gH;

vec4 gVar;

// The 2D sparse hexagon tree curve distance.
float distField2D(in vec2 p){ 


        
    vec2 oP = p;
    
    // Scaling.
    p *= (GRID_SIZE*GRID_ZOOM);
    
    // The hexagon grid. Local coordinates and cell IDs.
    vec4 h = getHex(p);
   
    // Passing the position based cell IDs into the texture, in order
    // to retrieve the cell struction information. The "GRID_SIZE" value
    // is added for wrapping purposes... I'm not sure why it's necessary,
    // but my GPU won't wrap things without it.
    vec4 bufA = texelFetch(iChannel0, ivec2(h.zw*2. + GRID_SIZE)%int(GRID_SIZE), 0);
    
    
    // All the branch information is encoded into the X channel.
    // For example, a value of 5 means you need to render edges from
    // the center to the first and third edges.
    int iVal = int(bufA.x);
    
    
    // Line variable.
    float ln = 1e5;

    
    // Obtaining the line information.
    
    
    int lineNum = 0;
    
    // Initializing.
    vec3[ASIZE] point;
    for(int i = 0; i<ASIZE; i++) point[i] = vec3(0, 0, -1);
     
    // Iterate through all the hexagon edges, and if an edge
    // is present, set the edge point and the edge number.
    for(int i = 0; i<ASIZE; i++){
        // An edge is present.
        if( ((iVal/(1<<i))&1) == 1){
           // Position and edge number.
           point[lineNum] = vec3(e[i]*s/4., i);
           lineNum++;
        }
    }

  
    int line=0;
    #if CURVE == 1
    // Rendering a starting circle for cells with more than 2
    // lines. Not entirely necessary here.
    if(lineNum>2) ln = length(h.xy) - 1./2.;
    #endif
    for(int i = 0; i<lineNum; i++){
    
           #if CURVE == 0
           // Straight line option. Very simple. Render a line from
           // the center of the cell to the mid edge, and you're done.
           ln = min(ln, distLine(h.xy, vec2(0), point[i].xy*2.));
           #else
           
           // The slightly more difficult curve option; That is to say,
           // rendering a curve around the lines.
           
           
           vec2 p0 = (point[i].xy);
           vec2 p1 = (point[(i + 1)%lineNum].xy);
           //if(i==lineNum-1){ vec2 t = p0; p0 = p1; p0 = t; }
           if(lineNum==1) ln = distLine(h.xy, vec2(0), p0);
           else if(lineNum==2){
           
                 // Two lines, which means one entry and exit point each.
                 // Therefore, render a straight line, or an arc line.
                 if(p0 == -p1) ln = distLine(h.xy, p0, p1); 
                 else {
                 
                    vec2 o; float r;
                    solveCircle(p0, p1, o, r);   
                    // Circular distance.
                    float arc = length(h.xy - o) - r;
                    arc = abs(arc); 
                    ln = arc;
                }
                
                break;
           }
           else {
                
                // More than two lines, which means blobby objects are involved.
                // This, in turn, means that a bit of constructive solid geometry 
                // (CSG) is required.
                
                if(p0 == -p1){ 
                   // If the adjacent points are on opposite sides of the 
                   // hexagon, render a straight line, and not a curve.
                   ln = max(ln, -distLineS(h.xy, p1, p0)); 
                }
                else {
                
                    // If the adjacent points are not opposite, then you need
                    // the render a curve... This is obvious, when you think about
                    // it, but it took me a while to figure out. The following is
                    // standard polygon edge point to edge point code.
                    
                    
                    // Applying Fizzer's "solveCircle" function, which returns the
                    // origin and radius of the circle that cuts through the end-points
                    // "a" and "b".
                    vec2 o; float r;
                    solveCircle((p0), (p1), o, r);   
 
                    // Circular distance.
                    float arc = length(h.xy - o) - r;
             
                    // I wrote this a while ago, but I remember being annoyed
                    // that the code wasn't as straight forward as I would have
                    // hoped. :) It appears from the code below that some arcs
                    // reside on the outside and some on the inside, depending
                    // on edge index difference.
                    float edgeDiff = point[i].z - point[(i + 1)%lineNum].z;
                    float sgn = edgeDiff == 2. || edgeDiff == -4.? 1. : -1.;
                    
                    // Apply an arc to the outside or the inside, depending
                    // on the conditions above.
                    ln = max(ln, sgn*arc);
                 
                }
                
               
           }
           
           #endif
    }
    
    
   
   // Adding end-point center circles to the single line 
   // cells in order to give it a soldered circuitry feel.
   float cCir = 1e5;
   if(lineNum==1){  // if floor(bufA.z)==1.
       
       // Center circle.
       cCir = length(h.xy) - min(s.x, s.y)/5.;
       
       // End point holes.
       //ln = max(ln, -cCir - .09/2.);
       //cCir = abs(cCir + .09) - .09;
    }
    
    #ifdef DOUBLE_CURVE
    ln = min(ln, cCir + .125*.9);
    ln = abs(abs(ln) - .125*.95); //Hollowing out.
    ln -= .125*.9;
    #else
    ln = min(ln - .125, cCir);
    #endif
    
    
    
    
    // Hexagon coordinates.
    #ifdef FLAT_TOP_HEXAGON
    vec2 pp = abs(h.xy);
    #else
    vec2 pp = abs(h.yx);
    #endif
    
    // Hexagon value. Used for the floor, and to cap the cell
    // object. Normally, you'd use IQ's nicer hexagonal distance,
    // but this plays a small part here, so a bound will do.
    float hex = max(pp.x*.8660254 + pp.y*.5, pp.y) - 1./2.;
    ln = max(ln, hex);
  
    
    // At the begining, the coordinates were scaled by 
    // the scaling figure you see below, so it's necessary
    // the scale back the resultant distance field by 
    // the same amount.
    ln /= (GRID_SIZE*GRID_ZOOM); 
    
    // Save some of the variables for later.
    gVar = vec4(ln, bufA.y, hex, 1e5);
    
/////////////// 

    // For raymarching precision, I dedided to calculate a traversal
    // value. This was a last minute decision, and more expensive, but
    // it allows for empty cells, and virtual artifact free raymarching.
    vec2 gP = h.xy/(GRID_SIZE*GRID_ZOOM);

     // Iterate through a few sides of the hexagon cell.
    // I should really do this outside of the map function.
    // The vertex and edge IDs are multiplied by 12, so we're factoring that in.
    const vec2 sDiv12 = s/12./(GRID_SIZE*GRID_ZOOM);
    const vec2[4] v = vec2[4](vID[0]*sDiv12, vID[1]*sDiv12, vID[2]*sDiv12, vID[3]*sDiv12);
 
    
    // Restricting the distance that the unit ray can jump. I've seen people
    // employ some pretty elaborate procedures to prevent the unit ray from
    // overshooting. Some of them are great in theory, but never quite get 
    // there. The mess below is pretty close to perfect, but it does add a
    // bit of extra load oton the GPU.
    //gCD = .5;
    
    // Normals to 3 hexagon edges. These could be precalculated.
    const vec2 n0 = normalize(v[0] - v[1]).yx*vec2(1, -1);
    const vec2 n1 = normalize(v[1] - v[2]).yx*vec2(1, -1);
    const vec2 n2 = normalize(v[2] - v[3]).yx*vec2(1, -1);
    
    // Hexagon symmetry trick in order to perform three edge intersections,
    // instead of all six.
    vec3 rDir = vec3(1);
    rDir.x = dot(gRd.xz, n0)<0.? -rDir.x : rDir.x;
    rDir.y = dot(gRd.xz, n1)<0.? -rDir.y : rDir.y;
    rDir.z = dot(gRd.xz, n2)<0.? -rDir.z : rDir.z;
    
    vec3 rC;
    rC.x = rayLine(gP, rDir.x*gRd.xz, v[0], rDir.x*n0);
    rC.y = rayLine(gP, rDir.y*gRd.xz, v[1], rDir.y*n1);
    rC.z = rayLine(gP, rDir.z*gRd.xz, v[2], rDir.z*n2);
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... or something like that.
    gCD = min(min(rC.x, rC.y), rC.z);
    //gCD = min(gCD, min(min(rC2.x, rC2.y), rC2.z));
  
    gCD = max(gCD, 0.) + .0015;
    //if(rC.x<=.0) gCD = 1e5;
    
  
    
    
///////////////    
    
    return ln;///GRID_SIZE;
    
}


// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2( sdf, abs(pz) - h);
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    /*
    // Slight rounding. A little nicer, but slower.
    const float sf = .015;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.);
  	return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
    */
}

 

// The extruded image.
float map(vec3 p){

   
    // Floor.
    float fl = p.y;

    // The 2D sparse hexagon tree object.
    float d2 = distField2D(p.xz);
    
    // Height variable. I kept it constant, but it 
    // doesn't have to be.
    gVar.w = .05;
    
    // Extruding the 2D field.
    float d = opExtrusion(d2, p.y, gVar.w);//gH*.05 + .01
    
    d += d2*.25; // Raised extruded pattern tops.
    
    // Adding some minor detail to the floor.
    fl += gVar.z*.008;//max(gVar.z, -.1)*.03;
    // Extra hexagon floor detail... Too much here.
    //fl -= (abs(fract(gVar.z*16.) - .5) - .25)*.0005;
    
   
    // Overall object ID.
    objID = fl<d? 1. : 0.;
    
    // Combining the floor with the extruded object.
    return  min(fl, d);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
        
    gRd = rd; // Set the global ray  direction varible.

    for(int i = min(0, iFrame); i<96; i++){
    
        // Scene distance.
        d = map(ro + rd*t);
        // Break conditions.
        if(abs(d)<.001 || t>FAR) break; 
        
        // Add the distance, but restrict it to the maximum
        // cell wall distance in the ray direction.
        t += min(d*.7, gCD); 
        
    }

    // Cap the distance to the far plane.
    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    //const vec2 e = vec2(.001, 0);
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), 
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}


// Soft shadows.
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 32; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.  
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    gRd = rd;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        t += clamp(min(d, gCD), .005, .15); 
       
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }
    
    // Cap the shadow above zero.
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    // Screen space distortion.
    //uv *= .95 + dot(uv, uv)*.1;
    
	// Camera Setup.
    vec3 lk = vec3(0, 0, iTime/16.);//vec3(0, -.25, iTime);  // "Look At" position.
 
    vec3 ro = lk + vec3(0, .85, -.35); // Camera position, doubling as the ray origin.
	
    
   
    // Light positioning.
 	vec3 lp = lk + vec3(-.5, 1.5, .5);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = .5; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro); // Forward.
    vec3 rgt = normalize(cross(vec3(0, 1, 0), fwd));// Right. 
    // "right" and "forward" are perpendicular normals, so the result is normalized.
    vec3 up = cross(fwd, rgt); // Up.
    
    // Camera.
    //mat3 mCam = mat3(rgt, up, fwd);
    // rd - Ray direction.
    //vec3 rd = mCam*normalize(vec3(uv, 1./FOV));//
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
 
    // Camera rotation.
    rd.xz *= rot2(PI/12.);
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the object ID.
    float svObjID = objID;
    
    // Various variables.
    vec4 svVar = gVar;
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
        vec3 sn = getNormal(sp, t);
        
            	// Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        //sh = min(sh + ao*.25, 1.);
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
     	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        //float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
		// Schlick approximation.
		//float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		//float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough. 
          
    
        float sf = 1./iResolution.y;
        
        vec2 pp = (sp.xz + 1.)*GRID_SIZE*GRID_ZOOM;
        vec4 h = getHex(pp);
        float rnd = hash21(h.zw + .1);
        
        // Object color.
        vec3 oCol = vec3(0);
        
   
        // The extruded grid.
        if(svObjID<.5){
            
             // Edges.
             float edge = abs(svVar.x) - .0005;
             edge = max(abs(sp.y - svVar.w) - .001, edge);
             edge = min(edge, abs(svVar.z) - .025);
             
             // Curve object color.
             oCol = .5 + .45*cos(6.2831*rnd/8. + vec3(0, 1.2, 2.2) + .2);
             oCol *= 1.5;           
   
             // Apply some edging.
             oCol = mix(oCol, oCol*.05, 1. - smoothstep(0., sf,  edge));
             
             // Greyscale value.
             float gr = dot(oCol, vec3(.299, .587, .114));
              
             // Mixing in silver side values. 
             vec3 svCol = oCol;
             oCol = mix(vec3(1.5)*gr, vec3(.05)*gr, 1. - smoothstep(0., sf, svVar.x + .005));
             oCol = mix(oCol, svCol, 1. - smoothstep(0., sf, svVar.x + .0075));
             
             // Curved object sides.
             svCol = mix(svCol, vec3(1)*gr, .0);
             oCol = mix(oCol, vec3(1)*gr, 1. - smoothstep(0., sf, sp.y - svVar.w));
          
        }
        else {
            
            // The floor pattern.
            
            
            // Background.
          
            // Color and greyscale.
            oCol = .5 + .45*cos(6.2831*rnd/8. + vec3(0, 1.2, 2.2) + .2);
            oCol *= 1.5;             
            float gr = dot(oCol, vec3(.299, .587, .114));
            
            vec3 svCol = oCol;
            
            // Hexagon grid background.
            oCol = mix(vec3(.05)*gr, svCol*.4 + gr*.8, 
                       1. - smoothstep(0., sf, svVar.z + .02));
            oCol = mix(oCol, oCol*.05, 1. - smoothstep(0., sf, svVar.z + .055));
            oCol = mix(oCol, vec3(.8)*gr, 1. - smoothstep(0., sf, svVar.z + .055 + .035));
          
            /*
            // Concentric pattern. Sometimes details work, but not always. :)
            float pat = (abs(fract(gVar.z*6. + .0) - .2) - .1)/6.;
            oCol = mix(oCol, oCol*.05, 1. - smoothstep(0., sf, pat));
            */
            
            /*
            // Extra extruded ground pattern... A bit too busy.
            oCol = mix(oCol, vec3(0), 1. - smoothstep(0., sf, svVar.x - .06 + .051));
            oCol = mix(oCol, vec3(1)*gr, 
                     1. - smoothstep(0., sf, svVar.x - .06 + .051 + .0025));
            */
            
   
            // Rendering some dark edges to match the extruded pattern.
            oCol = mix(oCol, oCol*.05, 1. - smoothstep(0., sf,  svVar.x - .002));
            
            
            /////////
            #if 1
            // Last minute colored dots, for decoration... Needs work.
            vec2 q = h.xy;
            float ia = (floor(atan(q.x, q.y)/6.2831853*6.) + .5)/6.;
            q *= rot2(ia*6.2831853);
            q.y -= .365;
            float dV = length(q) - .05; // Rivots.
            float shF = iResolution.y/450.; // 2D shadows are resolution dependent.
            oCol = mix(oCol, oCol*.25, 1. - smoothstep(0., sf*shF*8., dV));
            oCol = mix(oCol, vec3(gr*.0), 1. - smoothstep(0., sf, dV));
            oCol = mix(oCol, svCol, 1. - smoothstep(0., sf, dV + .03));
            #endif
            //////////
   
        }
        
        // Color options.
        #if COLOR == 0
        oCol = mix(oCol.yzx, oCol.xzy, smoothstep(0., 1., dot(uv, uv))*.6);
        #elif COLOR == 1
        oCol = mix(oCol, oCol.xzy, smoothstep(0., 1., dot(uv, uv))*.6);
        #elif COLOR == 2
        oCol = mix(oCol.yxz, oCol.yzx*oCol.zyx, 
                   smoothstep(.2, .8, .3 + dot(uv, uv))*.7);
        #else
        oCol = vec3(.9)*dot(oCol, vec3(.299, .587, .114));
        #endif
        
        
        // Specular reflective highlighting.
        float spR = pow(max(dot(normalize(ld - rd), sn), 0.), 8.);
        vec3 rf = reflect(rd, sn); // Surface reflection.
        vec3 rTx = texture(iChannel2, rf.xzy*vec3(1, 1, 1)).xyz; rTx *= rTx;
        oCol += oCol*spR*rTx.zyx*2.;
        //oCol = oCol/1.5 + oCol*spR*rTx.zyx*8.; // Shinier.
   
      
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        // Studio.
        float am = pow(length(sin((sn)*PI/2.)*.5 + .5)/sqrt(3.), 2.)*1.5; 

        // Anisotropic diffuse value. Not really correct, but it'll do.
        float diff2 = diff/4. + length(sin(diff*PI*8.)*.5 + .5);
        diff2 += pow(diff2*.6, 4.);
        diff = diff2*.8;

        // Combining the color and lighting.
        col = oCol*(diff*diff*sh + spec*sh + am/2.);

          // Shading.
        col *= ao*atten;
    
       
        // It's sometimes helpful to check things like shadows and AO by themselves.
        //col = vec3(ao);
 	}
   
   
    /*
    // The 2D distance field only, for debug purposes.
    vec2  R = iResolution.xy,
          uv2 = (fragCoord)/R.y ,
          p = uv2 + vec2(1, .5)*iTime/8.;

    
    float d = distField2D(p);
    
    col = vec3(.9, 1, .1)*smoothstep(0., 1.5/R.y, d);
    */
    
    // Horizon fog. Not visible here, but provided for completeness.
    col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));
          
    
    // Rought gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}